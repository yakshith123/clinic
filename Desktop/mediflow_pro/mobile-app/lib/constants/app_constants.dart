class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  
  // PostgreSQL Configuration
  static const String postgresHost = String.fromEnvironment('POSTGRES_HOST', defaultValue: 'localhost');
  static const int postgresPort = 5432; // Default PostgreSQL port
  static const String postgresDatabase = String.fromEnvironment('POSTGRES_DATABASE', defaultValue: 'mediflow_db');
  static const String postgresUsername = String.fromEnvironment('POSTGRES_USERNAME', defaultValue: 'postgres');
  static const String postgresPassword = String.fromEnvironment('POSTGRES_PASSWORD', defaultValue: 'password');

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.mediflow-pro.com');
  
  // App Configuration
  static const String appName = 'Clinikx';
  static const String version = '1.0.0';
  
  // Default Values
  static const String defaultClinicId = 'default_hospital';
  static const String defaultDepartment = 'General';
  
  // Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int requestTimeout = 60; // seconds
  
  // Cache Configuration
  static const int cacheDuration = 300; // seconds
  
  // Location Configuration
  static const double defaultLatitude = 37.7749; // San Francisco
  static const double defaultLongitude = -122.4194;
  static const double locationAccuracy = 100.0; // meters
  
  // Queue Configuration
  static const int maxQueueSize = 50;
  static const int defaultQueuePosition = 0;
  static const int appointmentNotificationDistance = 500; // meters
  
  // Demo Mode
  static const bool enableDemoMode = bool.fromEnvironment('ENABLE_DEMO_MODE', defaultValue: false);
  
  // QR Code Configuration
  static const String patientQrPrefix = 'MEDIFLOW_PATIENT_';
}