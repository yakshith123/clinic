import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as ModelUser;
import '../../services/firebase_qr_service.dart';
import '../../models/qr_registration.dart';
import '../../models/clinic.dart';
import '../../services/queue_service.dart';
import '../admin/ad_management_screen.dart';

class QRRegistrationScreen extends StatefulWidget {
  const QRRegistrationScreen({super.key});

  @override
  State<QRRegistrationScreen> createState() => _QRRegistrationScreenState();
}

class _QRRegistrationScreenState extends State<QRRegistrationScreen> {
  List<QrRegistration> _registrations = [];
  bool _isLoading = true;
  String _selectedClinicId = '';
  List<Clinic> _clinics = [];
  bool _isLoadingClinics = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _loadRegistrations();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await QueueService.getAllClinics();
      setState(() {
        _clinics = clinics;
        _isLoadingClinics = false;
        if (clinics.isNotEmpty) {
          _selectedClinicId = clinics[0].id;
        }
      });
    } catch (e) {
      print('Error loading clinics: $e');
      setState(() {
        _isLoadingClinics = false;
      });
    }
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseQrService.initialize();
      
      // Load registrations based on selected clinic
      if (_selectedClinicId.isNotEmpty) {
        final registrations = await FirebaseQrService.getQrRegistrationsByHospital(_selectedClinicId);
        setState(() {
          _registrations = registrations;
          _isLoading = false;
        });
      } else {
        // Load all registrations if no clinic selected
        final registrations = await FirebaseQrService.getQrRegistrations();
        setState(() {
          _registrations = registrations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading QR registrations: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patient registrations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Registration'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          // Ad Management Button (Admin only)
          if (currentUser?.role == ModelUser.UserRole.admin)
            IconButton(
              icon: const Icon(Icons.campaign),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdManagementScreen()),
                );
              },
              tooltip: 'Manage Ads',
            ),
          // Clinic selector
          if (_clinics.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedClinicId,
                underline: const SizedBox(),
                hint: const Text('Select Clinic'),
                items: _clinics.map((clinic) {
                  return DropdownMenuItem(
                    value: clinic.id,
                    child: Text(
                      clinic.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedClinicId = newValue;
                    });
                    _loadRegistrations();
                  }
                },
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.grey,
                isDense: true,
                style: const TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRegistrations,
              child: _registrations.isEmpty
                  ? _buildEmptyState()
                  : _buildRegistrationsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No QR Registrations Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Patients registered via your external web app will appear here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Using Your External Web App:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Generate QR codes for your clinic'),
                    Text('• Patients register through the web form'),
                    Text('• Data is stored in Firebase'),
                    Text('• View registrations here in real-time'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _registrations.length,
      itemBuilder: (context, index) {
        final registration = _registrations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                registration.firstName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              registration.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${registration.mobileNumber} • ${registration.email}'),
                const SizedBox(height: 4),
                Text('Hospital: ${registration.hospitalName}'),
                Text('Visit Type: ${registration.visitType}'),
                Text('Symptoms: ${registration.symptoms}'),
                const SizedBox(height: 4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${registration.createdAt.hour}:${registration.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${registration.createdAt.day}/${registration.createdAt.month}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () {
              _showRegistrationDetails(registration);
            },
          ),
        );
      },
    );
  }

  void _showRegistrationDetails(QrRegistration registration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Patient Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Full Name', registration.fullName),
                  _buildDetailRow('Email', registration.email),
                  _buildDetailRow('Phone', registration.mobileNumber),
                  _buildDetailRow('Hospital', registration.hospitalName),
                  _buildDetailRow('Visit Type', registration.visitType),
                  _buildDetailRow('Symptoms', registration.symptoms),
                  _buildDetailRow('Status', registration.status),
                  _buildDetailRow('Registered At', 
                    '${registration.createdAt.day}/${registration.createdAt.month}/${registration.createdAt.year} ${registration.createdAt.hour}:${registration.createdAt.minute}'),
                  const SizedBox(height: 20),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integration with External Web App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'This patient was registered through your external web application. The data is automatically synchronized with Firebase and displayed here in real-time.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}