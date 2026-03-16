import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

void main() {
  runApp(const DoctorDashboardDemo());
}

class DoctorDashboardDemo extends StatelessWidget {
  const DoctorDashboardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Dashboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DoctorDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String _currentHospitalId = 'clinic_1';
  
  final List<Map<String, dynamic>> _availableHospitals = [
    {
      'id': 'clinic_1',
      'name': 'City General Hospital',
      'address': '123 Medical Drive, Healthville, CA'
    },
    {
      'id': 'clinic_2', 
      'name': 'Metropolitan Medical Center',
      'address': '456 Healthcare Blvd, Medtown, NY'
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchHospital(String clinicId) {
    if (clinicId != _currentHospitalId) {
      setState(() {
        _currentHospitalId = clinicId;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_getHospitalName(clinicId)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getHospitalName(String clinicId) {
    return _availableHospitals
        .firstWhere((h) => h['id'] == clinicId)['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Professional Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clinikx',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        // Hospital Switcher
                        if (_availableHospitals.length > 1)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.business, color: Colors.white),
                            onSelected: _switchHospital,
                            itemBuilder: (context) {
                              return _availableHospitals.map((clinic) {
                                return PopupMenuItem<String>(
                                  value: clinic['id'],
                                  child: Row(
                                    children: [
                                      Icon(
                                        clinic['id'] == _currentHospitalId 
                                          ? Icons.check_circle 
                                          : Icons.business_outlined,
                                        color: clinic['id'] == _currentHospitalId 
                                          ? Colors.green 
                                          : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(clinic['name']),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications feature'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          itemBuilder: (context) {
                            return <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'settings',
                                child: Text('Settings'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Text('Logout', style: TextStyle(color: Colors.red)),
                              ),
                            ];
                          },
                          onSelected: (value) {
                            if (value == 'logout') {
                              // Handle logout
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Main Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      _buildDashboardTab(),
                      _buildQueueTab(),
                      _buildProfileTab(),
                    ],
                  ),
                ),
              ),
              
              // Bottom Navigation
              Container(
                color: Colors.white,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedIndex,
                  selectedItemColor: const Color(0xFF1976D2),
                  unselectedItemColor: Colors.grey,
                  backgroundColor: Colors.white,
                  elevation: 10,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Ionicons.home_outline),
                      activeIcon: Icon(Ionicons.home),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Ionicons.list_outline),
                      activeIcon: Icon(Ionicons.list),
                      label: 'Queue',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Ionicons.person_outline),
                      activeIcon: Icon(Ionicons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your patient consultations efficiently',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Real-time Statistics Cards
          const Row(
            children: [
              Expanded(
                child: _StatisticsCard(
                  title: 'Today\'s Patients',
                  value: '12',
                  icon: Ionicons.people,
                  color: Color(0xFF1565C0),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatisticsCard(
                  title: 'Pending Resources',
                  value: '3',
                  icon: Ionicons.business,
                  color: Color(0xFFFFA000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _StatisticsCard(
                  title: 'Completed Today',
                  value: '8',
                  icon: Ionicons.checkmark_done,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatisticsCard(
                  title: 'Avg. Wait Time',
                  value: '15 min',
                  icon: Ionicons.time,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Session Controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Session Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Ionicons.checkmark_circle, color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Session Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Starting session...'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Start Session'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Completing consultation...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Complete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Quick Actions Section
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActionCard(
                'View Appointments',
                Ionicons.calendar_outline,
                const Color(0xFF1565C0),
                () {
                  // Navigate to queue tab
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildActionCard(
                'Patient Records',
                Ionicons.folder_open_outline,
                const Color(0xFFFFA000),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Patient Records feature coming soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              _buildActionCard(
                'Resource Requests',
                Ionicons.medical_outline,
                const Color(0xFF9C27B0),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resource Requests feature coming soon!'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
              ),
              _buildActionCard(
                'My Schedule',
                Ionicons.time_outline,
                const Color(0xFF2E7D32),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule feature coming soon!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Queue',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 32),
          
          // Sample appointments
          for (int i = 0; i < 5; i++)
            _buildAppointmentCard(i),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Ionicons.medical,
                    size: 50,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dr. John Smith',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'john.smith@clinic.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CARDIOLOGIST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Hospital Information
          const Text(
            'Current Hospital',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Ionicons.business, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Text(
                      _getHospitalName(_currentHospitalId),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _availableHospitals.firstWhere((h) => h['id'] == _currentHospitalId)['address'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Hospital Switcher Section
          const Text(
            'Switch Hospital',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: _availableHospitals.map((clinic) {
                return ListTile(
                  leading: Icon(
                    clinic['id'] == _currentHospitalId 
                      ? Icons.check_circle 
                      : Icons.business_outlined,
                    color: clinic['id'] == _currentHospitalId 
                      ? Colors.green 
                      : Colors.grey,
                  ),
                  title: Text(clinic['name']),
                  subtitle: Text(clinic['address']),
                  onTap: () => _switchHospital(clinic['id']),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(int index) {
    final appointments = [
      {'name': 'Patient 1', 'time': '09:00 AM', 'status': 'Confirmed'},
      {'name': 'Patient 2', 'time': '10:30 AM', 'status': 'In Progress'},
      {'name': 'Patient 3', 'time': '11:15 AM', 'status': 'Waiting'},
      {'name': 'Patient 4', 'time': '02:00 PM', 'status': 'Pending'},
      {'name': 'Patient 5', 'time': '03:30 PM', 'status': 'Confirmed'},
    ];
    
    final appointment = appointments[index % appointments.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFF1976D2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Ionicons.person,
            color: Colors.white,
            size: 25,
          ),
        ),
        title: Text(
          appointment['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${appointment['status']}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appointment['time']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}