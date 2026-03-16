import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  String? _fcmToken;

  bool get notificationsEnabled => _notificationsEnabled;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await NotificationService.initialize();
      // Removed Firebase messaging related code since using external webapp
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  Future<void> enableNotifications() async {
    _notificationsEnabled = true;
    notifyListeners();
  }

  Future<void> disableNotifications() async {
    _notificationsEnabled = false;
    notifyListeners();
  }

  Future<void> setFcmToken(String token) async {
    _fcmToken = token;
    notifyListeners();
  }

  Future<void> setupUserNotifications(String userId, String role) async {
    // This will be handled by the external webapp
    print('User notifications setup requested for user: $userId with role: $role');
  }

  Future<void> cleanupUserNotifications(String userId) async {
    // This will be handled by the external webapp
    print('User notifications cleanup requested for user: $userId');
  }
}