# 🏥 MediFlow Pro - Complete Healthcare Management Platform

[![License](https://img.shields.io/badge/license-proprietary-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.5.0+-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100.0+-green.svg)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18-blue.svg)](https://reactjs.org)

**Transforming healthcare facility management with smart queuing, real-time tracking, and seamless coordination between patients, doctors, and resources.**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Repository Structure](#repository-structure)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Installation & Setup](#installation--setup)
  - [1. Mobile App (Flutter)](#1-mobile-app-flutter)
  - [2. Backend Server (FastAPI)](#2-backend-server-fastapi)
  - [3. Web App (QR Registration)](#3-web-app-qr-registration)
- [Running the Application](#running-the-application)
- [User Roles](#user-roles)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Support](#support)

---

## 🎯 Overview

MediFlow Pro is a **comprehensive healthcare management platform** that solves one critical problem: **hospital waiting room congestion**. Our system combines:

- 📱 **Mobile App** (Flutter) - For patients, doctors, and administrators
- 🔌 **Backend API** (FastAPI + Python) - Robust RESTful services
- 🌐 **Web App** (React + Vite) - QR registration portal

The platform uses **real-time location tracking**, **smart queuing algorithms**, and **dual-panel management** to ensure patients and medical staff arrive only when needed.

---

## ✨ Key Features

### Multi-Role Management System

#### 👨‍💼 Admin Panel
- Hospital and facility management
- Staff onboarding and role assignment
- System-wide analytics and reporting
- User management across all roles

#### 👨‍⚕️ Doctor Panel
- **Dual-Queue Dashboard**: Manage patients and resources simultaneously
- One-touch session start/stop
- Real-time queue management
- Patient history and resource coordination

#### 🧑 Patient Panel
- QR code check-in/check-out
- Real-time queue position tracking
- Proximity-based notifications
- Appointment booking and history

#### 🔧 Consultant Panel
- Equipment and specialist scheduling
- Resource availability management
- Integration with patient flow

### Smart Features

- ✅ **Location-Based Intelligence**: GPS tracking with Google Maps
- ✅ **Smart Queuing**: Dynamic queue positioning with predictive alerts
- ✅ **QR Code System**: Hospital and personal QR codes
- ✅ **Real-time Notifications**: Firebase Cloud Messaging
- ✅ **Dual Queue Management**: Patients + Resources synchronization

---

## 📁 Repository Structure

```
clinic/
├── mobile-app/              # Flutter Mobile Application
│   ├── lib/                 # Dart source code
│   │   ├── screens/         # UI screens (admin, doctor, patient)
│   │   ├── services/        # Business logic
│   │   ├── providers/       # State management
│   │   ├── widgets/         # Reusable components
│   │   └── main.dart        # App entry point
│   ├── android/             # Android platform files
│   ├── ios/                 # iOS platform files
│   ├── web-app/             # React QR Registration Portal
│   │   ├── src/             # React components
│   │   ├── package.json     # Node dependencies
│   │   └── vite.config.js   # Vite config
│   ├── pubspec.yaml         # Flutter dependencies
│   └── analysis_options.yaml # Dart linting
│
├── backend-server/          # FastAPI Backend
│   └── backend/             # Python backend code
│       ├── app/
│       │   ├── models/      # SQLAlchemy models
│       │   ├── routers/     # API endpoints
│       │   ├── schemas/     # Pydantic validation
│       │   ├── services/    # Email/SMS services
│       │   ├── utils/       # Helpers
│       │   ├── main.py      # FastAPI app
│       │   └── database.py  # DB connection
│       ├── requirements.txt # Python dependencies
│       ├── Dockerfile       # Docker config
│       └── docker-compose.yml # Docker compose
│
├── README.md                # This file
└── GITHUB_README.md         # Extended documentation
```

---

## 💻 Tech Stack

### Mobile Application
| Technology | Purpose |
|------------|---------|
| **Flutter 3.5.0+** | Cross-platform framework |
| **Provider** | State management |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time database |
| **Google Maps** | Location services |
| **qr_flutter** | QR code generation |
| **mobile_scanner** | QR code scanning |

### Backend API
| Technology | Purpose |
|------------|---------|
| **FastAPI 0.100.0+** | Modern Python framework |
| **Python 3.9+** | Backend programming |
| **SQLAlchemy** | ORM for database |
| **PostgreSQL** | Primary database |
| **Pydantic** | Data validation |
| **JWT** | Token authentication |

### Web Application (QR Portal)
| Technology | Purpose |
|------------|---------|
| **React 18** | Frontend framework |
| **Vite** | Build tool & dev server |
| **Tailwind CSS** | Styling |
| **qrcode.react** | QR generation |
| **html5-qrcode** | QR scanning |

---

## ⚡ Quick Start

### Prerequisites
Ensure you have installed:
- ✅ Flutter SDK (3.5.0 or higher)
- ✅ Python (3.9 or higher)
- ✅ Node.js (16.x or higher)
- ✅ PostgreSQL (14 or higher)
- ✅ Firebase Account
- ✅ Google Maps API Key

---

## 📦 Installation & Setup

### 1. Mobile App (Flutter)

#### Step-by-Step Setup

```bash
# Navigate to mobile app directory
cd mobile-app

# Install Flutter dependencies
flutter pub get

# Run code generation (if using freezed, json_serializable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app (choose your device)
flutter run

# Or run on specific platform
flutter run -d chrome      # Web
flutter run -d android     # Android emulator
flutter run -d ios         # iOS simulator
```

#### Firebase Configuration

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android app:
   - Download `google-services.json`
   - Place in: `mobile-app/android/app/google-services.json`
3. Add iOS app:
   - Download `GoogleService-Info.plist`
   - Place in: `mobile-app/ios/Runner/GoogleService-Info.plist`

#### Google Maps Setup

Edit `mobile-app/android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data 
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

#### Running Commands Summary

```bash
# From repository root
cd mobile-app
flutter pub get
flutter run
```

---

### 2. Backend Server (FastAPI)

#### Step-by-Step Setup

```bash
# Navigate to backend directory
cd backend-server/backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env

# Edit .env with your credentials:
# - DATABASE_URL=postgresql://user:password@localhost:5432/mediflow
# - FIREBASE_CREDENTIALS=path/to/firebase-credentials.json
# - JWT_SECRET_KEY=your-secret-key-here
# - EMAIL credentials for SMTP

# Initialize database tables
python -m app.database

# Run the backend server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Access API documentation
# Open browser: http://localhost:8000/docs
```

#### Environment Variables (.env)

```env
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/mediflow_db

# Firebase
FIREBASE_CREDENTIALS=firebase-credentials.json
FIREBASE_PROJECT_ID=your-project-id

# Security
JWT_SECRET_KEY=your-super-secret-key-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# SMS (Twilio or similar)
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

#### Running Commands Summary

```bash
# From repository root
cd backend-server/backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
cp .env.example .env
# Edit .env file
uvicorn app.main:app --reload
```

---

### 3. Web App (QR Registration)

#### Step-by-Step Setup

```bash
# Navigate to web app directory
cd mobile-app/web-app

# Install Node dependencies
npm install

# Create .env file
echo "VITE_API_URL=http://localhost:8000/api" > .env

# Run development server
npm run dev

# Access the web app
# Open browser: http://localhost:5173
```

#### Build for Production

```bash
# Build optimized production bundle
npm run build

# Preview production build
npm run preview
```

#### Running Commands Summary

```bash
# From repository root
cd mobile-app/web-app
npm install
npm run dev
```

---

## 🚀 Running the Application

### Complete Startup Sequence

#### Terminal 1 - Backend Server
```bash
cd backend-server/backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Terminal 2 - Mobile App
```bash
cd mobile-app
flutter pub get
flutter run
```

#### Terminal 3 - Web App (Optional)
```bash
cd mobile-app/web-app
npm run dev
```

### Verification

1. **Backend**: Visit http://localhost:8000/docs - You should see Swagger UI
2. **Mobile App**: Should launch on your device/emulator
3. **Web App**: Visit http://localhost:5173 - QR registration portal

---

## 👥 User Roles

### Administrator
- Full system access
- Manage hospitals and clinics
- User management and onboarding
- Analytics and reporting

### Doctor / Medical Representative
- Dual-queue dashboard
- Session controls (start/stop/pause)
- Patient appointment management
- Resource scheduling

### Patient
- Book appointments
- QR check-in at hospital
- Real-time queue updates
- Appointment history

### Consultant / Resource Provider
- Schedule equipment visits
- Coordinate with doctors
- Manage availability calendar

---

## 📖 API Documentation

Once the backend is running, access interactive API docs:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

```
Authentication:
POST   /api/auth/register          - Register new user
POST   /api/auth/login             - User login
POST   /api/auth/forgot-password   - Request password reset
POST   /api/auth/reset-password    - Reset password

Appointments:
GET    /api/appointments           - List appointments
POST   /api/appointments           - Create appointment
PUT    /api/appointments/{id}      - Update appointment
DELETE /api/appointments/{id}      - Cancel appointment

Queue Management:
GET    /api/queue/doctor/{id}      - Get doctor's queue
POST   /api/queue/add              - Add to queue
PUT    /api/queue/update-position  - Update position
POST   /api/queue/start-session    - Start session

Clinics/Hospitals:
GET    /api/clinics                - List clinics
POST   /api/clinics                - Create clinic
GET    /api/clinics/{id}/qr        - Get clinic QR code
```

---

## 🚢 Deployment

### Docker Deployment

#### Backend with Docker

```bash
cd backend-server/backend

# Build Docker image
docker build -t mediflow-backend .

# Run with Docker Compose
docker-compose up -d

# Backend runs at: http://localhost:8000
```

### AWS Elastic Beanstalk

```bash
cd backend-server/backend

# Initialize EB CLI
eb init

# Create environment
eb create production

# Deploy
eb deploy
```

### Render Deployment

1. Connect GitHub repository to Render
2. Auto-deploys on push to `main` branch
3. Configuration in `render.yaml`

### Flutter App Distribution

```bash
cd mobile-app

# Build APK
flutter build apk --release

# Build for iOS
flutter build ios --release

# Distribute via TestFlight or Google Play
```

---

## 📊 Project Structure Details

### Mobile App Directory

```
mobile-app/lib/
├── constants/           # App-wide constants
│   └── app_constants.dart
├── models/              # Data models
│   ├── user.dart
│   ├── appointment.dart
│   ├── clinic.dart
│   └── resource.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   ├── queue_provider.dart
│   └── notification_provider.dart
├── screens/             # UI screens
│   ├── admin/
│   ├── doctor/
│   ├── patient/
│   └── auth/
├── services/            # Business logic
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── qr_service.dart
│   └── notification_service.dart
├── widgets/             # Reusable components
│   ├── admin/
│   └── doctor/
├── theme/               # App theming
│   └── app_theme.dart
└── main.dart            # Entry point
```

### Backend Directory

```
backend-server/backend/app/
├── models/              # SQLAlchemy ORM models
│   ├── user.py
│   ├── appointment.py
│   ├── clinic.py
│   ├── doctor.py
│   └── queue.py
├── routers/             # API route handlers
│   ├── auth.py
│   ├── appointments.py
│   ├── clinics.py
│   ├── doctors.py
│   ├── queue.py
│   └── ads.py
├── schemas/             # Pydantic models
│   ├── user.py
│   ├── appointment.py
│   └── clinic.py
├── services/            # External services
│   ├── email_service.py
│   └── sms_service.py
├── utils/               # Helper functions
│   ├── security.py
│   └── firebase.py
├── config.py            # Configuration
├── database.py          # Database setup
└── main.py              # FastAPI application
```

---

## 🔒 Security Features

- ✅ JWT Token Authentication
- ✅ Password Hashing (bcrypt)
- ✅ CORS Protection
- ✅ Rate Limiting
- ✅ Input Validation (Pydantic)
- ✅ SQL Injection Prevention
- ✅ Role-Based Access Control
- ✅ Encrypted Data Transmission (TLS/SSL)

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Make your changes
4. Run tests:
   ```bash
   # Backend tests
   cd backend-server/backend
   pytest
   
   # Mobile app tests
   cd mobile-app
   flutter test
   ```
5. Commit your changes:
   ```bash
   git commit -m 'Add AmazingFeature'
   ```
6. Push to the branch:
   ```bash
   git push origin feature/AmazingFeature
   ```
7. Open a Pull Request

---

## 📞 Support

For support and questions:
- **Email**: support@mediflowpro.com
- **Issues**: Create an issue on GitHub
- **Documentation**: Check `GITHUB_README.md` for extended docs

---

## 📄 License

This project is **proprietary and confidential**. All rights reserved.

Unauthorized copying, distribution, or use of this software is strictly prohibited.

---

<div align="center">

**MediFlow Pro - Transforming Healthcare Through Smart Technology**

Made with ❤️ by the MediFlow Team

</div>
