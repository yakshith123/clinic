from fastapi import FastAPI
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from sqlalchemy.orm import Session
from app.config import settings
from app.database import init_db, SessionLocal
from app.routers import (
    auth_router,
    appointments_router,
    queue_router,
    clinics_router,
    doctors_router,
    qr_router,
    sms_router,
    email_router,
    ads_router,
)

def add_default_clinics():
    """Function to sync clinics from Firebase Firestore to database"""
    db = None
    try:
        from app.database import SessionLocal
        from app.models.clinic import Clinic  # Import here to avoid circular imports
        db = SessionLocal()
        
        # Valid Clinic model fields
        valid_clinic_fields = {
            'name', 'address', 'city', 'state', 'country', 'postal_code',
            'latitude', 'longitude', 'phone', 'email', 'departments', 'is_active'
        }
        
        # Try to load clinics from Firebase Firestore
        try:
            import firebase_admin
            from firebase_admin import credentials, firestore
            import os
            
            cred_path = "firebase-credentials.json"
            if os.path.exists(cred_path):
                # Initialize Firebase if not already done
                if not firebase_admin._apps:
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                
                db_firestore = firestore.client()
                clinics_ref = db_firestore.collection('clinics')
                docs = clinics_ref.stream()
                
                synced_count = 0
                for doc in docs:
                    clinic_data = doc.to_dict()
                    clinic_id = doc.id
                    
                    # Filter to only valid Clinic model fields and provide defaults for required fields
                    clean_clinic_data = {
                        'name': clinic_data.get('name', 'Unknown Clinic'),
                        'address': clinic_data.get('address', ''),
                        'city': clinic_data.get('city', 'Unknown'),
                        'state': clinic_data.get('state', 'Unknown'),
                        'country': clinic_data.get('country', 'India'),
                        'postal_code': clinic_data.get('postal_code', '000000'),
                        'phone': clinic_data.get('phone', '0000000000'),
                        'email': clinic_data.get('email', 'clinic@example.com'),
                        'latitude': clinic_data.get('latitude'),
                        'longitude': clinic_data.get('longitude'),
                        'departments': clinic_data.get('departments', []),
                        'is_active': clinic_data.get('is_active', 1)
                    }
                    
                    # Check if clinic exists in database
                    existing_clinic = db.query(Clinic).filter(Clinic.id == clinic_id).first()
                    
                    if existing_clinic:
                        # Update existing clinic
                        for key, value in clean_clinic_data.items():
                            if hasattr(existing_clinic, key):
                                setattr(existing_clinic, key, value)
                    else:
                        # Create new clinic from Firebase
                        clinic = Clinic(**clean_clinic_data)
                        clinic.id = clinic_id
                        db.add(clinic)
                        synced_count += 1
                
                db.commit()
                
                if synced_count > 0:
                    print(f"✅ Synced {synced_count} clinics from Firebase Firestore")
                    for clinic in db.query(Clinic).all():
                        print(f"   • {clinic.name} (ID: {clinic.id})")
                else:
                    print("ℹ️ No new clinics found in Firebase")
                
                total_clinics = db.query(Clinic).count()
                print(f"Total clinics in database: {total_clinics}")
            else:
                print("⚠️ Firebase credentials not found, skipping Firebase sync")
                
        except Exception as e:
            print(f"Error loading from Firebase: {e}")
            # Continue with empty database
        
    except Exception as e:
        print(f"Error syncing clinics: {e}")
        if db:
            db.rollback()
    finally:
        if db:
            db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    print("Starting MediFlow Pro Backend...")
    init_db()
    
    # Skip clinic initialization for now - handled by QR router
    print("Database initialized")
    yield
    # Shutdown
    print("Shutting down MediFlow Pro Backend...")

# Create FastAPI app
app = FastAPI(
    title="MediFlow Pro API",
    description="Healthcare Queue & Resource Management System",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api")
app.include_router(appointments_router, prefix="/api")
app.include_router(queue_router, prefix="/api")
app.include_router(clinics_router, prefix="/api")
app.include_router(doctors_router, prefix="/api")
app.include_router(qr_router, prefix="/api")
app.include_router(sms_router, prefix="/api")  # SMS endpoints at /api/sms/send
app.include_router(email_router, prefix="/api")  # Email endpoints at /api/email/send
app.include_router(ads_router)  # Ads router has /api/ads prefix

# Health check endpoint
@app.get("/")
async def root():
    return {
        "message": "Welcome to MediFlow Pro API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}