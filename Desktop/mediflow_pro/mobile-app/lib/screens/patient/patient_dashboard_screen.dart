import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as ModelUser;

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Patient Dashboard!\n\nPlease use the external webapp for QR code and location features.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.name.split(' ').first ?? 'Patient'}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your health journey starts here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Scan QR Code',
                  subtitle: 'Check-in for appointment',
                  icon: Icons.qr_code_scanner,
                  color: Color(0xFF2E7D32),
                  onTap: null, // Will be handled by main screen
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  title: 'My Appointments',
                  subtitle: 'View upcoming visits',
                  icon: Icons.calendar_today,
                  color: Color(0xFF1565C0),
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Medical Records',
                  subtitle: 'Access your history',
                  icon: Icons.description,
                  color: Color(0xFFFFA000),
                  onTap: null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  title: 'Emergency',
                  subtitle: 'Quick assistance',
                  icon: Icons.emergency,
                  color: Color(0xFFD32F2F),
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Upcoming Appointment
          const Text(
            'Next Appointment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.medical_services, color: Colors.white),
              ),
              title: Text('Dr. Sarah Johnson'),
              subtitle: Text('Cardiology • Tomorrow, 10:30 AM'),
              trailing: Chip(
                label: Text('Confirmed'),
                backgroundColor: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsScreen extends StatelessWidget {
  const _AppointmentsScreen();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Appointments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          // Filter Tabs
          _AppointmentFilterTabs(),
          SizedBox(height: 24),
          
          // Appointment List
          _PatientAppointmentList(),
        ],
      ),
    );
  }
}

class _CheckInScreen extends StatelessWidget {
  const _CheckInScreen();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check-in',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan QR code or show your check-in code',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // My QR Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Your Check-in Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // QR Code feature removed - use web app instead
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Use Web App',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PATIENT_12345',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Show this code at reception or scan the hospital QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Scan Button
          ElevatedButton.icon(
            onPressed: () {
              // This would trigger the scanner view
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Clinic QR Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.check_circle, color: Colors.white),
              ),
              title: Text('Appointment Confirmed'),
              subtitle: Text('Your appointment with Dr. Johnson is confirmed for tomorrow at 10:30 AM'),
              trailing: Text('2 hours ago'),
            ),
          ),
          
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.info, color: Colors.white),
              ),
              title: Text('Please Proceed'),
              subtitle: Text('Dr. Johnson is ready to see you now. Please proceed to room 204.'),
              trailing: Text('5 minutes ago'),
            ),
          ),
          
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.warning, color: Colors.white),
              ),
              title: Text('Appointment Reminder'),
              subtitle: Text('Your appointment is in 30 minutes. Please arrive 15 minutes early.'),
              trailing: Text('1 hour ago'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentFilterTabs extends StatelessWidget {
  const _AppointmentFilterTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              title: 'Upcoming',
              isSelected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _FilterTab(
              title: 'History',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PatientAppointmentList extends StatelessWidget {
  const _PatientAppointmentList();

  @override
  Widget build(BuildContext context) {
    final appointments = [
      {
        'doctor': 'Dr. Sarah Johnson',
        'specialty': 'Cardiology',
        'date': 'Tomorrow',
        'time': '10:30 AM',
        'status': 'Confirmed',
      },
      {
        'doctor': 'Dr. Michael Chen',
        'specialty': 'Orthopedics',
        'date': '2024-03-20',
        'time': '2:00 PM',
        'status': 'Scheduled',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        Color statusColor = appointment['status'] == 'Confirmed' 
            ? Colors.green 
            : Colors.blue;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.medical_services, color: Colors.white),
            ),
            title: Text(appointment['doctor'] as String),
            subtitle: Text('${appointment['specialty']} • ${appointment['date']} at ${appointment['time']}'),
            trailing: Chip(
              label: Text(appointment['status'] as String),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: statusColor),
            ),
            onTap: () {
              // TODO: Show appointment details
            },
          ),
        );
      },
    );
  }
}

class _QRScannerView extends StatelessWidget {
  const _QRScannerView();

  @override
  Widget build(BuildContext context) {
    // QR Scanner feature removed - use web app instead
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'QR Scanner',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please use the web app for QR code scanning and location features.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}