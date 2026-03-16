from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class ResourceType(enum.Enum):
    EQUIPMENT = "equipment"
    AMBULANCE = "ambulance"
    MEDICINE = "medicine"
    LAB_REPORT = "lab_report"
    OTHER = "other"

class Resource(Base):
    __tablename__ = "resources"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    company = Column(String, nullable=True)
    contact_person = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    contact_email = Column(String, nullable=True)
    type = Column(Enum(ResourceType), default=ResourceType.OTHER)
    doctor_id = Column(String, ForeignKey("doctors.id"), nullable=True)
    clinic_id = Column(String, ForeignKey("clinics.id"), nullable=False)
    scheduled_date = Column(DateTime, nullable=True)
    time_slot = Column(String, nullable=True)
    status = Column(String, default="available")  # available, in_use, maintenance
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    doctor = relationship("Doctor", back_populates="resources")
    clinic = relationship("Clinic", back_populates="resources")

