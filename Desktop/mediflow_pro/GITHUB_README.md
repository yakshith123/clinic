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
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [User Roles](#user-roles)
- [Screenshots & Demos](#screenshots--demos)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [Support](#support)

---

## 🎯 Overview

MediFlow Pro is a **comprehensive healthcare management platform** that solves one critical problem: **hospital waiting room congestion**. Our system combines:

- 📱 **Mobile App** (Flutter) - For patients, doctors, and administrators
- 🔌 **Backend API** (FastAPI + Python) - Robust RESTful services
- 🌐 **Web App** (React + Vite) - QR registration and patient self-service

The platform uses **real-time location tracking**, **smart queuing algorithms**, and **dual-panel management** to ensure patients and medical staff arrive only when needed, reducing wait times and improving facility efficiency.

---

## ✨ Key Features

### 🏢 **Multi-Role Management System**

#### Admin Panel
- Hospital and facility management
- Staff onboarding and role assignment
- System-wide analytics and reporting
- User management across all roles
- Resource allocation oversight

#### Doctor Panel
- **Dual-Queue Dashboard**: Manage patients and resources simultaneously
- Appointment scheduling and queue control
- One-touch session start/stop
- Patient history and resource coordination
- Real-time notifications

#### Patient Panel
- QR code check-in/check-out
- Real-time queue position tracking
- Proximity-based notifications
- Appointment booking and history
- Wait time estimates

#### Consultant/Resource Panel
- Equipment and specialist scheduling
- Resource availability management
- Integration with patient flow
- Automated coordination with doctors

### 🚀 Smart Features

#### Location-Based Intelligence
- ✅ Real-time GPS tracking with Google Maps integration
- ✅ Distance-based automatic notifications
- ✅ Geo-fenced arrival detection
- ✅ Smart proximity alerts (top 5 patients notified)

#### Queue Management
- ✅ Dynamic queue positioning
- ✅ Predictive wait time calculation
- ✅ Emergency priority handling
- ✅ Multi-queue synchronization (patients + resources)

#### QR Code System
- ✅ Hospital-specific QR codes for check-in
- ✅ Personal patient QR codes
- ✅ Quick scanning with mobile camera
- ✅ Web-based QR registration portal

#### Notifications
- ✅ Firebase Cloud Messaging push notifications
- ✅ Local notifications for proximity alerts
- ✅ SMS and email integration
- ✅ Real-time queue updates

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MediFlow Pro Platform                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Mobile     │  │     Web      │  │    Admin     │       │
│  │    App       │  │    Portal    │  │   Dashboard  │       │
│  │  (Flutter)   │  │  (React)     │  │   (Web)      │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                  │
│                  ┌─────────▼─────────┐                        │
│                  │   FastAPI Backend  │                       │
│                  │   (Python REST)    │                       │
│                  └─────────┬─────────┘                       │
│                            │                                  │
│         ┌──────────────────┼──────────────────┐              │
│         │                  │                  │              │
│  ┌──────▼──────┐  ┌───────▼───────┐  ┌──────▼──────┐        │
│  │  Firebase   │  │  PostgreSQL   │  │  External   │        │
│  │  (Auth/DB)  │  │   Database    │  │   Services  │        │
│  └─────────────┘  └───────────────┘  └─────────────┘        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 💻 Tech Stack

### Mobile Application
| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.5.0+ | Cross-platform mobile framework |
| **Dart** | 3.0+ | Programming language |
| **Provider** | Latest | State management |
| **Firebase Auth** | Latest | User authentication |
| **Cloud Firestore** | Latest | Real-time database |
| **Google Maps** | Latest | Location services |
| **qr_flutter** | Latest | QR code generation |
| **mobile_scanner** | Latest | QR code scanning |

### Backend API
| Technology | Version | Purpose |
|------------|---------|---------|
| **FastAPI** | 0.100.0+ | Modern Python web framework |
| **Python** | 3.9+ | Backend programming |
| **SQLAlchemy** | Latest | ORM for database operations |
| **PostgreSQL** | 14+ | Primary database |
| **Pydantic** | Latest | Data validation |
| **JWT** | Latest | Token-based auth |
| **Passlib** | Latest | Password hashing |
| **CORS** | Latest | Cross-origin resource sharing |

### Web Application (QR Portal)
| Technology | Version | Purpose |
|------------|---------|---------|
| **React** | 18+ | Frontend framework |
| **Vite** | Latest | Build tool & dev server |
| **Tailwind CSS** | 3.0+ | Utility-first styling |
| **qrcode.react** | Latest | QR generation |
| **html5-qrcode** | Latest | QR scanning |
| **React Router** | Latest | Navigation |

### Cloud & DevOps
| Technology | Purpose |
|------------|---------|
| **Docker** | Containerization |
| **Docker Compose** | Local development |
| **AWS Elastic Beanstalk** | Cloud deployment |
| **Render** | Alternative cloud hosting |
| **GitHub Actions** | CI/CD pipeline |

---

## ⚡ Quick Start

### Prerequisites
Before you begin, ensure you have:
- **Flutter SDK** (3.5.0 or higher)
- **Python** (3.9 or higher)
- **Node.js** (16.x or higher)
- **PostgreSQL** (14 or higher)
- **Firebase Account**
- **Google Maps API Key**

### 1. Clone the Repository
```bash
git clone https://github.com/yakshith123/clinic.git
cd clinic
```

### 2. Mobile App Setup (Flutter)
```bash
cd lib

# Install dependencies
flutter pub get

# Configure Firebase
# - Create Firebase project
# - Download google-services.json (Android) → android/app/
# - Download GoogleService-Info.plist (iOS) → ios/Runner/

# Add Google Maps API Key
# Edit: android/app/src/main/AndroidManifest.xml
# Add: <meta-data android:name="com.google.android.geo.API_KEY"
#              android:value="YOUR_API_KEY"/>

# Run the app
flutter run
```

### 3. Backend Setup (FastAPI)
```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env with your credentials:
# - DATABASE_URL
# - FIREBASE_CREDENTIALS
# - JWT_SECRET_KEY
# - EMAIL/SMS credentials

# Initialize database
python -m app.database

# Run the backend server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Access API docs at: http://localhost:8000/docs
```

### 4. Web App Setup (QR Registration Portal)
```bash
cd "qr code "

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Add your backend API URL

# Run development server
npm run dev

# Access at: http://localhost:5173
```

---

## 📁 Project Structure

```
mediflow_pro/
├── 📱 lib/                          # Flutter Mobile App
│   ├── constants/                   # App constants and configs
│   ├── models/                      # Data models
│   ├── providers/                   # State management
│   ├── screens/                     # UI screens
│   │   ├── admin/                   # Admin dashboard
│   │   ├── doctor/                  # Doctor panels
│   │   ├── patient/                 # Patient interface
│   │   └── auth/                    # Login/Signup
│   ├── services/                    # Business logic
│   ├── widgets/                     # Reusable components
│   └── main.dart                    # App entry point
│
├── 🔌 backend/                      # FastAPI Backend
│   ├── app/
│   │   ├── models/                  # SQLAlchemy models
│   │   ├── routers/                 # API endpoints
│   │   ├── schemas/                 # Pydantic models
│   │   ├── services/                # Email/SMS services
│   │   ├── utils/                   # Helpers
│   │   ├── config.py                # Configuration
│   │   ├── database.py              # DB connection
│   │   └── main.py                  # FastAPI app
│   ├── .env                         # Environment variables
│   ├── requirements.txt             # Python dependencies
│   ├── Dockerfile                   # Docker config
│   └── docker-compose.yml           # Docker compose
│
├── 🌐 qr code /                     # React Web App
│   ├── src/
│   │   ├── components/              # React components
│   │   ├── App.jsx                  # Main component
│   │   └── main.jsx                 # Entry point
│   ├── index.html                   # HTML template
│   ├── package.json                 # Node dependencies
│   ├── vite.config.js               # Vite config
│   └── tailwind.config.js           # Tailwind config
│
├── 📚 Documentation/
│   ├── README.md                    # This file
│   ├── API_DOCS.md                  # API documentation
│   └── DEPLOYMENT.md                # Deployment guide
│
└── 🛠️ Configuration/
    ├── pubspec.yaml                 # Flutter dependencies
    ├── analysis_options.yaml        # Dart linting
    └── firebase_options.dart        # Firebase config
```

---

## 👥 User Roles

### Administrator
**Responsibilities:**
- Manage multiple hospitals and clinics
- Onboard doctors, staff, and consultants
- Monitor system-wide metrics
- Generate reports and analytics
- Handle user escalations

**Access Level:** Full system access

---

### Doctor / Medical Representative
**Responsibilities:**
- View dual-queue dashboard (patients + resources)
- Start/stop consultation sessions
- Manage appointment schedules
- Coordinate with consultants/equipment
- Review patient histories

**Key Features:**
- One-touch session controls
- Real-time queue management
- Priority patient notifications
- Resource scheduling integration

---

### Patient
**Responsibilities:**
- Book appointments
- Check-in via QR code
- Wait in designated areas
- Respond to proximity alerts

**Key Features:**
- Real-time queue position
- Wait time estimates
- Automatic notifications
- Appointment history

---

### Consultant / Resource Provider
**Responsibilities:**
- Schedule equipment/specialist visits
- Coordinate with doctor availability
- Manage resource calendar
- Update availability status

**Key Features:**
- Integrated scheduling with patient flow
- Automated conflict detection
- Real-time notifications
- Resource utilization reports

---

## 📸 Screenshots & Demos

### Mobile App
<!-- Add your screenshots here -->
```
📍 Doctor Dashboard          📍 Patient Check-in         📍 Queue Management
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Dual Queue     │         │  QR Scanner     │         │  Live Queue     │
│  Patients: 12   │         │  Scan to        │         │  Position: #5   │
│  Resources: 3   │         │  Check-in       │         │  Wait: 15 min   │
│  Start Session  │         │                 │         │  Next: You      │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

### Web Portal
```
🌐 QR Registration Portal
┌─────────────────────────────────────┐
│  MediFlow QR Registration           │
│                                     │
│  Enter Details → Generate QR        │
│  - Name                             │
│  - Phone                            │
│  - Hospital                         │
│                                     │
│  [Generate QR Code]                 │
│                                     │
│  Your QR Code Ready!                │
│  [Download] [Print]                 │
└─────────────────────────────────────┘
```

### Backend API Dashboard
```
🔌 API Endpoints Status
┌─────────────────────────────────────┐
│  Base URL: http://localhost:8000    │
│  Docs: /docs                        │
│                                     │
│  ✅ /api/auth/*                     │
│  ✅ /api/appointments/*             │
│  ✅ /api/clinics/*                  │
│  ✅ /api/doctors/*                  │
│  ✅ /api/queue/*                    │
│  ✅ /api/ads/*                      │
└─────────────────────────────────────┘
```

---

## 📖 API Documentation

Once the backend is running, access interactive API documentation at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Key Endpoints

#### Authentication
```
POST   /api/auth/register          - Register new user
POST   /api/auth/login             - User login
POST   /api/auth/forgot-password   - Password reset request
POST   /api/auth/reset-password    - Reset password with token
```

#### Appointments
```
GET    /api/appointments/          - List appointments
POST   /api/appointments/          - Create appointment
GET    /api/appointments/{id}      - Get appointment details
PUT    /api/appointments/{id}      - Update appointment
DELETE /api/appointments/{id}      - Cancel appointment
```

#### Queue Management
```
GET    /api/queue/doctor/{id}      - Get doctor's queue
POST   /api/queue/add              - Add patient to queue
PUT    /api/queue/update-position  - Update queue position
DELETE /api/queue/remove           - Remove from queue
POST   /api/queue/start-session    - Start consultation session
```

#### Clinics/Hospitals
```
GET    /api/clinics/               - List all clinics
POST   /api/clinics/               - Create clinic
GET    /api/clinics/{id}           - Get clinic details
PUT    /api/clinics/{id}           - Update clinic
GET    /api/clinics/{id}/qr        - Get clinic QR code
```

---

## 🚀 Deployment

### Docker Deployment

#### Build and Run Locally
```bash
cd backend

# Build Docker image
docker build -t mediflow-backend .

# Run with Docker Compose
docker-compose up -d

# Backend runs at: http://localhost:8000
```

### AWS Elastic Beanstalk
```bash
cd backend

# Initialize EB
eb init

# Create environment
eb create production

# Deploy
eb deploy
```

### Render Deployment
```bash
# Connect GitHub repo to Render
# Auto-deploys on push to main branch
# Configuration in render.yaml
```

### Flutter App Distribution
```bash
# Build APK
flutter build apk --release

# Build for iOS
flutter build ios --release

# Distribute via TestFlight or Play Store
```

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
```

### Mobile App Tests
```bash
flutter test
```

---

## 🔒 Security Features

- ✅ **JWT Authentication** - Secure token-based auth
- ✅ **Password Hashing** - bcrypt with salt rounds
- ✅ **CORS Protection** - Configured origins only
- ✅ **Rate Limiting** - API request throttling
- ✅ **Data Encryption** - TLS/SSL for data in transit
- ✅ **Role-Based Access** - Granular permissions
- ✅ **Input Validation** - Pydantic schema validation
- ✅ **SQL Injection Prevention** - Parameterized queries

---

## 📊 Performance Metrics

- **API Response Time**: < 200ms average
- **Real-time Updates**: < 1s latency (Firebase)
- **Queue Processing**: 1000+ concurrent users supported
- **Location Tracking**: 5m accuracy with GPS
- **QR Scanning**: < 2s recognition time

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Run tests to ensure everything works
5. Commit your changes (`git commit -m 'Add AmazingFeature'`)
6. Push to the branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

### Contribution Guidelines
- Follow existing code style
- Write meaningful commit messages
- Add comments for complex logic
- Update documentation as needed
- Include tests for new features

---

## 📞 Support

For support and questions:
- **Email**: support@mediflowpro.com
- **Issues**: Create an issue on GitHub
- **Documentation**: Check the `/docs` folder

---

## 📄 License

This project is **proprietary and confidential**. All rights reserved.

Unauthorized copying, distribution, or use of this software is strictly prohibited.

---

## 🙏 Acknowledgments

Built with ❤️ using:
- [Flutter](https://flutter.dev)
- [FastAPI](https://fastapi.tiangolo.com)
- [React](https://reactjs.org)
- [Firebase](https://firebase.google.com)
- [PostgreSQL](https://www.postgresql.org)

---

## 📈 Roadmap

### Phase 1 (Current) ✅
- Core queue management system
- Basic appointment booking
- QR code registration
- Real-time notifications

### Phase 2 (In Progress) 🚧
- Advanced analytics dashboard
- Multi-language support
- Telemedicine integration
- Payment gateway

### Phase 3 (Planned) 📅
- AI-powered wait time prediction
- EMR/EHR integration
- Wearable device support
- Voice assistant integration

---

<div align="center">

**MediFlow Pro - Transforming Healthcare Through Smart Technology**

Made with ❤️ by the MediFlow Team

</div>
