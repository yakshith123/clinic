from sqlalchemy import Column, String, Integer, DateTime, Enum, Float, ForeignKey, Text, Table, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid

def generate_uuid():
    return str(uuid.uuid4())

# Junction table for many-to-many relationship between users and hospitals
user_clinics = Table(
    'user_clinics',
    Base.metadata,
    Column('user_id', String, ForeignKey('users.id'), primary_key=True),
    Column('clinic_id', String, ForeignKey('clinics.id'), primary_key=True)
)

class UserRole(enum.Enum):
    PATIENT = "patient"
    DOCTOR = "doctor"
    ADMIN = "admin"
    HOSPITAL_ADMIN = "hospital_admin"

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True)  # Made nullable for Google users
    name = Column(String, nullable=False)
    phone = Column(String, default="+1234567890")
    role = Column(Enum(UserRole), default=UserRole.PATIENT)
    clinic_id = Column(String, ForeignKey("clinics.id"), nullable=True)
    department = Column(String, nullable=True)
    fcm_token = Column(String, nullable=True)  # Firebase Cloud Messaging token
    is_active = Column(Integer, default=1)
    
    # Google Sign-In fields
    is_google_user = Column(Boolean, default=False)
    google_id = Column(String, nullable=True, unique=True)
    
    # OTP fields for password reset
    otp_code = Column(String, nullable=True)
    otp_expires_at = Column(DateTime(timezone=True), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    clinic = relationship("Clinic", back_populates="users")
    associated_clinics = relationship("Clinic", secondary="user_clinics", back_populates="associated_users")
    doctor = relationship("Doctor", back_populates="user", uselist=False)
    patient_appointments = relationship("Appointment", back_populates="patient", foreign_keys="Appointment.patient_id")