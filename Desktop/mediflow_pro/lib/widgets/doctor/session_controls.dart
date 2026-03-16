import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/queue_provider.dart';

class SessionControls extends StatelessWidget {
  const SessionControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueProvider>(
      builder: (context, queueProvider, child) {
        return Card(
          color: queueProvider.isSessionActive
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Start/Stop Session Button
                    ElevatedButton.icon(
                      onPressed: queueProvider.isSessionActive
                          ? () => _stopSession(context, queueProvider)
                          : () => _startSession(context, queueProvider),
                      icon: Icon(
                        queueProvider.isSessionActive
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        queueProvider.isSessionActive
                            ? 'Stop Session'
                            : 'Start Session',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: queueProvider.isSessionActive
                            ? Colors.red
                            : const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                    
                    if (queueProvider.isSessionActive) ...[
                      const SizedBox(width: 16),
                      // Complete Next Appointment
                      ElevatedButton.icon(
                        onPressed: queueProvider.patientQueue.isNotEmpty
                            ? () => _completeNextAppointment(context, queueProvider)
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (queueProvider.isSessionActive) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SessionInfoItem(
                        label: 'Patients in Queue',
                        value: queueProvider.patientQueue.length.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _SessionInfoItem(
                        label: 'Resources',
                        value: queueProvider.resourceQueue.length.toString(),
                        icon: Icons.business,
                        color: Colors.orange,
                      ),
                      _SessionInfoItem(
                        label: 'Total',
                        value: queueProvider.totalQueueCount.toString(),
                        icon: Icons.list,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startSession(BuildContext context, QueueProvider queueProvider) async {
    await queueProvider.startSession();
    if (queueProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queueProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _stopSession(BuildContext context, QueueProvider queueProvider) async {
    await queueProvider.stopSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _completeNextAppointment(
      BuildContext context, QueueProvider queueProvider) async {
    await queueProvider.completeNextAppointment();
    if (queueProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queueProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment completed! Next patient notified.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _SessionInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SessionInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}