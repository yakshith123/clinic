import 'package:flutter/material.dart';
import '../../models/qr_registration.dart';
import '../../services/qr_service.dart';

class MrAppointmentsScreen extends StatefulWidget {
  final String? selectedClinicId;

  const MrAppointmentsScreen({super.key, this.selectedClinicId});

  @override
  State<MrAppointmentsScreen> createState() => _MrAppointmentsScreenState();
}

class _MrAppointmentsScreenState extends State<MrAppointmentsScreen> with WidgetsBindingObserver {
  List<QrRegistration> _mrRegistrations = [];
  bool _isLoading = false;
  String? _lastClinicId;
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('💡 MR Appointments Screen initialized');
    print('🏥 Selected Clinic ID: ${widget.selectedClinicId}');
    _loadMrRegistrations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Reload data when app comes back to foreground
      if (_lastClinicId != widget.selectedClinicId) {
        _loadMrRegistrations();
      }
    }
  }

  @override
  void didUpdateWidget(MrAppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if clinic changed
    if (oldWidget.selectedClinicId != widget.selectedClinicId && mounted) {
      print('🔄 Clinic changed from ${oldWidget.selectedClinicId} to ${widget.selectedClinicId}, reloading data...');
      _loadMrRegistrations();
    }
  }

  Future<void> _loadMrRegistrations() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      print('⏳ Already loading, skipping...');
      return;
    }

    print('🔄 Starting to load MR registrations...');
    print('🏥 Clinic ID: ${widget.selectedClinicId}');
    
    // Always set loading state first
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Validate clinic ID
      if (widget.selectedClinicId == null || widget.selectedClinicId!.isEmpty) {
        print('⚠️ No clinic ID provided');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _mrRegistrations = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a clinic first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Load MR registrations filtered by clinic
      print('🌐 Calling API for clinic: ${widget.selectedClinicId}');
      final registrations = await QrService.getMrRegistrations(clinicId: widget.selectedClinicId);

      print('📋 Total MR registrations loaded: ${registrations.length}');
      if (registrations.isNotEmpty) {
        for (var reg in registrations) {
          print('   - ${reg.fullName} (${reg.mobileNumber}) from ${reg.hospitalName}');
        }
      } else {
        print('⚠️ No MR appointments found for clinic: ${widget.selectedClinicId}');
      }

      if (mounted) {
        setState(() {
          _mrRegistrations = registrations;
          _lastClinicId = widget.selectedClinicId;
          _isLoading = false;
        });

        // Show message if no data
        if (registrations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No appointments found. Register via the web admin panel at http://localhost:3014'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading MR registrations: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mrRegistrations = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: ${e.toString().substring(0, 80)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _scrollToPosition(double position) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleAppointmentAction(QrRegistration mr, String action) {
    print('🎯 Action tapped: $action for ${mr.fullName}');
    String message = '';
    Color backgroundColor = Colors.grey;
    
    switch (action) {
      case 'accepted':
        message = '✅ ${mr.fullName} accepted!';
        backgroundColor = Colors.green;
        break;
      case 'rescheduled':
        message = '🔄 ${mr.fullName} rescheduled';
        backgroundColor = Colors.orange;
        break;
      case 'rejected':
        message = '❌ ${mr.fullName} rejected';
        backgroundColor = Colors.red;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBulkAction(String action) {
    print('🎯 Bulk action selected: $action');
    print('📊 Selected count: ${_selectedIds.length}');
    if (_selectedIds.isEmpty) return;
    
    String message = '';
    Color backgroundColor = Colors.blue;
    int count = _selectedIds.length;
    
    switch (action) {
      case 'accept_all':
        message = '✅ Accepted $count pending appointments';
        backgroundColor = Colors.green;
        break;
      case 'reject_selected':
        message = '❌ Rejected $count selected appointments';
        backgroundColor = Colors.red;
        break;
      case 'reschedule_selected':
        message = '🔄 Rescheduled $count selected appointments';
        backgroundColor = Colors.orange;
        break;
      case 'message_selected':
        _sendBulkMessage();
        return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _sendBulkMessage() {
    if (_selectedIds.isEmpty) return;
    
    final selectedMRs = _mrRegistrations.where((mr) => _selectedIds.contains(mr.id)).toList();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📱 Sending message to ${selectedMRs.length} MRs...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Open WhatsApp',
          textColor: Colors.white,
          onPressed: () {
            print('Opening WhatsApp for bulk message');
          },
        ),
      ),
    );
    
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _showHistoryDialog(QrRegistration mr) {
    print('👁️ History dialog opened for: ${mr.fullName}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mr.fullName}\'s History'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Previous Visits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Feb 15, 2026 - Product Discussion'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Jan 20, 2026 - Sample Distribution'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Dec 10, 2025 - Initial Meeting'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text('+91 ${mr.mobileNumber}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mr.email ?? 'N/A',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📱 Messaging ${mr.fullName}...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text('Message'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : const Text(
                'MR Appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMrRegistrations,
                tooltip: 'Refresh',
              ),
        actions: [
          if (_isSelectionMode)
            // Bulk Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleBulkAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'accept_all',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Accept All Pending'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject_selected',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Reject Selected'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reschedule_selected',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Reschedule Selected'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'message_selected',
                  child: Row(
                    children: [
                      Icon(Icons.message, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Message Selected'),
                    ],
                  ),
                ),
              ],
            )
          else
            // Select button - Always visible
            TextButton.icon(
              onPressed: () {
                print('👆 Select button tapped - entering selection mode');
                setState(() {
                  _isSelectionMode = true;
                });
              },
              icon: const Icon(Icons.touch_app, size: 18),
              label: const Text(
                'Select',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMrRegistrations,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mrRegistrations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 80,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Appointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appointments will appear here once registered',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadMrRegistrations,
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
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _mrRegistrations.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final mr = _mrRegistrations[index];
                          return _buildMrAppointmentCard(mr);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMrAppointmentCard(QrRegistration mr) {
    final isSelected = _selectedIds.contains(mr.id);
    
    return GestureDetector(
      onTap: () => _showHistoryDialog(mr),
      onLongPress: () {
        // Keep long press as backup, but Select button is primary
        print('✋ Long press detected (backup method)');
        setState(() {
          _isSelectionMode = true;
          if (_selectedIds.contains(mr.id)) {
            _selectedIds.remove(mr.id);
          } else {
            _selectedIds.add(mr.id);
            print('✅ Added to selection: ${mr.fullName} (Total: ${_selectedIds.length})');
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Checkbox (only in selection mode)
              if (_isSelectionMode)
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      print('☑️ Checkbox changed for ${mr.fullName}: $value');
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(mr.id);
                          print('✅ Added to selection: ${mr.fullName} (Total: ${_selectedIds.length})');
                        } else {
                          _selectedIds.remove(mr.id);
                          print('❌ Removed from selection: ${mr.fullName} (Total: ${_selectedIds.length})');
                        }
                      });
                    },
                  ),
                ),
              
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    radius: 18,
                    child: Icon(
                      Icons.person,
                      color: Colors.purple.shade700,
                      size: 16,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: mr.status == 'pending' 
                            ? Colors.orange 
                            : mr.status == 'completed' 
                                ? Colors.green 
                                : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              
              // Info - Compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      mr.fullName ?? 'Unknown MR',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Phone & Visit Type in one line
                    Row(
                      children: [
                        Icon(Icons.phone, size: 10, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '+91 ${mr.mobileNumber ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mr.visitType ?? 'Info',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Buttons - Compact
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Accept button
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      onPressed: () => _handleAppointmentAction(mr, 'accepted'),
                      tooltip: 'Accept',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
                    ),
                    // Reschedule button
                    IconButton(
                      icon: const Icon(Icons.schedule, color: Colors.orange, size: 20),
                      onPressed: () => _handleAppointmentAction(mr, 'rescheduled'),
                      tooltip: 'Reschedule',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
                    ),
                    // Reject button
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      onPressed: () => _handleAppointmentAction(mr, 'rejected'),
                      tooltip: 'Reject',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      iconSize: 20,
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
}
