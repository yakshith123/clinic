from fastapi import APIRouter, Depends, HTTPException, status
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User, UserRole
from app.models.doctor import Doctor
from app.schemas.user import DoctorCreate, DoctorUpdate, DoctorResponse, DoctorWithUser, UserResponse
from app.routers.auth import get_current_active_user

class DoctorClinicsUpdate(BaseModel):
    associated_clinic_ids: Optional[List[str]] = None


router = APIRouter(prefix="/doctors", tags=["Doctors"])

@router.post("/", response_model=DoctorResponse, status_code=status.HTTP_201_CREATED)
async def create_doctor_profile(
    doctor: DoctorCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create doctor profile (requires user with doctor role)"""
    # Check if user is a doctor
    if current_user.role != UserRole.DOCTOR:
        raise HTTPException(status_code=403, detail="Only doctors can create profiles")
    
    # Check if doctor profile already exists
    existing = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Doctor profile already exists")
    
    # Update user role if needed
    current_user.role = UserRole.DOCTOR
    current_user.hospital_id = doctor.hospital_id
    current_user.department = doctor.specialization
    
    db_doctor = Doctor(
        user_id=current_user.id,
        hospital_id=doctor.hospital_id,
        specialization=doctor.specialization,
        qualification=doctor.qualification,
        experience_years=doctor.experience_years,
        bio=doctor.bio,
        consultation_fee=doctor.consultation_fee,
        availability=doctor.availability,
    )
    
    db.add(db_doctor)
    db.commit()
    db.refresh(db_doctor)
    
    return db_doctor

@router.get("/", response_model=List[DoctorWithUser])
async def get_doctors(
    skip: int = 0,
    limit: int = 100,
    hospital_id: Optional[str] = None,  # Changed parameter name back to hospital_id with proper typing
    specialization: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all doctors with optional filters"""
    query = db.query(Doctor).join(User, Doctor.user_id == User.id)
    
    if hospital_id:
        query = query.filter(Doctor.hospital_id == hospital_id)  # Changed to use hospital_id
    if specialization:
        query = query.filter(Doctor.specialization == specialization)
    
    doctors = query.filter(User.is_active == 1).offset(skip).limit(limit).all()
    
    result = []
    for doctor in doctors:
        user = db.query(User).filter(User.id == doctor.user_id).first()
        result.append(DoctorWithUser(
            **doctor.__dict__,
            user=UserResponse.model_validate(user)
        ))
    
    return result

@router.get("/list-all")
async def list_all_doctors(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all users with doctor role (for admin panel)"""
    doctors = db.query(User).filter(
        User.role == UserRole.DOCTOR,
        User.is_active == 1
    ).order_by(User.created_at.desc()).all()
    
    # Enrich doctor data with clinic information from user_clinics mapping
    result = []
    for doctor in doctors:
        # Get associated clinics from user_clinics table
        clinic_result = db.execute(
            text("SELECT clinic_id FROM user_clinics WHERE user_id = :user_id"),
            {"user_id": doctor.id}
        ).fetchall()
        
        # Convert to list of clinic IDs
        clinic_ids = [row[0] for row in clinic_result] if clinic_result else []
        
        # Get clinic details if any clinics found
        if clinic_ids:
            if len(clinic_ids) == 1:
                # For single clinic, use direct comparison
                clinics_result = db.execute(
                    text("SELECT id, name FROM clinics WHERE id = :clinic_id"),
                    {"clinic_id": clinic_ids[0]}
                ).fetchall()
            else:
                # For multiple clinics, use IN clause
                clinics_result = db.execute(
                    text("SELECT id, name FROM clinics WHERE id IN :clinic_ids"),
                    {"clinic_ids": tuple(clinic_ids)}
                ).fetchall()
            
            # Create a custom response with clinic names
            doctor_dict = {
                'id': doctor.id,
                'email': doctor.email,
                'name': doctor.name,
                'phone': doctor.phone,
                'role': str(doctor.role).split('.')[-1].lower(),  # Convert UserRole.DOCTOR to 'doctor'
                'clinic_id': doctor.clinic_id,
                'department': doctor.department,
                'associated_clinic_ids': clinic_ids,
                'is_active': doctor.is_active,
                'is_google_user': doctor.is_google_user,
                'google_id': doctor.google_id,
                'created_at': doctor.created_at,
                'updated_at': doctor.updated_at,
                'clinic_names': [clinic[1] for clinic in clinics_result]  # Add clinic names
            }
            result.append(doctor_dict)
        else:
            # No clinics assigned
            doctor_dict = {
                'id': doctor.id,
                'email': doctor.email,
                'name': doctor.name,
                'phone': doctor.phone,
                'role': str(doctor.role).split('.')[-1].lower(),  # Convert UserRole.DOCTOR to 'doctor'
                'clinic_id': doctor.clinic_id,
                'department': doctor.department,
                'associated_clinic_ids': [],
                'is_active': doctor.is_active,
                'is_google_user': doctor.is_google_user,
                'google_id': doctor.google_id,
                'created_at': doctor.created_at,
                'updated_at': doctor.updated_at,
                'clinic_names': []
            }
            result.append(doctor_dict)
    
    return result

@router.get("/{doctor_id}", response_model=DoctorWithUser)
async def get_doctor(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get doctor by ID"""
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    user = db.query(User).filter(User.id == doctor.user_id).first()
    
    return DoctorWithUser(
        **doctor.__dict__,
        user=UserResponse.model_validate(user)
    )

@router.put("/{doctor_id}", response_model=DoctorResponse)
async def update_doctor(
    doctor_id: str,
    doctor_update: DoctorUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update doctor profile"""
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Check authorization
    if current_user.role != UserRole.DOCTOR or doctor.user_id != current_user.id:
        if current_user.role not in [UserRole.ADMIN, UserRole.HOSPITAL_ADMIN]:
            raise HTTPException(status_code=403, detail="Not authorized")
    
    update_data = doctor_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(doctor, key, value)
    
    db.commit()
    db.refresh(doctor)
    
    return doctor

@router.get("/{doctor_id}/availability")
async def get_doctor_availability(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get doctor availability schedule"""
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    return doctor.availability or {}

@router.put("/{doctor_id}/availability")
async def update_doctor_availability(
    doctor_id: str,
    availability: dict,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update doctor availability schedule"""
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Check authorization
    if current_user.role != UserRole.DOCTOR or doctor.user_id != current_user.id:
        if current_user.role not in [UserRole.ADMIN, UserRole.HOSPITAL_ADMIN]:
            raise HTTPException(status_code=403, detail="Not authorized")
    
    doctor.availability = availability
    db.commit()
    db.refresh(doctor)
    
    return doctor.availability

@router.put("/{doctor_id}/toggle-availability")
async def toggle_doctor_availability(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Toggle doctor availability"""
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Check authorization
    if current_user.role != UserRole.DOCTOR or doctor.user_id != current_user.id:
        if current_user.role not in [UserRole.ADMIN, UserRole.HOSPITAL_ADMIN]:
            raise HTTPException(status_code=403, detail="Not authorized")
    
    doctor.is_available = 0 if doctor.is_available == 1 else 1
    db.commit()
    db.refresh(doctor)
    
    return {"is_available": doctor.is_available == 1}


@router.put("/{doctor_id}/clinics", response_model=UserResponse)
async def update_doctor_clinics(
    doctor_id: str,
    clinics_update: DoctorClinicsUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update doctor's associated clinics (admin only)"""
    # Check if user is admin
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Get the doctor user
    doctor = db.query(User).filter(User.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # Update associated_clinic_ids if provided
    if clinics_update.associated_clinic_ids is not None:
        # For now, we'll store it as a JSON string or use clinic_id for single clinic
        # If you want to support multiple clinics, you need to add the column to the database
        if len(clinics_update.associated_clinic_ids) > 0:
            # Use the first clinic as the primary clinic_id
            doctor.clinic_id = clinics_update.associated_clinic_ids[0]
        else:
            doctor.clinic_id = None
    
    db.commit()
    db.refresh(doctor)
    
    return UserResponse.model_validate(doctor)

