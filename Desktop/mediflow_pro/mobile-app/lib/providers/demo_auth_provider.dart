import 'package:flutter/material.dart';
import '../models/user.dart';

class DemoAuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Demo Auth Methods
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Demo credentials
    final validCredentials = [
      {'email': 'admin@hospital.com', 'password': 'admin123', 'role': UserRole.admin},
      {'email': 'doctor@hospital.com', 'password': 'doctor123', 'role': UserRole.doctor},
      {'email': 'patient@gmail.com', 'password': 'patient123', 'role': UserRole.patient},
      {'email': 'consultant@medical.com', 'password': 'consultant123', 'role': UserRole.consultant},
    ];

    final credential = validCredentials.firstWhere(
      (cred) => cred['email'] == email && cred['password'] == password,
      orElse: () => {'email': '', 'password': '', 'role': UserRole.patient}, // Default fallback
    );

    if (credential['email'] != '') {
      _currentUser = User(
        id: 'demo_${(credential['role'] as UserRole).toString().toLowerCase()}_user',
        email: credential['email'].toString(),
        name: credential['email'].toString().split('@')[0].capitalize(),
        phone: '+1234567890', 
        role: credential['role'] as UserRole,
        hospitalId: 'demo_hospital',
        department: (credential['role'] as UserRole) == UserRole.doctor ? 'Cardiology' : 'General',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      return true;
    } else {
      _setError('Invalid credentials. Try demo accounts:\nadmin@hospital.com / admin123\nor\ndoctor@hospital.com / doctor123\nor\npatient@gmail.com / patient123');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? hospitalId,
    String? department,
  }) async {
    _setLoading(true);
    _clearError();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create demo user
    _currentUser = User(
      id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      phone: '+1234567890', // Added required phone field
      role: role,
      hospitalId: hospitalId,
      department: department,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  // Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}