from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from enum import Enum

class QueueStatus(str, Enum):
    WAITING = "waiting"
    CALLED = "called"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"

# Queue Schemas
class QueueBase(BaseModel):
    current_position: int
    status: QueueStatus = QueueStatus.WAITING

class QueueCreate(QueueBase):
    appointment_id: str
    hospital_id: str
    doctor_id: str

class QueueUpdate(BaseModel):
    current_position: Optional[int] = None
    status: Optional[QueueStatus] = None
    called_time: Optional[datetime] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    estimated_wait_time: Optional[int] = None
    actual_wait_time: Optional[int] = None

class QueueResponse(QueueBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    appointment_id: str
    hospital_id: str
    doctor_id: int
    check_in_time: datetime
    called_time: Optional[datetime] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    estimated_wait_time: int
    actual_wait_time: int
    created_at: datetime
    updated_at: Optional[datetime] = None

class QueueWithDetails(QueueResponse):
    patient_name: Optional[str] = None
    patient_phone: Optional[str] = None
    appointment_time: Optional[str] = None
    reason: Optional[str] = None

