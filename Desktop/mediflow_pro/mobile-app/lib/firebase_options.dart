import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyD9h9Y_1_QmUHpJHK-66dtvUG6l5eUIa98",
      authDomain: "patient-qr-registration.firebaseapp.com",
      projectId: "patient-qr-registration",
      storageBucket: "patient-qr-registration.firebasestorage.app",
      messagingSenderId: "343467579186",
      appId: "1:343467579186:web:c8af7c7113f094c897292b",
      measurementId: "G-0FWB6SCXSJ",
    );
  }
}