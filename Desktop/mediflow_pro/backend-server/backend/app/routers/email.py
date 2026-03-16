from fastapi import APIRouter, HTTPException
from app.schemas.email import EmailPatientRegistration, EmailMRAppointment
from app.services.email_service import email_service
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/email", tags=["Email"])

@router.post("/send-patient-registration-confirmation")
async def send_patient_registration_email(email_data: EmailPatientRegistration):
    """Send email confirmation to registered patient"""
    try:
        success = await email_service.send_patient_registration_email(
            patient_name=email_data.patientName,
            clinic_name=email_data.clinicName,
            patient_email=email_data.email,
            visit_type=email_data.visitType,
            appointment_date=email_data.appointmentDate
        )
        
        if success:
            return {"message": "Email sent successfully", "success": True}
        else:
            raise HTTPException(status_code=500, detail="Failed to send email")
    except Exception as e:
        logger.error(f"Error in send_patient_registration_email: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-mr-appointment-confirmation")
async def send_mr_appointment_email(email_data: EmailMRAppointment):
    """Send email confirmation to MR after appointment request"""
    try:
        success = await email_service.send_mr_appointment_email(
            mr_name=email_data.mrName,
            clinic_name=email_data.clinicName,
            mr_email=email_data.email,
            appointment_date=email_data.appointmentDate,
            appointment_time=email_data.appointmentTime,
            specialty=email_data.specialty
        )
        
        if success:
            return {"message": "Email sent successfully", "success": True}
        else:
            raise HTTPException(status_code=500, detail="Failed to send email")
    except Exception as e:
        logger.error(f"Error in send_mr_appointment_email: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
