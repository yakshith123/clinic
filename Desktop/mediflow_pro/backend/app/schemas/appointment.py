from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum

class AppointmentStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"

# Appointment Schemas
class AppointmentBase(BaseModel):
    appointment_date: datetime
    time_slot: str
    department: str
    reason: Optional[str] = None

class AppointmentCreate(AppointmentBase):
    patient_id: str
    doctor_id: str
    hospital_id: str
    patient_latitude: Optional[float] = None
    patient_longitude: Optional[float] = None

class AppointmentUpdate(BaseModel):
    appointment_date: Optional[datetime] = None
    time_slot: Optional[str] = None
    department: Optional[str] = None
    reason: Optional[str] = None
    status: Optional[AppointmentStatus] = None
    queue_position: Optional[int] = None
    notes: Optional[str] = None

class AppointmentResponse(AppointmentBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    patient_id: str
    doctor_id: str
    hospital_id: str
    status: AppointmentStatus
    queue_position: int
    estimated_wait_time: int
    patient_latitude: Optional[float] = None
    patient_longitude: Optional[float] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

class AppointmentWithDetails(AppointmentResponse):
    patient_name: Optional[str] = None
    doctor_name: Optional[str] = None
    hospital_name: Optional[str] = None

