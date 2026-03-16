from app.routers.auth import router as auth_router
from app.routers.appointments import router as appointments_router
from app.routers.queue import router as queue_router
from app.routers.clinics import router as clinics_router
from app.routers.doctors import router as doctors_router
from app.routers.qr import router as qr_router
from app.routers.sms import router as sms_router
from app.routers.email import router as email_router
from app.routers.ads import router as ads_router

__all__ = [
    "auth_router",
    "appointments_router",
    "queue_router",
    "clinics_router",
    "doctors_router",
    "qr_router",
    "sms_router",
    "email_router",
    "ads_router",
]

