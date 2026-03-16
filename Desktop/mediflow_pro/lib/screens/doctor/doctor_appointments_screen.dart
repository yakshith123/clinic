import 'package:flutter/material.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          
          // Filter Tabs
          _AppointmentFilterTabs(),
          SizedBox(height: 24),
          
          // Appointment List
          _AppointmentList(),
        ],
      ),
    );
  }
}

class _AppointmentFilterTabs extends StatelessWidget {
  const _AppointmentFilterTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterTab(
              title: 'Today',
              isSelected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _FilterTab(
              title: 'Upcoming',
              isSelected: false,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _FilterTab(
              title: 'History',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList();

  @override
  Widget build(BuildContext context) {
    final appointments = [
      {
        'patient': 'John Smith',
        'time': '09:00 AM',
        'reason': 'Routine Checkup',
        'status': 'Confirmed',
        'emergency': false,
      },
      {
        'patient': 'Mary Johnson',
        'time': '10:30 AM',
        'reason': 'Follow-up Consultation',
        'status': 'In Progress',
        'emergency': false,
      },
      {
        'patient': 'Robert Davis',
        'time': '02:00 PM',
        'reason': 'Chest Pain',
        'status': 'Emergency',
        'emergency': true,
      },
      {
        'patient': 'Lisa Wilson',
        'time': '03:30 PM',
        'reason': 'Annual Physical',
        'status': 'Pending',
        'emergency': false,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        Color statusColor;
        IconData statusIcon;
        
        switch (appointment['status']) {
          case 'Confirmed':
            statusColor = Colors.blue;
            statusIcon = Icons.check_circle;
            break;
          case 'In Progress':
            statusColor = Colors.purple;
            statusIcon = Icons.access_time;
            break;
          case 'Emergency':
            statusColor = Colors.red;
            statusIcon = Icons.warning;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(appointment['patient'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${appointment['time']} • ${appointment['reason']}'),
                if (appointment['emergency'] as bool)
                  const Chip(
                    label: Text('Emergency'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                Text(
                  appointment['status'] as String,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Show appointment details
            },
          ),
        );
      },
    );
  }
}