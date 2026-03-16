from fastapi import APIRouter, Depends, HTTPException
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.routers.auth import get_current_active_user
from app.models.user import User

router = APIRouter(tags=["QR Registrations"])

# Mock data for testing - replace with actual database queries
MOCK_QR_DATA = [
    {
        "id": "1",
        "email": "abc@gmail.com",
        "firstName": "abc",
        "lastName": "ac",
        "fullName": "abc ac",
        "mobileNumber": "8431952036",
        "hospitalId": "apollo_delhi",
        "hospitalName": "Apollo Hospitals (Delhi)",
        "symptoms": "adw",
        "visitType": "Prescription Refill",
        "status": "registered",
        "createdAt": "2026-03-02T11:27:02.945Z"
    },
    {
        "id": "2",
        "email": "patient2@gmail.com",
        "firstName": "John",
        "lastName": "Doe",
        "fullName": "John Doe",
        "mobileNumber": "9876543210",
        "hospitalId": "max_delhi",
        "hospitalName": "Max Super Speciality Clinic",
        "symptoms": "Fever and cough",
        "visitType": "General Checkup",
        "status": "registered",
        "createdAt": "2026-03-02T10:15:30.123Z"
    }
]

@router.get("/")
async def get_qr_registrations(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get all QR registrations"""
    # For now, return mock data
    # In production, query from your database
    return MOCK_QR_DATA

@router.get("/hospital/{hospital_id}")
async def get_qr_registrations_by_hospital(
    hospital_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get QR registrations by hospital"""
    filtered_data = [reg for reg in MOCK_QR_DATA if reg["hospitalId"] == hospital_id]
    return filtered_data

@router.get("/status/{status}")
async def get_qr_registrations_by_status(
    status: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get QR registrations by status"""
    filtered_data = [reg for reg in MOCK_QR_DATA if reg["status"] == status]
    return filtered_data