import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../models/appointment.dart';
import '../../providers/queue_provider.dart';

class QueueCard extends StatelessWidget {
  final Appointment appointment;
  final Function(AppointmentStatus) onStatusChange;
  final Function(int) onPositionChange;

  const QueueCard({
    super.key,
    required this.appointment,
    required this.onStatusChange,
    required this.onPositionChange,
  });

  @override
  Widget build(BuildContext context) {
    // Provider.of<QueueProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Dismissible(
        key: Key(appointment.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.check, color: Colors.white, size: 32),
              SizedBox(width: 8),
              Text(
                'Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onStatusChange(AppointmentStatus.completed);
          }
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Complete Appointment'),
                  content: Text('Mark appointment for ${appointment.patientId.substring(0, math.min(appointment.patientId.length, 8))} as completed?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Complete'),
                    ),
                  ],
                );
              },
            ) ?? false;
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient #${appointment.patientId.substring(0, math.min(appointment.patientId.length, 8))}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.reason,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 80,
                      maxWidth: 120,
                    ),
                    child: Text(
                      appointment.status.name.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.business, appointment.department),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.schedule, 
                          '${appointment.appointmentDate.hour}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}'),
                        const SizedBox(height: 8),
                        Text(
                          'Queue #${appointment.queuePosition}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            _buildActionButton(
                              'Confirm',
                              Colors.green,
                              () => onStatusChange(AppointmentStatus.confirmed),
                            ),
                            _buildActionButton(
                              'Start',
                              Colors.orange,
                              () => onStatusChange(AppointmentStatus.inProgress),
                            ),
                            _buildActionButton(
                              'Complete',
                              Colors.blue,
                              () => onStatusChange(AppointmentStatus.completed),
                            ),
                            _buildActionButton(
                              'Cancel',
                              Colors.red,
                              () => onStatusChange(AppointmentStatus.cancelled),
                            ),
                          ],
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
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.grey;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}