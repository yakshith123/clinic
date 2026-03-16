# MediFlow Pro - Smart Healthcare Queue & Resource Management System

## Overview
MediFlow Pro is an innovative mobile application built on Flutter designed to eliminate hospital waiting room congestion and streamline professional medical visits. By utilizing real-time location data and a dual-panel management system, the app ensures that both patients and medical consultants arrive at the facility only when the doctor is ready to receive them.

## Key Features

### 🏥 **Dual-Panel Management System**
- **Admin Panel**: Hospital management, staff onboarding, facility oversight
- **Doctor Panel**: Dual-queue dashboard for patients and resources
- **Patient/Consultant Panel**: QR check-in, appointment management

### 📍 **Smart Proximity Engine**
- Real-time location tracking with Google Maps integration
- Distance-based notification system
- QR code check-in functionality
- Smart queuing with predictive alerting

### 📱 **Core Functionality**
- **Queue Management**: Separate queues for patients and resources
- **Session Control**: One-touch "Start Session" for doctors
- **Resource Scheduling**: Equipment and consultant coordination
- **Real-time Notifications**: Push notifications via Firebase
- **Location Services**: Geolocation for proximity-based alerts

## Technical Architecture

### Frontend
- **Framework**: Flutter (Cross-platform iOS/Android)
- **State Management**: Provider pattern
- **UI Components**: Material Design 3
- **Maps**: Google Maps Flutter
- **QR Code**: qr_flutter & mobile_scanner

### Backend
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Messaging**: Firebase Cloud Messaging
- **Storage**: Firebase Storage
- **Location**: Geolocator package

### Key Services
1. **FirebaseService** - Authentication and data management
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