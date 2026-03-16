from sqlalchemy import Column, String, Integer, DateTime, Float, Boolean, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class Clinic(Base):
    __tablename__ = "clinics"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    address = Column(String, nullable=False)
    city = Column(String, nullable=False)
    state = Column(String, nullable=False)
    country = Column(String, default="USA")
    postal_code = Column(String, nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    phone = Column(String, nullable=False)
    email = Column(String, nullable=False)
    departments = Column(JSON, default=list)  # List of department names
    is_active = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    users = relationship("User", back_populates="clinic")
    associated_users = relationship("User", secondary="user_clinics", back_populates="associated_clinics")
    doctors = relationship("Doctor", back_populates="clinic")
    appointments = relationship("Appointment", back_populates="clinic")
    resources = relationship("Resource", back_populates="clinic")
