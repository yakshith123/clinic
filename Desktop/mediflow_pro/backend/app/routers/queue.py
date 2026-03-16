from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import datetime

from app.database import get_db
from app.models.user import User, UserRole
from app.models.queue import Queue, QueueStatus
from app.models.appointment import Appointment, AppointmentStatus
from app.schemas.queue import (
    QueueCreate,
    QueueUpdate,
    QueueResponse,
    QueueWithDetails,
)
from app.schemas.queue import QueueStatus as QueueStatusSchema
from app.schemas.appointment import AppointmentStatus as AppointmentStatusSchema
from app.routers.auth import get_current_active_user
from app.utils.firebase import send_notification

router = APIRouter(prefix="/queue", tags=["Queue"])

@router.get("/hospital/{hospital_id}", response_model=List[QueueWithDetails])
async def get_hospital_queue(
    hospital_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all queue entries for a hospital"""
    # Check authorization
    if current_user.role not in [UserRole.ADMIN, UserRole.HOSPITAL_ADMIN]:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    queues = db.query(Queue).filter(
        Queue.hospital_id == hospital_id,
        Queue.status == QueueStatus.WAITING
    ).order_by(Queue.current_position.asc()).all()
    
    result = []
    for q in queues:
        appointment = db.query(Appointment).filter(Appointment.id == q.appointment_id).first()
        patient = db.query(User).filter(User.id == appointment.patient_id).first() if appointment else None
        
        result.append(QueueWithDetails(
            **q.__dict__,
            patient_name=patient.name if patient else None,
            patient_phone=patient.phone if patient else None,
            appointment_time=appointment.time_slot if appointment else None,
            reason=appointment.reason if appointment else None,
        ))
    
    return result

@router.get("/doctor/{doctor_id}", response_model=List[QueueWithDetails])
async def get_doctor_queue(
    doctor_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all queue entries for a doctor"""
    queues = db.query(Queue).filter(
        Queue.doctor_id == doctor_id
    ).order_by(Queue.current_position.asc()).all()
    
    result = []
    for q in queues:
        appointment = db.query(Appointment).filter(Appointment.id == q.appointment_id).first()
        patient = db.query(User).filter(User.id == appointment.patient_id).first() if appointment else None
        
        result.append(QueueWithDetails(
            **q.__dict__,
            patient_name=patient.name if patient else None,
            patient_phone=patient.phone if patient else None,
            appointment_time=appointment.time_slot if appointment else None,
            reason=appointment.reason if appointment else None,
        ))
    
    return result

@router.get("/{appointment_id}", response_model=QueueWithDetails)
async def get_queue_by_appointment(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get queue entry for a specific appointment"""
    queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    
    if not queue:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    patient = db.query(User).filter(User.id == appointment.patient_id).first() if appointment else None
    
    return QueueWithDetails(
        **queue.__dict__,
        patient_name=patient.name if patient else None,
        patient_phone=patient.phone if patient else None,
        appointment_time=appointment.time_slot if appointment else None,
        reason=appointment.reason if appointment else None,
    )

@router.put("/{appointment_id}/call", response_model=QueueResponse)
async def call_patient(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Call next patient in queue"""
    queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    
    if not queue:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    # Update queue status
    queue.status = QueueStatus.CALLED
    queue.called_time = datetime.now()
    db.commit()
    
    # Update appointment status
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment:
        appointment.status = AppointmentStatus.IN_PROGRESS
        db.commit()
        
        # Send notification to patient
        patient = db.query(User).filter(User.id == appointment.patient_id).first()
        if patient and patient.fcm_token:
            send_notification(
                token=patient.fcm_token,
                title="You're Next!",
                body="Please proceed to the consultation room",
                data={"appointment_id": appointment_id}
            )
    
    return queue

@router.put("/{appointment_id}/start", response_model=QueueResponse)
async def start_consultation(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Start consultation"""
    queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    
    if not queue:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    queue.status = QueueStatus.IN_PROGRESS
    queue.start_time = datetime.now()
    db.commit()
    
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment:
        appointment.status = AppointmentStatus.IN_PROGRESS
        db.commit()
    
    return queue

@router.put("/{appointment_id}/complete", response_model=QueueResponse)
async def complete_consultation(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Complete consultation"""
    queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    
    if not queue:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    queue.status = QueueStatus.COMPLETED
    queue.end_time = datetime.now()
    
    if queue.start_time:
        queue.actual_wait_time = int((queue.end_time - queue.start_time).total_seconds() / 60)
    
    db.commit()
    
    # Update appointment status
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment:
        appointment.status = AppointmentStatus.COMPLETED
        db.commit()
        
        # Recalculate queue positions for remaining appointments
        remaining_queues = db.query(Queue).filter(
            Queue.doctor_id == queue.doctor_id,
            Queue.status == QueueStatus.WAITING,
            Queue.current_position > queue.current_position
        ).all()
        
        for q in remaining_queues:
            q.current_position -= 1
            q.estimated_wait_time = (q.current_position - 1) * 15
        
        db.commit()
    
    return queue

@router.put("/{appointment_id}/skip", response_model=QueueResponse)
async def skip_patient(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Skip current patient"""
    queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    
    if not queue:
        raise HTTPException(status_code=404, detail="Queue entry not found")
    
    queue.status = QueueStatus.SKIPPED
    db.commit()
    
    # Update appointment status
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment:
        appointment.status = AppointmentStatus.NO_SHOW
        db.commit()
    
    return queue

@router.post("/check-in/{appointment_id}", response_model=QueueResponse)
async def check_in(
    appointment_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Patient check-in for appointment"""
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Check if patient owns this appointment
    if appointment.patient_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    # Check if already checked in
    existing_queue = db.query(Queue).filter(Queue.appointment_id == appointment_id).first()
    if existing_queue:
        raise HTTPException(status_code=400, detail="Already checked in")
    
    #="Already checked in Get current queue count for this doctor
    queue_count = db.query(func.count(Queue.id)).filter(
        Queue.doctor_id == appointment.doctor_id,
        Queue.status == QueueStatus.WAITING
    ).scalar() or 0
    
    # Create queue entry
    queue = Queue(
        appointment_id=appointment_id,
        hospital_id=appointment.hospital_id,
        doctor_id=appointment.doctor_id,
        current_position=queue_count + 1,
        estimated_wait_time=queue_count * 15,
    )
    
    db.add(queue)
    db.commit()
    db.refresh(queue)
    
    return queue

