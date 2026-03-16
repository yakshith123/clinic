from fastapi import APIRouter, Depends, HTTPException, status
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.user import User, UserRole
from app.models.appointment import Appointment, AppointmentStatus
from app.models.queue import Queue, QueueStatus
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse,
    AppointmentWithDetails,
)
from app.schemas.appointment import AppointmentStatus as AppointmentStatusSchema
from app.routers.auth import get_current_active_user
from app.utils.firebase import send_notification

router = APIRouter(prefix="/appointments", tags=["Appointments"])

@router.post("/", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    appointment: AppointmentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new appointment"""
    # Calculate queue position
    today_count = db.query(func.count(Appointment.id)).filter(
        Appointment.doctor_id == appointment.doctor_id,
        Appointment.appointment_date >= datetime.now().replace(hour=0, minute=0, second=0)
    ).scalar() or 0
    
    queue_position = today_count + 1
    
    # Estimate wait time (15 minutes per appointment)
    estimated_wait_time = (queue_position - 1) * 15
    
    db_appointment = Appointment(
        patient_id=current_user.id,
        doctor_id=appointment.doctor_id,
        hospital_id=appointment.hospital_id,
        appointment_date=appointment.appointment_date,
        time_slot=appointment.time_slot,
        department=appointment.department,
        reason=appointment.reason,
        queue_position=queue_position,
        estimated_wait_time=estimated_wait_time,
        patient_latitude=appointment.patient_latitude,
        patient_longitude=appointment.patient_longitude,
    )
    
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    # Create queue entry
    db_queue = Queue(
        appointment_id=db_appointment.id,
        hospital_id=appointment.hospital_id,
        doctor_id=appointment.doctor_id,
        current_position=queue_position,
        estimated_wait_time=estimated_wait_time,
    )
    
    db.add(db_queue)
    db.commit()
    
    # Send notification to doctor
    doctor = db.query(User).filter(User.id == db_appointment.doctor_id).first()
    if doctor and doctor.fcm_token:
        send_notification(
            token=doctor.fcm_token,
            title="New Appointment",
            body=f"You have a new appointment from {current_user.name}",
            data={"appointment_id": db_appointment.id}
        )
    
    return db_appointment

@router.get("/", response_model=List[AppointmentResponse])
async def get_appointments(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointments based on user role"""
    if current_user.role == UserRole.PATIENT:
        appointments = db.query(Appointment).filter(
            Appointment.patient_id == current_user.id
        ).offset(skip).limit(limit).all()
    elif current_user.role == UserRole.DOCTOR:
        # Get doctor profile first
        from app.models.doctor import Doctor
        doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        if doctor:
            appointments = db.query(Appointment).filter(
                Appointment.doctor_id == doctor.id
            ).offset(skip).limit(limit).all()
        else:
            appointments = []
    elif current_user.role in [UserRole.ADMIN, UserRole.HOSPITAL_ADMIN]:
        appointments = db.query(Appointment).offset(skip).limit(limit).all()
    else:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    return appointments

@router.get("/{appointment_id}", response_model=AppointmentWithDetails)
async def get_appointment(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointment by ID"""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Check authorization
    if (current_user.role == UserRole.PATIENT and appointment.patient_id != current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Get related details
    patient = db.query(User).filter(User.id == appointment.patient_id).first()
    doctor = db.query(User).filter(User.id == appointment.doctor_id).first()
    hospital = db.query(appointment.hospital_id).first()  # You'll need to import Hospital
    
    return AppointmentWithDetails(
        **appointment.__dict__,
        patient_name=patient.name if patient else None,
        doctor_name=doctor.name if doctor else None,
        hospital_name=None,  # Add hospital name
    )

@router.put("/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: str,
    appointment_update: AppointmentUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update appointment"""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Check authorization
    if (current_user.role == UserRole.PATIENT and appointment.patient_id != current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Update fields
    update_data = appointment_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(appointment, key, value)
    
    db.commit()
    db.refresh(appointment)
    
    return appointment

@router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_appointment(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Cancel appointment"""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Check authorization
    if (current_user.role == UserRole.PATIENT and appointment.patient_id != current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    appointment.status = AppointmentStatus.CANCELLED
    db.commit()
    
    # Delete queue entry
    db.query(Queue).filter(Queue.appointment_id == appointment_id).delete()
    db.commit()
    
    return None

@router.get("/by-patient/{patient_id}", response_model=List[AppointmentResponse])
async def get_patient_appointments(
    patient_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointments for a specific patient"""
    # Check authorization
    if (current_user.role == UserRole.PATIENT and current_user.id != patient_id):
        raise HTTPException(status_code=403, detail="Not authorized")
    
    appointments = db.query(Appointment).filter(
        Appointment.patient_id == patient_id
    ).all()
    
    return appointments

@router.get("/doctor/{doctor_id}", response_model=List[AppointmentResponse])
async def get_doctor_appointments(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointments for a specific doctor"""
    # Check authorization - doctors can only see their own appointments
    if current_user.role == UserRole.DOCTOR and current_user.id != doctor_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    appointments = db.query(Appointment).filter(
        Appointment.doctor_id == doctor_id
    ).all()
    
    return appointments
    
    appointments = db.query(Appointment).filter(
        Appointment.patient_id == patient_id
    ).order_by(Appointment.appointment_date.desc()).all()
    
    return appointments

@router.get("/by-doctor/{doctor_id}", response_model=List[AppointmentResponse])
async def get_doctor_appointments(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get appointments for a specific doctor"""
    appointments = db.query(Appointment).filter(
        Appointment.doctor_id == doctor_id
    ).order_by(Appointment.appointment_date.asc()).all()
    
    return appointments

@router.get("/hospital/{hospital_id}", response_model=List[dict])
async def get_hospital_appointments(
    hospital_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all appointments for a specific hospital/clinic"""
    # Get appointments with patient details
    appointments = db.query(
        Appointment,
        User.name.label('patient_name')
    ).join(
        User, Appointment.patient_id == User.id
    ).filter(
        Appointment.clinic_id == hospital_id  # Changed from hospital_id to clinic_id
    ).order_by(
        Appointment.appointment_date.desc()
    ).limit(50).all()
    
    result = []
    for apt in appointments:
        result.append({
            'id': apt.Appointment.id,
            'fullName': apt.patient_name or 'Unknown Patient',
            'mobileNumber': '',  # You can join with User.phone if needed
            'email': '',  # Join with User.email if needed
            'appointmentType': 'Consultation',
            'reason': apt.Appointment.reason or '',
            'status': apt.Appointment.status.value if apt.Appointment.status else 'scheduled',
            'date': apt.Appointment.appointment_date.isoformat() if apt.Appointment.appointment_date else '',
            'clinicName': hospital_id,
        })
    
    return result

@router.get("/firebase/patients/{clinicId}", response_model=List[dict])
async def get_patients_from_firebase(
    clinicId: str,
    current_user: User = Depends(get_current_active_user)
):
    """Fetch patient registrations directly from Firebase Firestore"""
    import requests
    
    firebase_project_id = 'patient-qr-registration'
    firebase_api_key = 'AIzaSyD9h9Y_1_QmUHpJHK-66dtvUG6l5eUIa98'
    
    # Query qr_registrations collection (NOT patients)
    url = f'https://firestore.googleapis.com/v1/projects/{firebase_project_id}/databases/(default)/documents/qr_registrations?key={firebase_api_key}'
    
    try:
        response = requests.get(url, timeout=10)
        print(f"Firebase API Response Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            documents = data.get('documents', [])
            print(f"Found {len(documents)} total QR registrations in Firebase")
            
            # Filter by clinic/hospital ID
            filtered = []
            for doc in documents:
                fields = doc.get('fields', {})
                hospital_id = fields.get('hospitalId', {}).get('stringValue', '')
                
                if hospital_id == clinicId:
                    filtered.append({
                        'id': doc.get('name', '').split('/').pop(),
                        'fullName': f"{fields.get('firstName', {}).get('stringValue', '')} {fields.get('lastName', {}).get('stringValue', '')}".strip() or 'Unknown',
                        'mobileNumber': fields.get('mobileNumber', {}).get('stringValue', ''),
                        'email': fields.get('email', {}).get('stringValue', ''),
                        'hospitalId': hospital_id,
                        'hospitalName': fields.get('hospitalName', {}).get('stringValue', ''),
                        'visitType': fields.get('visitType', {}).get('stringValue', 'Consultation'),
                        'symptoms': fields.get('symptoms', {}).get('stringValue', ''),
                        'status': fields.get('status', {}).get('stringValue', 'registered'),
                        'createdAt': fields.get('createdAt', {}).get('stringValue', ''),
                    })
            
            print(f"Filtered to {len(filtered)} patients for clinic {clinicId}")
            return filtered
        else:
            print(f"Firebase API error: {response.status_code}")
            return []
            
    except Exception as e:
        print(f"Error fetching from Firebase: {e}")
        return []

@router.get("/firebase/mr/{clinicId}", response_model=List[dict])
async def get_mr_from_firebase(
    clinicId: str,
    current_user: User = Depends(get_current_active_user)
):
    """Fetch MR registrations directly from Firebase Firestore"""
    import requests
    
    firebase_project_id = 'patient-qr-registration'
    firebase_api_key = 'AIzaSyD9h9Y_1_QmUHpJHK-66dtvUG6l5eUIa98'
    
    # Use the working URL format without subdomain
    url = f'https://firestore.googleapis.com/v1/projects/{firebase_project_id}/databases/(default)/documents/mr_registrations?key={firebase_api_key}'
    
    try:
        response = requests.get(url, timeout=10)
        print(f"Firebase MR API Response Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            documents = data.get('documents', [])
            print(f"Found {len(documents)} total MR registrations in Firebase")
            
            # Filter by clinic/hospital ID
            filtered = []
            for doc in documents:
                fields = doc.get('fields', {})
                hospital_id = fields.get('hospitalId', {}).get('stringValue', '')
                
                if hospital_id == clinicId:
                    filtered.append({
                        'id': doc.get('name', '').split('/').pop(),
                        'fullName': fields.get('fullName', {}).get('stringValue', 'Unknown MR'),
                        'mobileNumber': fields.get('mobileNumber', {}).get('stringValue', ''),
                        'email': fields.get('email', {}).get('stringValue', ''),
                        'hospitalId': hospital_id,
                        'hospitalName': fields.get('hospitalName', {}).get('stringValue', ''),
                        'visitType': fields.get('visitPurpose', {}).get('stringValue', 'Information Sharing'),
                        'symptoms': fields.get('specialty', {}).get('stringValue', 'General'),
                        'status': fields.get('status', {}).get('stringValue', 'pending'),
                        'createdAt': fields.get('createdAt', {}).get('stringValue', ''),
                    })
            
            print(f"Filtered to {len(filtered)} MR registrations for clinic {clinicId}")
            return filtered
        else:
            print(f"Firebase API error: {response.status_code}")
            return []
            
    except Exception as e:
        print(f"Error fetching from Firebase: {e}")
        return []

