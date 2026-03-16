import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/patient/qr_registration_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/notification_provider.dart';
import 'theme/app_theme.dart';
import 'models/user.dart' as ModelUser;
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
  }
  
  // Initialize services
  try {
    await AuthService.initialize();
    await NotificationService.initialize();
    print('Services initialized');
  } catch (e) {
    print('Service initialization error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            authProvider.initializeAuthListener();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final notificationProvider = NotificationProvider();
            notificationProvider.initialize();
            return notificationProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinikx',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/qr-registration': (context) => const QRRegistrationScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialLoadComplete = false;
  static const platform = MethodChannel('deep_link_channel');

  @override
  void initState() {
    super.initState();
    
    // Set a timeout to bypass initial loading if it takes too long
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    });
    
    // Handle initial URL if the app was launched from a deep link
    _handleInitialUrl();
  }

  Future<void> _handleInitialUrl() async {
    // Check if the app was launched with a URL
    final initialUrl = await _getInitialUrl();
    if (initialUrl != null) {
      _handleDeepLink(initialUrl);
    }
  }

  Future<String?> _getInitialUrl() async {
    try {
      // Use the method channel to get the initial deep link
      final String? initialLink = await platform.invokeMethod('getInitialLink');
      print('Initial deep link: $initialLink');
      return initialLink;
    } on PlatformException catch (e) {
      print("Failed to get initial link: '${e.message}'.");
      return null;
    }
  }

  void _handleDeepLink(String? link) {
    if (link == null) return;
    
    try {
      // Parse the URL
      final uri = Uri.parse(link);
      
      // Handle the specific URL format: mediflow://qr-scan?params
      if (uri.scheme == 'mediflow' && uri.host == 'qr-scan') {
        String? clinicId = uri.queryParameters['clinicId'];

        if (clinicId != null) {
          // Navigate to QR registration screen with the extracted parameters
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRRegistrationScreen(),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('Error parsing deep link: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set the navigation context for API error handling
    ApiService.setNavigationContext(context);
    
    try {
      return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // If 2.5 seconds have passed or auth is initialized, proceed
          if (_initialLoadComplete || authProvider.isInitialized) {
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }

            // Route based on user role - Admin dashboard removed, use web admin panel instead
            switch (authProvider.currentUser?.role) {
              case ModelUser.UserRole.doctor:
                return const DoctorDashboardScreen();
              case ModelUser.UserRole.patient:
              case ModelUser.UserRole.consultant:
                // If patient tries to access dashboard, redirect to QR registration
                return const QRRegistrationScreen();
              default:
                // Default to doctor dashboard for unknown roles or admin users
                // Admin users should use the web admin panel at http://localhost:3000
                return const DoctorDashboardScreen();
            }
          } else {
            // Show splash screen for max 2.5 seconds or until auth is initialized
            return const SplashScreen();
          }
        },
      );
    } catch (e) {
      // Fallback in case of provider error
      print('Provider error: $e');
      return const SplashScreen();
    }
  }
}