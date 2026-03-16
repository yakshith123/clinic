import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_registration.dart';

class FirebaseQrService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'qr_registrations';

  static Future<void> initialize() async {
    // Firebase initializes automatically
    print('Firebase Firestore initialized for QR service');
  }

  static Future<List<QrRegistration>> getQrRegistrations() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => QrRegistration.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching QR registrations: $e');
      rethrow;
    }
  }

  static Future<List<QrRegistration>> getQrRegistrationsByHospital(String hospitalId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('hospitalId', isEqualTo: hospitalId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => QrRegistration.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching QR registrations by hospital: $e');
      rethrow;
    }
  }

  static Future<List<QrRegistration>> getQrRegistrationsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => QrRegistration.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching QR registrations by status: $e');
      rethrow;
    }
  }

  static Stream<List<QrRegistration>> streamQrRegistrations() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => QrRegistration.fromMap(doc.data())).toList());
  }
}