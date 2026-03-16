import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/qr_registration.dart';
import '../../services/qr_service.dart';

class PatientListWidget extends StatefulWidget {
  final String? selectedClinicId;
  final VoidCallback? onPatientStarted;

  const PatientListWidget({
    super.key,
    this.selectedClinicId,
    this.onPatientStarted,
  });

  @override
  State<PatientListWidget> createState() => _PatientListWidgetState();
}

class _PatientListWidgetState extends State<PatientListWidget> {
  List<QrRegistration> _patients = [];
  bool _isLoading = false;
  QrRegistration? _currentPatient;
  List<QrRegistration> _waitingPatients = [];
  List<QrRegistration> _historyPatients = []; // Completed patients
  DateTime? _lastLoadTime;
  static const _loadDebounceDuration = Duration(seconds: 10); // Prevent rapid reloads

  @override
  void initState() {
    super.initState();
    // Always reload when widget is created
    print('👥 PatientListWidget initialized - loading patients immediately');
    _loadPatients();
  }
  
  @override
  void didUpdateWidget(PatientListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if clinic ID changes
    if (oldWidget.selectedClinicId != widget.selectedClinicId) {
      print('👥 Clinic ID changed - reloading patients');
      _loadPatients();
    }
  }

  Future<void> _loadPatients() async {
    // Validate clinic ID
    if (widget.selectedClinicId == null || widget.selectedClinicId!.isEmpty) {
      print('⚠️ PatientListWidget: No clinic ID provided');
      setState(() => _isLoading = false);
      return;
    }

    // Don't prevent reloads - always load when tab is switched
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!) < _loadDebounceDuration) {
      print('⏳ Skipping patient load - too soon since last load (${now.difference(_lastLoadTime!).inSeconds}s)');
      // Still allow load if it's been more than 5 seconds
      if (now.difference(_lastLoadTime!).inSeconds < 5) {
        return;
      }
    }
    _lastLoadTime = now;

    // Don't reload if already loading
    if (_isLoading) {
      print('⏳ Already loading patients, skipping...');
      return;
    }

    print('🔄 Loading patients for clinic: ${widget.selectedClinicId}');
    setState(() => _isLoading = true);

    try {
      await QrService.initialize();
      print('📡 Fetching QR registrations from backend...');
      final allPatients = await QrService.getQrRegistrations(clinicId: widget.selectedClinicId);
      
      print('📊 Backend returned ${allPatients.length} patients');
      
      if (mounted) {
        setState(() {
          if (allPatients.isNotEmpty) {
            _currentPatient = allPatients.first;
            _waitingPatients = allPatients.skip(1).toList();
            _patients = allPatients;
            print('✅ Loaded ${allPatients.length} patients for clinic ${widget.selectedClinicId}');
          } else {
            _currentPatient = null;
            _waitingPatients = [];
            _patients = [];
            print('ℹ️ No patients found for clinic ${widget.selectedClinicId}');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading patients: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentPatient = null;
          _waitingPatients = [];
          _patients = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: ${e.toString().substring(0, 50)}...'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startPatientProcess() {
    if (_currentPatient == null) {
      print('⚠️ No current patient to start');
      return;
    }

    print('✅ Starting consultation for ${_currentPatient!.fullName}');

    // Send SMS to current patient
    _sendSMSToPatient(_currentPatient!);

    // Send SMS to next patient in queue (if exists)
    if (_waitingPatients.isNotEmpty) {
      _sendSMSToNextPatient(_waitingPatients.first);
    }

    // Move current patient to history
    setState(() {
      if (_currentPatient != null) {
        _historyPatients.add(_currentPatient!);
      }
      
      // Get next patient as current
      if (_waitingPatients.isNotEmpty) {
        _currentPatient = _waitingPatients.first;
        _waitingPatients = _waitingPatients.skip(1).toList();
      } else {
        _currentPatient = null;
      }
    });

    // Callback to notify parent
    widget.onPatientStarted?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Started consultation for ${_currentPatient?.fullName ?? "patient"}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _nextPatient() {
    // Move current patient to history
    if (_currentPatient != null) {
      setState(() {
        _historyPatients.add(_currentPatient!);
        
        // Get next patient as current
        if (_waitingPatients.isNotEmpty) {
          _currentPatient = _waitingPatients.first;
          _waitingPatients = _waitingPatients.skip(1).toList();
          
          // Send SMS to new current patient
          _sendSMSToPatient(_currentPatient!);
          
          // Notify next patient
          if (_waitingPatients.length > 1) {
            _sendSMSToNextPatient(_waitingPatients[1]);
          }
        } else {
          _currentPatient = null;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Next patient called'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendSMSToPatient(QrRegistration patient) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/sms/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': patient.mobileNumber,
          'message': 'Your consultation is starting now. Please proceed to the clinic.',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ SMS sent successfully to ${patient.fullName}');
      } else {
        print('⚠️ SMS API returned: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
    }
  }

  void _sendSMSToNextPatient(QrRegistration patient) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/sms/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': patient.mobileNumber,
          'message': 'You are next in queue. Please get ready.',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ SMS sent successfully to next patient ${patient.fullName}');
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Patient Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_patients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_patients.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _currentPatient == null
                  ? _buildEmptyState()
                  : _buildPatientList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Patients in Queue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Patients will appear here after QR registration',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    return Column(
      children: [
        // Current Patient Card
        _buildCurrentPatientCard(),
        
        // Waiting Patients List
        if (_waitingPatients.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Waiting Patients (${_waitingPatients.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _waitingPatients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildWaitingPatientTile(_waitingPatients[index]),
          ),
        ],
        
        // History Section (Completed Patients)
        if (_historyPatients.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Completed (${_historyPatients.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _historyPatients.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildHistoryPatientTile(_historyPatients[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentPatientCard() {
    if (_currentPatient == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green[100],
                child: Icon(Icons.person, size: 30, color: Colors.green[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _currentPatient!.fullName ?? 'Unknown Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPatient!.mobileNumber ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Start Consultation Button - Smaller size
              Expanded(
                child: Material(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      print('🟢 Start Consultation button tapped');
                      _startPatientProcess();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Start',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Next Button
              Expanded(
                child: Material(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _waitingPatients.isNotEmpty ? _nextPatient : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Next',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPatientTile(QrRegistration patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.orange[100],
        child: Icon(Icons.access_time, size: 20, color: Colors.orange[700]),
      ),
      title: Text(
        patient.fullName ?? 'Unknown Patient',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        patient.mobileNumber ?? 'N/A',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'WAITING',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPatientTile(QrRegistration patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.green[100],
        child: Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
      ),
      title: Text(
        patient.fullName ?? 'Unknown Patient',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        patient.mobileNumber ?? 'N/A',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'COMPLETED',
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
