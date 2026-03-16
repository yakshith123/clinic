from pydantic import BaseModel, Field, EmailStr

class EmailPatientRegistration(BaseModel):
    patientName: str = Field(..., description="Patient's full name")
    clinicName: str = Field(..., description="Clinic/Hospital name")
    email: EmailStr = Field(..., description="Patient's email address")
    visitType: str = Field(..., description="Type of visit (Consultation, Follow-up, etc.)")
    appointmentDate: str = Field(..., description="Appointment date")

class EmailMRAppointment(BaseModel):
    mrName: str = Field(..., description="MR's full name")
    clinicName: str = Field(..., description="Clinic/Hospital name")
    email: EmailStr = Field(..., description="MR's email address")
    appointmentDate: str = Field(..., description="Preferred appointment date")
    appointmentTime: str = Field(..., description="Preferred appointment time")
    specialty: str = Field(..., description="MR's specialty/department")
