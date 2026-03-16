from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum, Float, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class AppointmentStatus(enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"

class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(String, primary_key=True, default=generate_uuid)
    patient_id = Column(String, ForeignKey("users.id"), nullable=False)
    doctor_id = Column(String, ForeignKey("doctors.id"), nullable=False)
    clinic_id = Column(String, ForeignKey("clinics.id"), nullable=True)  # Made nullable
    appointment_date = Column(DateTime, nullable=False)
    time_slot = Column(String, nullable=False)  # e.g., "09:00-09:30"
    department = Column(String, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(Enum(AppointmentStatus), default=AppointmentStatus.PENDING)
    queue_position = Column(Integer, default=0)
    estimated_wait_time = Column(Integer, default=0)  # in minutes
    patient_latitude = Column(Float, nullable=True)
    patient_longitude = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    patient = relationship("User", back_populates="patient_appointments", foreign_keys=[patient_id])
    doctor = relationship("Doctor", back_populates="appointments")
    clinic = relationship("Clinic", back_populates="appointments")
    queue = relationship("Queue", back_populates="appointment", uselist=False)

