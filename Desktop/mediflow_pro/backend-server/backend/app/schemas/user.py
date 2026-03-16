from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class UserRole(str, Enum):
    PATIENT = "patient"
    DOCTOR = "doctor"
    ADMIN = "admin"
    HOSPITAL_ADMIN = "hospital_admin"
    
class UserCreate(BaseModel):
    email: EmailStr
    password: Optional[str] = Field(None, min_length=6)  # Made optional for Google users
    name: str
    phone: str = "+1234567890"
    role: UserRole = UserRole.PATIENT
    clinic_id: Optional[str] = None
    department: Optional[str] = None
    associated_clinic_ids: Optional[List[str]] = None  # Add this field for multiple clinic associations
    is_google_user: Optional[bool] = False  # New field for Google users
    google_id: Optional[str] = None  # New field for Google ID

class UserLogin(BaseModel):
    email: EmailStr
    password: Optional[str] = None  # Made optional for Google users

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: Optional[dict] = None

class TokenData(BaseModel):
    user_id: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    department: Optional[str] = None
    fcm_token: Optional[str] = None

# Response Schemas
class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    phone: str
    role: UserRole
    clinic_id: Optional[str] = None
    department: Optional[str] = None
    associated_clinic_ids: Optional[List[str]] = None  # Add field for multiple clinic associations
    is_active: int
    is_google_user: bool  # New field for Google users
    google_id: Optional[str] = None  # New field for Google ID
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

class UserInDB(UserResponse):
    password_hash: Optional[str] = None  # Made optional for Google users

# Hospital Schemas
class HospitalBase(BaseModel):
    name: str
    address: str
    city: str
    state: str
    country: str = "USA"
    postal_code: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: str
    email: EmailStr
    departments: List[str] = []

class HospitalCreate(HospitalBase):
    pass

class HospitalUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    departments: Optional[List[str]] = None
    is_active: Optional[int] = None

class HospitalResponse(HospitalBase):
    id: str
    is_active: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

# Doctor Schemas
class DoctorBase(BaseModel):
    specialization: str
    qualification: Optional[str] = None
    experience_years: int = 0
    bio: Optional[str] = None
    consultation_fee: int = 0

class DoctorCreate(DoctorBase):
    user_id: str
    clinic_id: str
    availability: dict = {}

class DoctorUpdate(BaseModel):
    specialization: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None
    bio: Optional[str] = None
    consultation_fee: Optional[int] = None
    availability: Optional[dict] = None
    is_available: Optional[int] = None

class DoctorResponse(DoctorBase):
    id: str
    user_id: str
    clinic_id: str
    availability: dict
    is_available: int
    rating: float
    total_appointments: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

class DoctorWithUser(DoctorResponse):
    user: UserResponse

    model_config = {"from_attributes": True}

# OTP / Forgot Password Schemas
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6)

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6)

class OTPResponse(BaseModel):
    message: str
    email: str
    # For testing purposes only - remove in production
    otp_code: Optional[str] = None
    
class PasswordResetSuccess(BaseModel):
    message: str

