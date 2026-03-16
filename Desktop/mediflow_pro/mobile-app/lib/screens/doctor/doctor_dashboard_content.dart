import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/appointment.dart';
import '../../models/resource.dart';
import '../../widgets/doctor/queue_card.dart';
import '../../widgets/doctor/list_queue_card.dart';
import '../../widgets/doctor/session_controls.dart';

class DoctorDashboardContent extends StatelessWidget {
  const DoctorDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, QueueProvider>(
      builder: (context, authProvider, queueProvider, child) {
        final user = authProvider.currentUser;
        
        return RefreshIndicator(
          onRefresh: () => queueProvider.loadQueues(
            user?.id ?? '',
            user?.hospitalId ?? '',
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  'Welcome, Dr. ${user?.name.split(' ').first ?? ''}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today is ${DateTime.now().toString().split(' ').first}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Session Status Card
                Card(
                  color: queueProvider.isSessionActive 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          queueProvider.isSessionActive 
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 40,
                          color: queueProvider.isSessionActive 
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                queueProvider.isSessionActive
                                    ? 'Session Active'
                                    : 'Session Inactive',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: queueProvider.isSessionActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                queueProvider.isSessionActive
                                    ? 'Currently seeing patients'
                                    : 'Tap Start Session to begin',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dual Queue Dashboard
                const Text(
                  'Queue Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Patient Queue
                ListQueueCard<Appointment>(
                  title: 'Patient Queue',
                  icon: Ionicons.people,
                  items: queueProvider.patientQueue,
                  itemCount: queueProvider.patientQueue.length,
                  itemBuilder: (context, index) {
                    final appointment = queueProvider.patientQueue[index];
                    return _buildAppointmentItem(appointment, index);
                  },
                  emptyMessage: 'No patients in queue',
                ),
                const SizedBox(height: 16),

                // Resource Queue
                ListQueueCard<Resource>(
                  title: 'Resource Queue',
                  icon: Ionicons.business,
                  items: queueProvider.resourceQueue,
                  itemCount: queueProvider.resourceQueue.length,
                  itemBuilder: (context, index) {
                    final resource = queueProvider.resourceQueue[index];
                    return _buildResourceItem(resource);
                  },
                  emptyMessage: 'No resources scheduled',
                ),
                const SizedBox(height: 24),

                // Session Controls
                const SessionControls(),
                const SizedBox(height: 24),
                const SizedBox(height: 24),

                // Quick Stats
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Today\'s Patients',
                        value: '12',
                        icon: Ionicons.people,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending Resources',
                        value: '3',
                        icon: Ionicons.business,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
            color: _getAppointmentStatusColor(appointment.status),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceItem(Resource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1565C0),
          child: Icon(Icons.business, color: Colors.white),
        ),
        title: Text('${resource.name} (${resource.company})'),
        subtitle: Text(
          '${resource.contactPerson} • ${resource.scheduledDate.toString().split(' ')[0]}',
        ),
        trailing: Chip(
          label: Text(
            resource.isApproved ? 'Approved' : 'Pending',
            style: TextStyle(
              color: resource.isApproved ? Colors.green : Colors.orange,
            ),
          ),
          backgroundColor: resource.isApproved
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
      ),
    );
  }

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.grey;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.green;
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}