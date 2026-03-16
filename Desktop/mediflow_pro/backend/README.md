# MediFlow Pro Backend

FastAPI-based backend for MediFlow Pro - Healthcare Queue & Resource Management System

## Features

- ✅ User Authentication (JWT)
- ✅ Appointment Management
- ✅ Real-time Queue Management
- ✅ Hospital & Doctor Management
- ✅ Push Notifications (Firebase)
- ✅ RESTful API
- ✅ PostgreSQL Database

## Tech Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Authentication**: JWT (Python-Jose)
- **Password Hashing**: Bcrypt
- **Notifications**: Firebase Cloud Messaging

## Prerequisites

- Python 3.9+
- PostgreSQL
- Firebase Project (for notifications)

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your settings
```

Required environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT secret key
- `FIREBASE_CREDENTIALS_PATH`: Path to Firebase credentials JSON

### 3. Setup Database

Make sure PostgreSQL is running and create the database:

```sql
CREATE DATABASE mediflow_db;
```

### 4. Run the Server

```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

### 5. API Documentation

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user

### Appointments
- `POST /api/appointments` - Create appointment
- `GET /api/appointments` - Get appointments
- `GET /api/appointments/{id}` - Get appointment details
- `PUT /api/appointments/{id}` - Update appointment
- `DELETE /api/appointments/{id}` - Cancel appointment

### Queue
- `GET /api/queue/hospital/{id}` - Get hospital queue
- `GET /api/queue/doctor/{id}` - Get doctor queue
- `PUT /api/queue/{id}/call` - Call patient
- `PUT /api/queue/{id}/start` - Start consultation
- `PUT /api/queue/{id}/complete` - Complete consultation

### Hospitals
- `POST /api/hospitals` - Create hospital
- `GET /api/hospitals` - List hospitals
- `GET /api/hospitals/{id}` - Get hospital details

### Doctors
- `POST /api/doctors` - Create doctor profile
- `GET /api/doctors` - List doctors
- `GET /api/doctors/{id}` - Get doctor details
- `PUT /api/doctors/{id}` - Update doctor

## Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Go to Project Settings > Service Accounts
4. Generate new private key
5. Save as `firebase-credentials.json` in backend folder

## Project Structure

```
backend/
├── app/
│   ├── config.py          # Configuration
│   ├── database.py        # Database setup
│   ├── main.py            # FastAPI app
│   ├── models/            # SQLAlchemy models
│   ├── routers/           # API endpoints
│   ├── schemas/           # Pydantic schemas
│   └── utils/             # Utility functions
├── requirements.txt
├── .env.example
└── README.md
```

## License

MIT

