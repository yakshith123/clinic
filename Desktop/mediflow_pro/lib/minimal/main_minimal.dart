import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalMediFlowApp());
}

class MinimalMediFlowApp extends StatelessWidget {
  const MinimalMediFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediFlow Pro',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'MediFlow Pro',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Smart Healthcare Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'admin';

  final List<Map<String, String>> _demoCredentials = [
    {'email': 'admin@hospital.com', 'password': 'admin123', 'role': 'admin'},
    {'email': 'doctor@hospital.com', 'password': 'doctor123', 'role': 'doctor'},
    {'email': 'patient@gmail.com', 'password': 'patient123', 'role': 'patient'},
  ];

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Check credentials
    final user = _demoCredentials.firstWhere(
      (cred) => cred['email'] == email && cred['password'] == password && cred['role'] == _selectedRole,
      orElse: () => {'email': '', 'password': '', 'role': ''},
    );
    
    if (user['email']!.isNotEmpty) {
      // Login successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(role: _selectedRole),
        ),
      );
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid credentials. Try demo accounts.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediFlow Pro Login'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Role Selection
            const Text(
              'Select Role',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'admin', label: Text('Admin')),
                ButtonSegment(value: 'doctor', label: Text('Doctor')),
                ButtonSegment(value: 'patient', label: Text('Patient')),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedRole = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 30),
            
            // Demo Credentials Info
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    'Demo Credentials:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('Admin: admin@hospital.com / admin123'),
                  Text('Doctor: doctor@hospital.com / doctor123'),
                  Text('Patient: patient@gmail.com / patient123'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Email Field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            // Password Field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            
            // Login Button
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String role;
  
  const DashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    String title = '';
    List<Widget> cards = [];
    
    switch (role) {
      case 'admin':
        title = 'Admin Dashboard';
        cards = [
          _buildDashboardCard('Hospitals', '12', Icons.business, Colors.blue),
          _buildDashboardCard('Doctors', '156', Icons.medical_services, Colors.green),
          _buildDashboardCard('Patients', '2,847', Icons.people, Colors.orange),
          _buildDashboardCard('Appointments', '89', Icons.calendar_today, Colors.purple),
        ];
        break;
      case 'doctor':
        title = 'Doctor Dashboard';
        cards = [
          _buildDashboardCard('Patients Queue', '5', Icons.people, Colors.blue),
          _buildDashboardCard('Resources', '3', Icons.business, Colors.green),
          _buildDashboardCard('Today\'s Appointments', '12', Icons.calendar_today, Colors.orange),
          _buildDashboardCard('Session Status', 'Active', Icons.check_circle, Colors.purple),
        ];
        break;
      case 'patient':
        title = 'Patient Dashboard';
        cards = [
          _buildDashboardCard('My Appointments', '3', Icons.calendar_today, Colors.blue),
          _buildDashboardCard('Check-in', 'QR Code', Icons.qr_code, Colors.green),
          _buildDashboardCard('Notifications', '2', Icons.notifications, Colors.orange),
          _buildDashboardCard('Medical Records', '15', Icons.description, Colors.purple),
        ];
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: cards,
        ),
      ),
    );
  }
  
  Widget _buildDashboardCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}