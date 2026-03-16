import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/appointment.dart';
import '../../models/resource.dart';
import '../../services/ad_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/ad.dart';
import 'modern_patient_queue_screen.dart';
import 'modern_mr_appointments_screen.dart';
import 'patient_list_widget.dart';
import 'start_all_button.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> with TickerProviderStateMixin {
  String? _selectedClinicId;
  List<String> _clinicIds = []; // Store multiple clinic IDs
  Map<String, String> _clinicNames = {}; // Map clinic IDs to names
  List<Ad> _ads = []; // Store ads
  bool _isLoadingAds = false;
  late PageController _adPageController;
  int _currentAdIndex = 0;
  Timer? _adScrollTimer;
  
  // Animation controllers for floating menu
  late AnimationController _menuAnimationController;
  late Animation<double> _mainButtonScaleAnim;
  late Animation<double> _mainButtonRotationAnim;
  bool _isMenuExpanded = false;
  
  // Add request debouncing
  DateTime? _lastLoadTime;
  static const _loadDebounceDuration = Duration(seconds: 30); // Increased to 30s to prevent spam
  
  // Add ads caching
  DateTime? _lastAdLoadTime;
  static const _adCacheDuration = Duration(minutes: 5);
  List<Ad> _cachedAds = [];
  
  // Track if initial load is complete
  bool _initialLoadComplete = false;
  
  // Bottom navigation
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserClinic();
    _loadAds();
    
    // Initialize page controller for ad carousel
    _adPageController = PageController(initialPage: 0, viewportFraction: 0.8);
    
    // Auto-scroll ads every 3 seconds
    _startAdAutoScroll();
    
    // Initialize animation controller for floating menu
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _mainButtonScaleAnim = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );
    
    _mainButtonRotationAnim = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _menuAnimationController, curve: Curves.easeInOut),
    );
  }

  void _startAdAutoScroll() {
    _adScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_ads.length > 1 && mounted && _adPageController.hasClients) {
        final nextPage = (_currentAdIndex + 1) % _ads.length;
        _adPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentAdIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _adPageController.dispose();
    _adScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserClinic() async {
    // Prevent rapid reloads
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!) < _loadDebounceDuration) {
      print('⏳ Skipping load - too soon since last load');
      return;
    }
    _lastLoadTime = now;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // Get all associated clinic IDs from user model
        List<String> clinicIds = [];
        if (user.associatedClinicIds != null && user.associatedClinicIds!.isNotEmpty) {
          clinicIds = List<String>.from(user.associatedClinicIds!);
        }
        if (user.hospitalId != null && !clinicIds.contains(user.hospitalId)) {
          clinicIds.add(user.hospitalId!);
        }
        
        // Fetch clinic names from API with timeout
        Map<String, String> clinicNames = {};
        for (String clinicId in clinicIds) {
          try {
            final clinicName = await _fetchClinicName(clinicId).timeout(
              const Duration(seconds: 5),
              onTimeout: () => 'Clinic ${clinicIds.indexOf(clinicId) + 1}',
            );
            clinicNames[clinicId] = clinicName ?? 'Clinic ${clinicIds.indexOf(clinicId) + 1}';
          } catch (e) {
            print('⚠️ Error fetching clinic name for $clinicId: $e');
            clinicNames[clinicId] = 'Clinic ${clinicIds.indexOf(clinicId) + 1}';
          }
        }
        
        setState(() {
          _clinicIds = clinicIds;
          _clinicNames = clinicNames;
          _selectedClinicId = clinicIds.isNotEmpty ? clinicIds.first : null;
        });
        
        print('✅ Loaded ${clinicIds.length} clinics: ${clinicNames.values.join(", ")}');
        
        // Load queues for this clinic if we have one - with timeout to prevent hanging
        if (_selectedClinicId != null && mounted && !_initialLoadComplete) {
          final queueProvider = Provider.of<QueueProvider>(context, listen: false);
          print('🔄 Loading dashboard data for clinic: $_selectedClinicId');
          try {
            await queueProvider.loadQueues(
              user.id ?? '',
              _selectedClinicId!,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ Queue loading timed out after 10 seconds');
              },
            );
            print('✅ Dashboard queues loaded');
            _initialLoadComplete = true; // Mark initial load as complete
          } catch (e) {
            print('❌ Error loading queues: $e');
          }
          // Removed duplicate _loadAds() - already called in initState with caching
        }
      }
    } catch (e) {
      print('❌ Error loading user clinic: $e');
    }
  }

  Future<String?> _fetchClinicName(String clinicId) async {
    try {
      final authHeaders = AuthService.getAuthHeaders();
      final response = await ApiService.get('/clinics/$clinicId', headers: authHeaders);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['name'] as String?;
      }
    } catch (e) {
      print('Error fetching clinic name for $clinicId: $e');
    }
    return null;
  }

  Future<void> _loadAds() async {
    if (!mounted) return;
    
    // Check cache first
    final now = DateTime.now();
    if (_lastAdLoadTime != null && now.difference(_lastAdLoadTime!) < _adCacheDuration && _cachedAds.isNotEmpty) {
      print('📢 Using cached ads (${_cachedAds.length} ads)');
      setState(() {
        _ads = _cachedAds;
      });
      return;
    }
    
    // Prevent duplicate ad loading
    if (_isLoadingAds) {
      print('⏳ Ads already loading, skipping...');
      return;
    }
    
    setState(() {
      _isLoadingAds = true;
    });
    
    // Show test ads immediately while API loads (better UX)
    if (_cachedAds.isEmpty) {
      final testAds = AdService.getTestAds();
      if (mounted) {
        setState(() {
          _ads = testAds;
        });
      }
    }
    
    try {
      print('📢 Loading ads for clinic: $_selectedClinicId');
      final ads = await AdService.getAds(clinicId: _selectedClinicId).timeout(
        const Duration(seconds: 5), // Reduced from 8s to 5s for faster response
        onTimeout: () {
          print('⚠️ Ad loading timed out, using fallback');
          return AdService.getTestAds(); // Return test ads on timeout
        },
      );
      
      if (mounted) {
        // If API returns empty, use test ads
        final effectiveAds = ads.isNotEmpty ? ads : AdService.getTestAds();
        setState(() {
          _ads = effectiveAds;
          _cachedAds = effectiveAds; // Cache the ads
          _isLoadingAds = false;
        });
        _lastAdLoadTime = DateTime.now();
        print('✅ Loaded ${effectiveAds.length} ads');
      }
    } catch (e) {
      print('⚠️ Error loading ads: $e');
      if (mounted) {
        // On error, use test ads
        final fallbackAds = AdService.getTestAds();
        setState(() {
          _ads = fallbackAds;
          _cachedAds = fallbackAds;
          _isLoadingAds = false;
        });
        _lastAdLoadTime = DateTime.now();
      }
    }
  }

  void _switchClinic() {
    if (_clinicIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only one clinic available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show clinic selection dialog with better UI
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch Clinic',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your active clinic',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                ..._clinicIds.map((clinicId) {
                  final isSelected = clinicId == _selectedClinicId;
                  final clinicName = _clinicNames[clinicId] ?? 'Clinic';
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _selectClinic(clinicId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clinicName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${clinicId.substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectClinic(String clinicId) async {
    print('🏥 Switching to clinic: $clinicId');
    setState(() {
      _selectedClinicId = clinicId;
    });

    // Reload queues for new clinic
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_clinicNames[clinicId] ?? "Clinic"}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Load queues for new clinic
      await queueProvider.loadQueues(
        authProvider.currentUser?.id ?? '',
        clinicId,
      );
      
      // Force refresh of current page
      setState(() {
        // This triggers a rebuild of all pages with new clinic data
      });
      
      print('✅ Clinic switched successfully. Queues reloaded.');
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_clinicIds.length > 1 && _selectedClinicId != null) ...[
              GestureDetector(
                onTap: _switchClinic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🏥 ${_clinicNames[_selectedClinicId] != null && _clinicNames[_selectedClinicId]!.length > 20 
                            ? '${_clinicNames[_selectedClinicId]!.substring(0, 20)}...' 
                            : (_clinicNames[_selectedClinicId] ?? "Select Clinic")}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          GestureDetector(
            onTap: () {
              print('🔄 Dashboard refresh tapped');
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final queueProvider = Provider.of<QueueProvider>(context, listen: false);
              queueProvider.loadQueues(
                authProvider.currentUser?.id ?? '',
                _selectedClinicId ?? '',
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 12),
                      Text('Logout'),
                    ],
                  ),
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
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboardPage(),
              _buildPatientListPage(),
              _buildMRAppointmentsPage(),
              _buildProfilePage(),
            ],
          ),
          // Show floating menu only on dashboard page
          if (_selectedIndex == 0) ..._buildFloatingMenuAsOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'MR Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return Consumer2<AuthProvider, QueueProvider>(
      builder: (context, authProvider, queueProvider, child) {
        final user = authProvider.currentUser;
        
        // Auto-load data EVERY time dashboard is shown
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
            print('⏳ No clinic selected, skipping auto-load');
            return;
          }
          
          print('🔄 Dashboard visible - loading queues for clinic: $_selectedClinicId');
          try {
            await queueProvider.loadQueues(
              user?.id ?? '',
              _selectedClinicId ?? '',
            );
            print('✅ Dashboard queues loaded');
          } catch (e) {
            print('❌ Error loading queues: $e');
          }
        });
        
        return RefreshIndicator(
          onRefresh: () async {
            print('🔄 Manual refresh triggered');
            await queueProvider.loadQueues(
              user?.id ?? '',
              _selectedClinicId ?? '',
            );
            await _loadAds();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad Banner - fixed opacity issue
                if (_ads.isNotEmpty)
                  _buildAdBanner(),
                
                // Start All Button
                StartAllButton(selectedClinicId: _selectedClinicId),
                const SizedBox(height: 16),
                
                // Patient List with Start Button
                PatientListWidget(
                  selectedClinicId: _selectedClinicId,
                  onPatientStarted: () {
                    print('Patient started - refreshing...');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMRAppointmentsPage() {
    // Force reload when switching to MR Appointments tab
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🏥 MR Appointments tab opened - clinic ID: $_selectedClinicId');
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        print('❌ ERROR: No clinic ID selected for MR Appointments tab!');
      }
    });
    
    // Ensure we have a valid clinic ID
    final clinicId = _selectedClinicId ?? '';
    
    return KeyedSubtree(
      key: ValueKey('mr_appointments_page_$clinicId'),
      child: ModernMRAppointmentsScreen(selectedClinicId: clinicId),
    );
  }

  Widget _buildPatientListPage() {
    // Force reload when switching to Patients tab
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('👥 Patients tab opened - clinic ID: $_selectedClinicId');
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        print('❌ ERROR: No clinic ID selected for Patients tab!');
      }
    });
    
    // Ensure we have a valid clinic ID
    final clinicId = _selectedClinicId ?? '';
    
    return KeyedSubtree(
      key: ValueKey('patients_page_$clinicId'),
      child: PatientListWidget(
        selectedClinicId: clinicId,
        onPatientStarted: () {
          print('Patient started from Patients tab - refreshing...');
        },
      ),
    );
  }

  List<Widget> _buildFloatingMenuAsOverlay() {
    // Return floating menu as a list of widgets for Stack overlay
    return [_buildFloatingMenu()];
  }

  Widget _buildAppointmentItem(Appointment appointment, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAppointmentStatusColor(appointment.status),
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(appointment.reason),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appointment.appointmentDate.toString().split(' ')[0]} • ${appointment.timeSlot}'),
            if (appointment.isEmergency)
              const Chip(
                label: Text('Emergency'),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
        trailing: Text(
          _getAppointmentStatusText(appointment.status),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getAppointmentStatusColor(appointment.status),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceItem(Resource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(resource.name),
        subtitle: Text('${resource.company} • ${resource.contactPerson}'),
        trailing: Text(
          resource.timeSlot,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getAppointmentStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }



  Widget _buildProfilePage() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Enhanced Profile Header with Switch Clinic Button
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Doctor',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.role.toString().split('.').last ?? 'Doctor',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not provided'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Phone'),
                  subtitle: Text(user?.phone ?? 'Not provided'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Assigned Clinics'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_clinicIds.isEmpty)
                        const Text('No clinics assigned')
                      else
                        ..._clinicIds.map((clinicId) {
                          final clinicName = _clinicNames[clinicId] ?? 'Clinic';
                          final isSelected = clinicId == _selectedClinicId;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinicName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${clinicId.substring(0, 8)}...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    if (_ads.isEmpty || !mounted) {
      print('🚫 Ads not showing: isEmpty=${_ads.isEmpty}, mounted=$mounted, isLoadingAds=$_isLoadingAds');
      return const SizedBox.shrink();
    }
    
    // Sort ads by priority (highest first)
    final sortedAds = List<Ad>.from(_ads)..sort((a, b) => b.priority.compareTo(a.priority));
    
    print('✅ Displaying ${sortedAds.length} ads');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 120,
      child: Stack(
        children: [
          PageView.builder(
            controller: _adPageController,
            scrollDirection: Axis.horizontal,
            itemCount: sortedAds.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentAdIndex = index;
                });
              }
            },
            itemBuilder: (context, index) {
              final ad = sortedAds[index];
              print('📢 Building ad #$index: ${ad.title} | imageUrl: ${ad.imageUrl} | localAsset: ${ad.localAssetPath}');
              return GestureDetector(
                onTap: () {
                  if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening: ${ad.title}')),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildAdImage(ad),
                  ),
                ),
              );
            },
          ),
          // Page indicators
          if (sortedAds.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(sortedAds.length, (index) {
                  return Container(
                    width: _currentAdIndex == index ? 12 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentAdIndex == index ? Colors.blue : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Build ad image with multiple fallback options
  Widget _buildAdImage(Ad ad) {
    print('🖼️ Building ad image for: ${ad.title}');
    print('   - imageUrl: "${ad.imageUrl}"');
    print('   - localAssetPath: "${ad.localAssetPath}"');
    
    // Priority 1: Try network image if URL exists
    if (ad.imageUrl.isNotEmpty && ad.imageUrl != 'null') {
      return Image.network(
        ad.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        cacheWidth: 400,
        cacheHeight: 120,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading network image: ${ad.imageUrl}');
          print('   Error: $error');
          // Fallback to placeholder
          return _buildAdPlaceholder(ad);
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          // Simple placeholder while loading - no progress indicator to avoid stuck buffer
          return Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey, size: 40),
            ),
          );
        },
      );
    }
    
    // Priority 2: Try local asset if path exists
    if (ad.localAssetPath != null && ad.localAssetPath!.isNotEmpty && ad.localAssetPath != 'null') {
      return Image.asset(
        ad.localAssetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        package: null, // Use default package resolution
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading local asset: ${ad.localAssetPath}');
          print('   Error: $error');
          return _buildAdPlaceholder(ad);
        },
      );
    }
    
    // Priority 3: Show placeholder
    print('📄 Showing placeholder for ad: ${ad.title}');
    return _buildAdPlaceholder(ad);
  }

  // NEW: Build ad placeholder when no image available
  Widget _buildAdPlaceholder(Ad ad) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.indigo.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 40, color: Colors.blue.shade300),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ad.title,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMenu() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Menu items (slide-in animation)
          AnimatedBuilder(
            animation: _menuAnimationController,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(
                    icon: Icons.add_circle_outline,
                    label: 'New Patient',
                    delay: 0,
                    onTap: () => _handleMenuAction('New Patient'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Schedule',
                    delay: 1,
                    onTap: () => _handleMenuAction('Schedule'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.message_outlined,
                    label: 'Messages',
                    delay: 2,
                    onTap: () => _handleMenuAction('Messages'),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Alerts',
                    delay: 3,
                    onTap: () => _handleMenuAction('Alerts'),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Main floating action button with pulse effect
          GestureDetector(
            onTap: _toggleMenu,
            child: AnimatedBuilder(
              animation: _menuAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _mainButtonScaleAnim.value,
                  child: Transform.rotate(
                    angle: _mainButtonRotationAnim.value * 3.14159,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1976D2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                          if (_isMenuExpanded)
                            BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (delay * 50)),
      tween: Tween(begin: 0.0, end: _isMenuExpanded ? 1.0 : 0.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0), // Slide from right
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: value > 0.5 ? onTap : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Label on the LEFT
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Icon on the RIGHT
                        Icon(icon, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleMenu() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
    });
    
    if (_isMenuExpanded) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  void _handleMenuAction(String action) {
    _toggleMenu();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action clicked'),
        backgroundColor: const Color(0xFF1976D2),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}