from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, JSON, Boolean, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    hospital_id = Column(String, ForeignKey("clinics.id"), nullable=False)  # Changed from clinic_id to hospital_id to match database
    specialization = Column(String, nullable=False)
    qualification = Column(String, nullable=True)
    experience_years = Column(Integer, default=0)
    bio = Column(String, nullable=True)
    consultation_fee = Column(Integer, default=0)
    availability = Column(JSON, default=dict)  # { "monday": ["09:00-12:00", "14:00-17:00"], ... }
    is_available = Column(Integer, default=1)
    rating = Column(Float, default=0.0)
    total_appointments = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="doctor")
    clinic = relationship("Clinic", back_populates="doctors")  # Note: Still refers to clinic relationship
    appointments = relationship("Appointment", back_populates="doctor")
    resources = relationship("Resource", back_populates="doctor")