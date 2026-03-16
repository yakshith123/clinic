import 'package:flutter/material.dart';

class HospitalManagement extends StatelessWidget {
  const HospitalManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hospital Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Add Hospital Button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Show add hospital dialog
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Hospital'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          
          // Hospital List
          const Text(
            'Registered Hospitals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              final hospitals = [
                {
                  'name': 'City General Hospital',
                  'location': 'Downtown, Medical District',
                  'doctors': 45,
                  'patients': 1200,
                },
                {
                  'name': 'Metropolitan Medical Center',
                  'location': 'Westside, Healthcare Plaza',
                  'doctors': 32,
                  'patients': 890,
                },
                {
                  'name': 'Community Health Center',
                  'location': 'East End, Wellness Street',
                  'doctors': 18,
                  'patients': 650,
                },
              ];
              
              final hospital = hospitals[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.local_hospital, color: Colors.white),
                  ),
                  title: Text(hospital['name'] as String),
                  subtitle: Text(hospital['location'] as String),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text('${hospital['doctors']} doctors'),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${hospital['patients']} patients'),
                        backgroundColor: Colors.green.withOpacity(0.2),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Show hospital details
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}