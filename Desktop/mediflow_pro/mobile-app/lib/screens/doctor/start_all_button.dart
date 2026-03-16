import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/qr_registration.dart';
import '../../services/qr_service.dart';

class StartAllButton extends StatefulWidget {
  final String? selectedClinicId;

  const StartAllButton({super.key, this.selectedClinicId});

  @override
  State<StartAllButton> createState() => _StartAllButtonState();
}

class _StartAllButtonState extends State<StartAllButton> {
  bool _isSending = false;
  int _totalPatients = 0;
  int _sentCount = 0;
  bool _showProgress = false;

  Future<void> _startAllProcess() async {
    print('🔵 Start All Process triggered');
    
    // Prevent multiple clicks
    if (_isSending) return;
    
    if (widget.selectedClinicId == null || widget.selectedClinicId!.isEmpty) {
      print('⚠️ No clinic selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a clinic first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _showProgress = true;
      _sentCount = 0;
    });

    try {
      await QrService.initialize();
      final patients = await QrService.getQrRegistrations(clinicId: widget.selectedClinicId);
      
      _totalPatients = patients.length;
      print('📊 Found $_totalPatients patients for clinic ${widget.selectedClinicId}');

      if (_totalPatients == 0) {
        setState(() {
          _isSending = false;
          _showProgress = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No patients in queue'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Send SMS to all patients
      for (var patient in patients) {
        print('📱 Sending SMS to ${patient.fullName} (${patient.mobileNumber})');
        await _sendBulkSMS(patient);
        if (mounted) {
          setState(() {
            _sentCount++;
          });
        }
        // Reduced delay for faster processing
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        _isSending = false;
        _showProgress = false;
      });

      if (mounted) {
        print('✅ Successfully sent SMS to all $_totalPatients patients');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ SMS sent to all $_totalPatients patients!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in Start All Process: $e');
      setState(() {
        _isSending = false;
        _showProgress = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().substring(0, 50)}...'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendBulkSMS(QrRegistration patient) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/sms/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': patient.mobileNumber,
          'message': 'Doctor is now available. Your consultation will start soon.',
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ SMS sent to ${patient.fullName} (${patient.mobileNumber})');
      } else {
        print('⚠️ SMS API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 60,
        maxHeight: 80,
      ),
      child: GestureDetector(
        onTap: () {
          print('🔵 Start All button tapped');
          if (!_isSending) {
            _startAllProcess();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Already processing...'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isSending ? Icons.send : Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSending ? 'Sending SMS...' : 'Start All',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isSending 
                                ? 'Notifying patients...' 
                                : 'Send SMS to all registered patients',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_showProgress) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalPatients > 0 ? _sentCount / _totalPatients : 0,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_sentCount / $_totalPatients patients notified',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
