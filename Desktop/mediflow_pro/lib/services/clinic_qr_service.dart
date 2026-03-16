import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_registration.dart';

class ClinicQRService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'qr_registrations';

  static Future<void> initialize() async {
    // Firebase initializes automatically
    print('Firebase Firestore initialized for Clinic QR service');
  }

  static Future<List<QrRegistration>> getQrRegistrationsByClinic(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('hospitalId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => QrRegistration.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching QR registrations by clinic: $e');
      rethrow;
    }
  }

  static Future<QrRegistration> registerPatientWithQR({
    required String clinicId,
    required String clinicName,
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String symptoms,
    required String visitType,
  }) async {
    try {
      final registration = QrRegistration(
        id: _firestore.collection(_collectionName).doc().id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName',
        mobileNumber: mobileNumber,
        hospitalId: clinicId,
        hospitalName: clinicName,
        symptoms: symptoms,
        visitType: visitType,
        status: 'registered',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(registration.id)
          .set(registration.toMap());

      return registration;
    } catch (e) {
      print('Error registering patient with QR: $e');
      rethrow;
    }
  }

  static Future<void> updateRegistrationStatus(String registrationId, String status) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(registrationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating registration status: $e');
      rethrow;
    }
  }

  static Stream<List<QrRegistration>> streamQrRegistrationsByClinic(String clinicId) {
    return _firestore
        .collection(_collectionName)
        .where('hospitalId', isEqualTo: clinicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => QrRegistration.fromMap(doc.data())).toList());
  }
}