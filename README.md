# MediFlow Pro - Complete Healthcare Management System

## 🏥 Overview
MediFlow Pro is a comprehensive healthcare management platform that combines mobile applications (Flutter), backend APIs (FastAPI), and web-based QR registration to eliminate hospital waiting room congestion and streamline medical facility operations. The system features real-time location tracking, dual-panel management, and smart queuing to ensure patients and medical staff arrive only when needed.

## ✨ Key Features

### 🏥 **Dual-Panel Management System**
- **Admin Panel**: Hospital management, staff onboarding, facility oversight
- **Doctor Panel**: Dual-queue dashboard for patients and resources
- **Patient/Consultant Panel**: QR check-in, appointment management

### 🎯 **Web Application - QR Registration System**
- **Vite + React**: Modern web-based QR code registration
- **Patient Self-Registration**: Generate personal QR codes for hospital check-ins
- **Hospital QR Display**: Facilities can display QR codes for easy patient scanning
- **Responsive Design**: Tailwind CSS for mobile-first responsive UI
- **Real-time Processing**: Instant QR code generation and validation
- Real-time location tracking with Google Maps integration
- Distance-based notification system
- QR code check-in functionality
- Smart queuing with predictive alerting

### 📍 **Smart Proximity & Location Engine**
- **Queue Management**: Separate queues for patients and resources
- **Session Control**: One-touch "Start Session" for doctors
- **Resource Scheduling**: Equipment and consultant coordination
- **Real-time Notifications**: Push notifications via Firebase
- **Location Services**: Geolocation for proximity-based alerts

### 📱 **Mobile App Features**

## 🏗️ Technical Architecture

### Mobile App (Flutter)
### Backend API (FastAPI + Python)
- **Framework**: FastAPI with async support
- **Database**: PostgreSQL / Firebase Firestore
- **Authentication**: JWT tokens + Firebase Auth
- **API Documentation**: Auto-generated OpenAPI/Swagger docs
- **Real-time**: WebSocket support for live updates

### Web App (React + Vite)
### Web App (React + Vite)
- **Framework**: React 18 with Vite
- **Styling**: Tailwind CSS
- **Build Tool**: Vite for fast development and production builds
- **QR Libraries**: qrcode.react for generation, html5-qrcode for scanning
- **State Management**: React Context API

### Mobile App State Management
### Mobile App State Management
- **Pattern**: Provider pattern with ChangeNotifier
- **Authentication**: Firebase Authentication integration
- **Authentication**: Firebase Authentication integration
- **Maps Integration**: Google Maps Flutter package
- **QR Scanning**: mobile_scanner & qr_flutter packages

### Backend Services (FastAPI)
### Backend Services (FastAPI)
- **Routers**: Modular API endpoints (auth, appointments, clinics, doctors, queue, etc.)
- **Models**: SQLAlchemy ORM models for database operations
- **Schemas**: Pydantic models for request/response validation
- **Services**: Email and SMS notification services
- **Security**: JWT token authentication and password hashing

### Cloud & Deployment

### Backend
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Messaging**: Firebase Cloud Messaging
- **Storage**: Firebase Storage
- **Location**: Geolocator package

### Cloud & Deployment
- **Containerization**: Docker support for all components
- **Orchestration**: Docker Compose for local development
- **Cloud Ready**: AWS Elastic Beanstalk, Render deployment configs
- **CI/CD**: Deployment scripts included

### Key Mobile Services
### Key Mobile Services
1. **FirebaseService** - Authentication and real-time database operations
2. **LocationService** - Geolocation tracking and distance calculations
3. **NotificationService** - Push notifications via FCM
4. **QueueProvider** - Queue management and state handling
5. **QRService** - QR code generation and scanning
6. **API Service** - REST API communication with backend
7. **LocalStorageService** - Offline data persistence

### Key Backend Routers
2. **LocationService** - Geolocation and distance calculations
3. **NotificationService** - Push and local notifications
4. **QueueProvider** - Queue management logic

## Project Structure

```
lib/
├── constants/
│   └── app_constants.dart
├── models/
│   ├── user.dart
│   ├── hospital.dart
│   ├── appointment.dart
│   └── resource.dart
├── providers/
│   ├── auth_provider.dart
│   └── queue_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── admin/
│   │   └── admin_dashboard_screen.dart
│   ├── doctor/
│   │   ├── doctor_dashboard_screen.dart
│   │   ├── doctor_dashboard_content.dart
│   │   ├── doctor_appointments_screen.dart
│   │   ├── doctor_resources_screen.dart
│   │   └── doctor_profile_screen.dart
│   ├── patient/
│   │   └── patient_dashboard_screen.dart
│   └── splash_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── theme/
│   └── app_theme.dart
├── widgets/
│   ├── admin/
│   │   ├── statistics_card.dart
│   │   ├── hospital_list.dart
│   │   └── user_management.dart
│   └── doctor/
│       ├── queue_card.dart
│       └── session_controls.dart
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (3.5.0 or higher)
- Android Studio / Xcode
- Firebase account

### Setup Instructions

1. **Clone the repository**
```bash
git clone <repository-url>
cd mediflow_pro
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Configuration**
   - Create a Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in respective directories:
     - `android/app/` for Android
     - `ios/Runner/` for iOS

4. **Configure Google Maps**
   - Get Google Maps API key
   - Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_API_KEY"/>
   ```

5. **Run the application**
```bash
flutter run
```

## User Roles

### Administrator
- Manage hospitals and facilities
- Onboard staff members
- Monitor system metrics
- Approve resource requests

### Doctor
- View dual-queue dashboard
- Manage patient appointments
- Schedule resource consultations
- Control session flow
- Approve/reject resources

### Patient
- Book appointments
- QR code check-in
- Receive proximity notifications
- View appointment history

### Consultant
- Schedule resource appointments
- QR code check-in for equipment
- Receive workflow notifications

## Core Workflows

### Patient Check-in Process
1. Patient arrives at hospital
2. Scans hospital QR code or shows personal QR
3. System captures location and check-in time
4. Patient waits in designated area
5. Receives notification when called

### Doctor Session Management
1. Doctor logs in and views queues
2. Presses "Start Session"
3. System notifies top 5 patients/resources
4. Doctor manages appointments in real-time
5. System updates queue positions automatically

### Resource Coordination
1. Consultants schedule equipment visits
2. Doctors review and approve requests
3. System integrates resource meetings with patient schedule
4. Notifications sent to all parties

## Security & Privacy

- **Authentication**: Firebase Auth with role-based access
- **Data Encryption**: All sensitive data encrypted in transit
- **Privacy Controls**: Users control location sharing
- **Compliance**: Designed for HIPAA compliance considerations

## Future Enhancements

- [ ] Telemedicine integration
- [ ] AI-powered appointment scheduling
- [ ] Integration with hospital EMR systems
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Wearable device integration

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is proprietary and confidential. All rights reserved.

## Support

For support, email support@mediflowpro.com or join our Slack channel.

---
*MediFlow Pro - Transforming healthcare through smart technology*
