from pydantic import BaseModel, Field

class SMSPatientRegistration(BaseModel):
    patientName: str = Field(..., description="Patient's full name")
    clinicName: str = Field(..., description="Clinic/Hospital name")
    phoneNumber: str = Field(..., description="Patient's phone number with country code")

class SMMRAppointment(BaseModel):
    mrName: str = Field(..., description="MR's full name")
    clinicName: str = Field(..., description="Clinic/Hospital name")
    phoneNumber: str = Field(..., description="MR's phone number with country code")
    appointmentDate: str = Field(..., description="Preferred appointment date")
    appointmentTime: str = Field(..., description="Preferred appointment time")
