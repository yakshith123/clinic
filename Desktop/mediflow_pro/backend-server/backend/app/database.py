from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings


engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20
)


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    from app.models import user, clinic, doctor, appointment, queue
    Base.metadata.create_all(bind=engine)
    
    # Add default hospitals if none exist
    db = SessionLocal()
    try:
        hospital_count = db.query(Clinic).count()
        if hospital_count == 0:
            # Add default clinics
            default_clinics = [
                {
                    'name': 'Apollo Clinics',
                    'address': '21, Greams Road, Thousand Lights',
                    'city': 'Chennai',
                    'state': 'Tamil Nadu',
                    'country': 'India',
                    'postal_code': '600006',
                    'latitude': 13.0720,
                    'longitude': 80.2428,
                    'phone': '+91-44-28291122',
                    'email': 'info@apollohospitals.com',
                    'departments': ['Cardiology', 'Orthopedics', 'Neurology', 'Pediatrics', 'Oncology']
                },
                {
                    'name': 'BLK Super Speciality Clinic',
                    'address': 'P-7, Block P, Rajender Nagar',
                    'city': 'New Delhi',
                    'state': 'Delhi',
                    'country': 'India',
                    'postal_code': '110009',
                    'latitude': 28.6480,
                    'longitude': 77.2000,
                    'phone': '+91-11-25846000',
                    'email': 'contact@blkhospital.com',
                    'departments': ['Cardiology', 'Neurosurgery', 'Urology', 'Gastroenterology', 'IVF']
                },
                {
                    'name': 'Max Super Speciality Clinic',
                    'address': '1, 2, Press Enclave Marg, Saket',
                    'city': 'New Delhi',
                    'state': 'Delhi',
                    'country': 'India',
                    'postal_code': '110017',
                    'latitude': 28.5355,
                    'longitude': 77.2090,
                    'phone': '+91-11-26515050',
                    'email': 'info@maxhealthcare.in',
                    'departments': ['Cardiology', 'Oncology', 'Nephrology', 'Orthopedics', 'Neurology']
                },
                {
                    'name': 'Medanta Clinic',
                    'address': 'Plot No. 1, Sector 38, Aravali Hills',
                    'city': 'Gurugram',
                    'state': 'Haryana',
                    'country': 'India',
                    'postal_code': '122001',
                    'latitude': 28.4595,
                    'longitude': 77.0266,
                    'phone': '+91-124-4141414',
                    'email': 'contact@medantahospital.com',
                    'departments': ['Cardiology', 'Orthopedics', 'Liver Transplant', 'Kidney Transplant', 'Robotic Surgery']
                },
                {
                    'name': 'Artemis Clinic',
                    'address': 'Sector 56, Golf Course Road',
                    'city': 'Gurugram',
                    'state': 'Haryana',
                    'country': 'India',
                    'postal_code': '122002',
                    'latitude': 28.4400,
                    'longitude': 77.0600,
                    'phone': '+91-124-4277777',
                    'email': 'info@artemishospital.net',
                    'departments': ['Cardiology', 'Oncology', 'Obstetrics', 'Gynecology', 'Pediatrics']
                },
                {
                    'name': 'Wockhardt Clinic',
                    'address': 'Rajiv Gandhi Salai, OMR',
                    'city': 'Chennai',
                    'state': 'Tamil Nadu',
                    'country': 'India',
                    'postal_code': '600095',
                    'latitude': 12.8968,
                    'longitude': 80.2363,
                    'phone': '+91-44-27777777',
                    'email': 'contact@wockhardt.com',
                    'departments': ['Cardiology', 'Orthopedics', 'Neurology', 'Critical Care', 'Transplants']
                },
                {
                    'name': 'Narayana Health Clinic',
                    'address': '258/A, Bommasandra Industrial Estate',
                    'city': 'Bangalore',
                    'state': 'Karnataka',
                    'country': 'India',
                    'postal_code': '560099',
                    'latitude': 12.8880,
                    'longitude': 77.6750,
                    'phone': '+91-80-26764060',
                    'email': 'info@narayanahospitals.com',
                    'departments': ['Cardiology', 'Cardiac Surgery', 'Neurosurgery', 'Orthopedics', 'Nephrology']
                },
                {
                    'name': 'Columbia Asia Clinic',
                    'address': '14/1, Old Airport Road, HAL 2nd Stage',
                    'city': 'Bangalore',
                    'state': 'Karnataka',
                    'country': 'India',
                    'postal_code': '560008',
                    'latitude': 12.9510,
                    'longitude': 77.6480,
                    'phone': '+91-80-49544444',
                    'email': 'enquiry@columbiaworld.com',
                    'departments': ['Cardiology', 'Orthopedics', 'Dermatology', 'ENT', 'Ophthalmology']
                }
            ]
            
            for clinic_data in default_clinics:
                clinic = Clinic(**clinic_data)
                db.add(clinic)
            
            db.commit()
            print(f"Added {len(default_clinics)} default clinics to the database")
    except Exception as e:
        print(f"Error adding default clinics: {e}")
        db.rollback()
    finally:
        db.close()