import 'package:flutter/material.dart';
import '../../models/qr_registration.dart';
import '../../services/qr_service.dart';
import '../../services/ad_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String? selectedClinicId;

  const DoctorAppointmentsScreen({super.key, this.selectedClinicId});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<QrRegistration> _registrations = [];
  List<QrRegistration> _history = []; // History list
  bool _isLoading = true;
  String _selectedFilter = 'Today';
  int _currentIndex = 0; // Current patient index
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadQrRegistrations();
  }

  Future<void> _loadQrRegistrations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await QrService.initialize();
      // Pass the selected clinic ID to filter registrations
      final registrations = await QrService.getQrRegistrations(clinicId: widget.selectedClinicId);
      
      print('📋 Total registrations loaded: ${registrations.length}');
      if (registrations.isNotEmpty) {
        for (var reg in registrations) {
          print('   - ${reg.fullName} (${reg.mobileNumber})');
        }
      }
      
      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
      
      // Show message if no data
      if (registrations.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No patient registrations found for this clinic'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading QR registrations: $e');
      setState(() {
        _isLoading = false;
        _registrations = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patient data: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _nextPatient() {
    if (_registrations.isNotEmpty && _currentIndex < _registrations.length) {
      // Move current patient to history
      setState(() {
        if (_currentIndex < _registrations.length) {
          _history.insert(0, _registrations[_currentIndex]); // Add to front of history
          _registrations.removeAt(_currentIndex); // Remove from current list
          
          // Adjust index since we removed an item
          if (_currentIndex >= _registrations.length && _registrations.isNotEmpty) {
            _currentIndex = _registrations.length - 1;
          } else if (_registrations.isEmpty) {
            _currentIndex = 0;
          }
        }
      });
    }
  }

  void _startSession() {
    if (_registrations.isNotEmpty && _currentIndex < _registrations.length) {
      // Add current patient to history
      final currentPatient = _registrations[_currentIndex];
      
      setState(() {
        _history.insert(0, currentPatient);
      });
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started session with ${currentPatient.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Patient History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(
                          child: Text('No patient history available'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final patient = _history[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${patient.firstName} ${patient.lastName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('ID: ${patient.id.substring(0, 8)}...'),
                                    Text('Mobile: ${patient.mobileNumber}'),
                                    Text('Status: ${patient.status}'),
                                    Text('Time: ${patient.createdAt}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter registrations based on selected filter
    List<QrRegistration> filteredRegistrations = _registrations;
    if (_selectedFilter == 'Today') {
      filteredRegistrations = _registrations.where((reg) {
        return reg.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'This Week') {
      filteredRegistrations = _registrations.where((reg) {
        return reg.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).toList();
    }

    // If clinic is selected, filter by clinic
    if (widget.selectedClinicId != null) {
      filteredRegistrations = filteredRegistrations.where((reg) {
        return reg.hospitalId == widget.selectedClinicId;
      }).toList();
    }

    // Update current index to stay within bounds
    if (filteredRegistrations.isNotEmpty) {
      if (_currentIndex >= filteredRegistrations.length) {
        setState(() {
          _currentIndex = filteredRegistrations.length - 1;
        });
      }
    } else {
      setState(() {
        _currentIndex = 0;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        toolbarHeight: 40, // Very small appbar height
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQrRegistrations,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Patient Section
                      if (filteredRegistrations.isNotEmpty && _currentIndex < filteredRegistrations.length)
                        _buildCurrentPatientCard(filteredRegistrations[_currentIndex]),
                      
                      // If no patients and not loading
                      if (filteredRegistrations.isEmpty && !_isLoading)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Patients in Queue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Patients will appear here once they register via QR code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadQrRegistrations,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Patient List
                      _buildPatientList(filteredRegistrations),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPatientCard(QrRegistration registration) {
    return Card(
      color: Colors.blue[50], // Light blue background
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14, // Smaller avatar
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    registration.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${registration.firstName} ${registration.lastName}',
                        style: const TextStyle(
                          fontSize: 12, // Smaller font
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${registration.id.length > 6 ? registration.id.substring(0, 6) + "..." : registration.id}',
                        style: const TextStyle(
                          fontSize: 10, // Smaller font
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(6.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.phone, registration.mobileNumber),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.email, registration.email),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.local_hospital, registration.hospitalName),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.medical_services, registration.symptoms),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: registration.status == 'registered' 
                            ? Colors.green[100] 
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Status: ${registration.status.toUpperCase()}',
                        style: TextStyle(
                          color: registration.status == 'registered' 
                              ? Colors.green[800] 
                              : Colors.orange[800],
                          fontSize: 9, // Smaller font
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Very small Start and Next buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_arrow, size: 10),
                  label: const Text('Start', style: TextStyle(fontSize: 9)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _nextPatient,
                  icon: const Icon(Icons.arrow_forward_ios, size: 8),
                  label: const Text('Next', style: TextStyle(fontSize: 9)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(List<QrRegistration> registrations) {
    if (registrations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient Queue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...registrations.asMap().entries.map((entry) {
          int index = entry.key;
          QrRegistration registration = entry.value;
          bool isCurrent = index == _currentIndex;
          
          // Safety check for index bounds
          if (index >= registrations.length) {
            return const SizedBox.shrink();
          }
          
          return Card(
            color: isCurrent ? Colors.blue[50] : null, // Highlight current patient
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      registration.firstName.isNotEmpty 
                          ? registration.firstName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${registration.firstName} ${registration.lastName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'ID: ${registration.id.length > 6 ? registration.id.substring(0, 6) + "..." : registration.id}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: registration.status == 'registered' 
                          ? Colors.green[100] 
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      registration.status.toUpperCase(),
                      style: TextStyle(
                        color: registration.status == 'registered' 
                            ? Colors.green[800] 
                            : Colors.orange[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action buttons with proper constraints
                  IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (index >= 0 && index < registrations.length) {
                              setState(() {
                                _currentIndex = index;
                              });
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          color: Colors.green,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'View',
                        ),
                        IconButton(
                          onPressed: () {
                            // Move patient to history
                            if (index >= 0 && index < registrations.length) {
                              setState(() {
                                _history.insert(0, registration);
                                _registrations.removeAt(index);
                                
                                // Adjust current index if needed
                                if (_currentIndex >= _registrations.length && _registrations.isNotEmpty) {
                                  _currentIndex = _registrations.length - 1;
                                } else if (_registrations.isEmpty) {
                                  _currentIndex = 0;
                                } else if (index <= _currentIndex && _currentIndex > 0) {
                                  _currentIndex = index > 0 ? index - 1 : 0;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          color: Colors.blue,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: 'Next',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}