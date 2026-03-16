import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/demo_auth_provider.dart';
import 'providers/simple_queue_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: Firebase initialization is commented out for demo mode
  // await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoAuthProvider()),
        ChangeNotifierProvider(create: (_) => SimpleQueueProvider()),
      ],
      child: MaterialApp(
        title: 'MediFlow Pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Route based on user role
        switch (authProvider.currentUser?.role) {
          case UserRole.admin:
            return const AdminDashboardScreen();
          case UserRole.doctor:
            return const DoctorDashboardScreen();
          case UserRole.patient:
          case UserRole.consultant:
            return const PatientDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}