from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class QueueStatus(enum.Enum):
    WAITING = "waiting"
    CALLED = "called"
    IN_PROGRESS = "in_progress"
    COMPLETED = "cancelled"
    SKIPPED = "skipped"

class Queue(Base):
    __tablename__ = "queues"

    id = Column(String, primary_key=True, default=generate_uuid)
    appointment_id = Column(String, ForeignKey("appointments.id"), nullable=False, unique=True)
    clinic_id = Column(String, ForeignKey("clinics.id"), nullable=False)
    doctor_id = Column(String, ForeignKey("doctors.id"), nullable=False)
    current_position = Column(Integer, nullable=False, default=0)
    status = Column(Enum(QueueStatus), default=QueueStatus.WAITING)
    check_in_time = Column(DateTime(timezone=True), server_default=func.now())
    called_time = Column(DateTime(timezone=True), nullable=True)
    start_time = Column(DateTime(timezone=True), nullable=True)
    end_time = Column(DateTime(timezone=True), nullable=True)
    estimated_wait_time = Column(Integer, default=0)  # in minutes
    actual_wait_time = Column(Integer, default=0)  # in minutes
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    appointment = relationship("Appointment", back_populates="queue")

