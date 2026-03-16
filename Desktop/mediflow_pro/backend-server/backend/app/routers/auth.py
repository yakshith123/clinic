from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import timedelta
import random
from app.database import get_db
from app.models.user import User, UserRole
from app.models.clinic import Clinic
from app.schemas.user import UserCreate, UserResponse, Token
from app.utils.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from app.config import settings
from fastapi import HTTPException, status
import logging
from app.services.sms_service import sms_service

logger = logging.getLogger(__name__)

# In-memory OTP storage (in production, use Redis or database)
otp_storage = {}

def normalize_phone_number(phone: str) -> str:
    """
    Normalize phone number to E.164 format.
    - If phone starts with +, keep as is
    - If phone is 10 digits (India), add +91 prefix
    - Remove any spaces, dashes, or parentheses
    """
    # Remove all non-digit characters except +
    cleaned = ''.join(filter(str.isdigit, phone.lstrip('+')))
    
    # Add country code if missing
    if len(cleaned) == 10:  # Indian mobile number without country code
        return f"+91{cleaned}"
    elif len(cleaned) == 12 and cleaned.startswith('91'):  # Already has 91 but no +
        return f"+{cleaned}"
    elif cleaned.startswith('+'):
        return cleaned
    else:
        # Return as-is with + prefix if it doesn't have one
        return f"+{cleaned}" if not phone.startswith('+') else phone

router = APIRouter(prefix="/auth", tags=["Authentication"])

from fastapi.security import HTTPBearer
oauth2_scheme = HTTPBearer(auto_error=False)

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    if credentials is None:
        raise credentials_exception
    
    # Extract token from credentials
    token_str = credentials.credentials
    
    payload = decode_token(token_str)
    if payload is None:
        raise credentials_exception
    
    user_id = payload.get("sub")
    if user_id is None:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Get current active user"""
    # Handle SQLAlchemy comparison properly - use getattr to access the value
    if getattr(current_user, 'is_active', 1) == 0:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        # If it's a Google user trying to register again, update the existing user
        if user.is_google_user and getattr(existing_user, 'is_google_user', False):
            # Update existing Google user
            setattr(existing_user, 'name', user.name)
            setattr(existing_user, 'phone', user.phone)
            setattr(existing_user, 'role', UserRole[user.role.value.upper()])
            setattr(existing_user, 'clinic_id', user.clinic_id)
            setattr(existing_user, 'department', user.department)
            setattr(existing_user, 'google_id', user.google_id)
            db.commit()
            db.refresh(existing_user)
            return existing_user
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # For Google users, we don't need to hash a password
    hashed_password = None
    if not user.is_google_user and user.password:
        hashed_password = get_password_hash(user.password)
    
    # Create user
    db_user = User(
        email=user.email,
        password_hash=hashed_password,
        name=user.name,
        phone=user.phone,
        role=UserRole[user.role.value.upper()],
        clinic_id=user.clinic_id,
        department=user.department,
        is_google_user=user.is_google_user or False,
        google_id=user.google_id,
    )
    
    db.add(db_user)
    db.flush()  # Get the user ID before committing
    
    # If associated_clinic_ids are provided, add them to the relationship
    if hasattr(user, 'associated_clinic_ids') and user.associated_clinic_ids:
        for clinic_id in user.associated_clinic_ids:
            # Verify that the clinic exists
            clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
            if clinic:
                db_user.associated_clinics.append(clinic)
    
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.post("/google-login", response_model=Token)
async def google_login(user_data: dict, db: Session = Depends(get_db)):
    """Login/Register Google user and return access token"""
    # Extract user data from Google response
    email = user_data.get("email")
    name = user_data.get("name")
    google_id = user_data.get("google_id")
    
    if not email or not name or not google_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing required Google user data"
        )
    
    # Check if user exists
    existing_user = db.query(User).filter(User.email == email).first()
    
    if existing_user:
        # User exists, check if it's a Google user
        if not getattr(existing_user, 'is_google_user', False):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered with non-Google account"
            )
        # Update existing Google user
        setattr(existing_user, 'name', name)
        setattr(existing_user, 'google_id', google_id)
        db_user = existing_user
        db.commit()
    else:
        # Create new Google user
        db_user = User(
            email=email,
            password_hash=None,  # No password for Google users
            name=name,
            phone="+1234567890",  # Default phone
            role=UserRole.PATIENT,
            is_google_user=True,
            google_id=google_id,
        )
        db.add(db_user)
        db.commit()
    
    # Create tokens
    access_token = create_access_token(
        data={"sub": db_user.id},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    refresh_token = create_refresh_token(data={"sub": db_user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login user and return access token"""
    user = db.query(User).filter(User.email == form_data.username).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Google users cannot login with email/password
    if getattr(user, 'is_google_user', False):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google users must login with Google Sign-In",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password for non-Google users
    user_password_hash = getattr(user, 'password_hash', '')
    if not user_password_hash or not verify_password(form_data.password, user_password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Handle SQLAlchemy comparison properly
    if getattr(user, 'is_active', 1) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # Create tokens
    access_token = create_access_token(
        data={"sub": user.id},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "role": str(user.role).split('.')[-1].lower(),
            "clinic_id": user.clinic_id,
            "associated_clinic_ids": [clinic.id for clinic in getattr(user, 'associated_clinics', [])],
            "department": user.department,
            "is_active": user.is_active
        }
    }

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_active_user)):
    """Logout user (client should discard tokens)"""
    return {"message": "Successfully logged out"}

@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user info with clinic associations"""
    # Get associated clinics from user_clinics table
    clinic_result = db.execute(
        text("SELECT clinic_id FROM user_clinics WHERE user_id = :user_id"),
        {"user_id": current_user.id}
    ).fetchall()
    
    associated_clinic_ids = [row[0] for row in clinic_result] if clinic_result else []
    
    # Create response dict with all fields including associated_clinic_ids
    response_data = {
        'id': current_user.id,
        'email': current_user.email,
        'name': current_user.name,
        'phone': current_user.phone,
        'role': str(current_user.role).split('.')[-1].lower(),
        'clinic_id': current_user.clinic_id,
        'department': current_user.department,
        'associated_clinic_ids': associated_clinic_ids,
        'is_active': current_user.is_active,
        'is_google_user': getattr(current_user, 'is_google_user', False),
        'google_id': getattr(current_user, 'google_id', None),
        'created_at': current_user.created_at,
        'updated_at': getattr(current_user, 'updated_at', None)
    }
    
    return response_data

@router.put("/me", response_model=UserResponse)
async def update_me(
    user_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update current user info"""
    # Update user fields if provided
    if 'name' in user_data:
        setattr(current_user, 'name', user_data['name'])
    if 'phone' in user_data:
        setattr(current_user, 'phone', user_data['phone'])
    if 'clinic_id' in user_data:
        setattr(current_user, 'clinic_id', user_data['clinic_id'])
    if 'department' in user_data:
        setattr(current_user, 'department', user_data['department'])
    
    db.commit()
    db.refresh(current_user)
    
    return current_user

@router.post("/request-phone-otp")
async def request_phone_otp(phone_data: dict, db: Session = Depends(get_db)):
    """Request OTP for phone number authentication"""
    try:
        phone = phone_data.get('phone')
        if not phone:
            raise HTTPException(status_code=400, detail="Phone number is required")
        
        # Generate 6-digit OTP
        otp_code = str(random.randint(100000, 999999))
        
        # Store OTP with 5-minute expiry
        otp_storage[phone] = {
            'code': otp_code,
            'attempts': 0,
            'verified': False
        }
        
        # Send OTP via SMS using Twilio
        import asyncio
        sms_sent = await sms_service.send_otp_sms(phone_number=phone, otp_code=otp_code)
        
        # Print OTP to console for testing (will show in backend logs)
        print(f"\n{'='*50}")
        print(f"🔐 OTP GENERATED FOR: {phone}")
        print(f"🔢 OTP CODE: {otp_code}")
        if sms_sent:
            print(f"📱 SMS SENT: ✅ Yes (via Twilio)")
        else:
            print(f"📱 SMS SENT: ❌ Failed (check logs)")
        print(f"{'='*50}\n")
        
        return {
            "success": True,
            "message": "OTP sent successfully",
            "phone": phone,
            "sms_sent": sms_sent
        }
    except Exception as e:
        logger.error(f"Error requesting OTP: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to send OTP: {str(e)}")

@router.post("/verify-phone-otp")
async def verify_phone_otp(verification_data: dict, db: Session = Depends(get_db)):
    """Verify OTP for phone number authentication"""
    try:
        phone = verification_data.get('phone')
        otp_code = verification_data.get('otp_code')
        
        if not phone or not otp_code:
            raise HTTPException(status_code=400, detail="Phone number and OTP code are required")
        
        # Normalize phone number to E.164 format
        normalized_phone = normalize_phone_number(phone)
        print(f"📱 Verifying OTP for phone: {phone} -> Normalized: {normalized_phone}")
        
        # Check if OTP exists (use normalized phone)
        if normalized_phone not in otp_storage:
            # Try with original phone as fallback
            if phone not in otp_storage:
                raise HTTPException(status_code=400, detail="OTP not found or expired")
            else:
                # Use original phone if normalized not found
                normalized_phone = phone
        
        otp_data = otp_storage[normalized_phone]
        
        # Check attempts
        if otp_data['attempts'] >= 3:
            del otp_storage[normalized_phone]
            raise HTTPException(status_code=400, detail="Too many failed attempts. Please request a new OTP.")
        
        # Verify OTP
        if otp_data['code'] != otp_code:
            otp_data['attempts'] += 1
            raise HTTPException(status_code=400, detail="Invalid OTP code")
        
        # OTP verified successfully
        otp_storage[normalized_phone]['verified'] = True
        
        # Check if user exists (search with normalized phone)
        # Also try without +91 prefix as fallback
        user = db.query(User).filter(User.phone == normalized_phone).first()
        
        # If not found, try searching with phone without country code
        if not user and normalized_phone.startswith('+91'):
            phone_without_country = normalized_phone[3:]  # Remove +91
            user = db.query(User).filter(User.phone == phone_without_country).first()
        
        # If still not found, try with + prefix
        if not user and not normalized_phone.startswith('+'):
            user = db.query(User).filter(User.phone == f"+{normalized_phone}").first()
        
        if user:
            # User exists - LOGIN SUCCESSFUL
            access_token = create_access_token(
                data={"sub": user.id},
                expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
            )
            refresh_token = create_refresh_token(data={"sub": user.id})
            
            return {
                "success": True,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "name": user.name,
                    "phone": user.phone,
                    "role": user.role.value,
                    "clinic_id": user.clinic_id,
                    "department": user.department
                }
            }
        else:
            # User does NOT exist - Registration required
            print(f"❌ User not found for phone: {normalized_phone}")
            raise HTTPException(
                status_code=403,
                detail="Phone number not registered. Please register an account first."
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error verifying OTP: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to verify OTP: {str(e)}")
