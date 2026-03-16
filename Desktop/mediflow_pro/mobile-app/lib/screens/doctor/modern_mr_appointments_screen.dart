import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../models/qr_registration.dart';
import '../../services/qr_service.dart';

class ModernMRAppointmentsScreen extends StatefulWidget {
  final String? selectedClinicId;

  const ModernMRAppointmentsScreen({super.key, this.selectedClinicId});

  @override
  State<ModernMRAppointmentsScreen> createState() => _ModernMRAppointmentsScreenState();
}

class _ModernMRAppointmentsScreenState extends State<ModernMRAppointmentsScreen> {
  List<QrRegistration> _mrList = [];
  bool _isLoading = false;
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  DateTime? _lastLoadTime;
  static const _loadDebounceDuration = Duration(seconds: 10); // Prevent rapid reloads

  @override
  void initState() {
    super.initState();
    // Always reload when widget is created
    print('🏥 ModernMRAppointmentsScreen initialized - loading MRs immediately');
    _loadMRs();
  }
  
  @override
  void didUpdateWidget(ModernMRAppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if clinic ID changes
    if (oldWidget.selectedClinicId != widget.selectedClinicId) {
      print('🏥 Clinic ID changed - reloading MR appointments');
      _loadMRs();
    }
  }

  Future<void> _loadMRs() async {
    if (widget.selectedClinicId == null || widget.selectedClinicId!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Don't prevent reloads - always load when tab is switched
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!) < _loadDebounceDuration) {
      print('⏳ Skipping MR load - too soon since last load (${now.difference(_lastLoadTime!).inSeconds}s)');
      // Still allow load if it's been more than 5 seconds
      if (now.difference(_lastLoadTime!).inSeconds < 5) {
        return;
      }
    }
    _lastLoadTime = now;

    // Prevent multiple simultaneous loads
    if (_isLoading) {
      print('⏳ Already loading MRs, skipping...');
      return;
    }

    print('🔄 Loading MR appointments for clinic: ${widget.selectedClinicId}');
    setState(() => _isLoading = true);

    try {
      await QrService.initialize();
      final mrs = await QrService.getMrRegistrations(clinicId: widget.selectedClinicId);
      
      if (mounted) {
        setState(() {
          _mrList = mrs;
          _isLoading = false;
          print('✅ Loaded ${mrs.length} MR appointments for clinic ${widget.selectedClinicId}');
        });
      }
    } catch (e) {
      print('❌ Error loading MR appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mrList = [];
        });
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

  void _handleAction(QrRegistration mr, String action) {
    String message = '';
    Color color = Colors.grey;
    
    switch (action) {
      case 'accepted':
        message = '✅ ${mr.fullName} accepted!';
        color = Colors.green;
        print('✅ Accepted MR: ${mr.fullName}');
        break;
      case 'rescheduled':
        message = '🔄 ${mr.fullName} rescheduled';
        color = Colors.orange;
        print('🔄 Rescheduled MR: ${mr.fullName}');
        break;
      case 'rejected':
        message = '❌ ${mr.fullName} rejected';
        color = Colors.red;
        print('❌ Rejected MR: ${mr.fullName}');
        break;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMRDetails(QrRegistration mr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple[100],
                    child: Icon(Icons.business, size: 30, color: Colors.purple[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mr.fullName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mr.visitType,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(Icons.phone, 'Phone', '+91 ${mr.mobileNumber}'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.email, 'Email', mr.email),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.local_hospital, 'Hospital', mr.hospitalName),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.medical_services, 'Purpose', mr.symptoms),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleAction(mr, 'accepted');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleAction(mr, 'rescheduled');
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Reschedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'MR Appointments',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2), // Changed from purple to blue
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                print('✅ Done selection tapped');
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                });
              },
              tooltip: 'Done',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                print('🔘 Select All tapped');
                setState(() => _isSelectionMode = true);
              },
              tooltip: 'Select',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                print('🔄 Refresh tapped');
                _loadMRs();
              },
              tooltip: 'Refresh',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mrList.isEmpty
              ? _buildEmptyState()
              : _buildMRList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100, color: Colors.purple[100]),
          const SizedBox(height: 24),
          Text(
            'No MR Appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Medical Representative appointments will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              print('🔄 Refresh button tapped');
              _loadMRs();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(150, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMRList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _mrList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMRCard(_mrList[index]),
    );
  }

  Widget _buildMRCard(QrRegistration mr) {
    final isSelected = _selectedIds.contains(mr.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (_selectedIds.contains(mr.id)) {
              _selectedIds.remove(mr.id);
            } else {
              _selectedIds.add(mr.id);
            }
          });
        } else {
          _showMRDetails(mr);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          if (_selectedIds.contains(mr.id)) {
            _selectedIds.remove(mr.id);
          } else {
            _selectedIds.add(mr.id);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isSelectionMode) ...[
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(mr.id);
                          } else {
                            _selectedIds.remove(mr.id);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.business, color: Colors.blue[700], size: 28),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: mr.status == 'pending' ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mr.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '+91 ${mr.mobileNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mr.visitType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Small Reschedule Icon Button (compact)
                Material(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () {
                      print('🔄 Reschedule tapped for: ${mr.fullName}');
                      _handleAction(mr, 'rescheduled');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
