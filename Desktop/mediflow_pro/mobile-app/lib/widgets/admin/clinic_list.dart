import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class ClinicManagement extends StatefulWidget {
  const ClinicManagement({super.key});

  @override
  State<ClinicManagement> createState() => _ClinicManagementState();
}

class _ClinicManagementState extends State<ClinicManagement> {
  final List<Map<String, dynamic>> clinics = [
    {
      'name': 'Green Valley Clinic',
      'location': '123 Main Street, Downtown',
      'doctors': 12,
      'patients': 450,
      'status': 'Active',
    },
    {
      'name': 'Downtown Medical Center',
      'location': '456 Central Ave, City Center',
      'doctors': 8,
      'patients': 320,
      'status': 'Active',
    },
    {
      'name': 'Sunrise Health Clinic',
      'location': '789 Park Road, Suburbia',
      'doctors': 6,
      'patients': 280,
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinic Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddClinicDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Clinic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Clinic List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return _buildClinicCard(context, clinic);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, Map<String, dynamic> clinic) {
    final statusColor = clinic['status'] == 'Active' 
        ? const Color(0xFF2E7D32)
        : const Color(0xFFFFA000);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFF2E7D32).withOpacity(0.03),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: const Icon(
                      Ionicons.business,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clinic['location'] as String,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (String result) {
                      switch (result) {
                        case 'view':
                          _showClinicDetails(context, clinic);
                          break;
                        case 'edit':
                          _showEditClinicDialog(context, clinic);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, clinic);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit Clinic'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete Clinic', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    '${clinic['doctors']} Doctors',
                    Icons.medical_services,
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    '${clinic['patients']} Patients',
                    Icons.people,
                    const Color(0xFFFFA000),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      clinic['status'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
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

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Function to show add clinic dialog
  void _showAddClinicDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Clinic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Clinic Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (nameController.text.isEmpty || 
                    locationController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Close dialog
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text('Adding clinic...'),
                        ],
                      ),
                    );
                  },
                );
                
                try {
                  // TODO: Call the new API endpoint
                  // This would call: POST /api/hospitals/register-with-admin
                  // with the clinic data and admin credentials
                  
                  // For now, simulate the API call with a delay
                  await Future.delayed(const Duration(seconds: 2));
                  
                  // Add clinic to local list (in real app, this would come from API response)
                  setState(() {
                    clinics.add({
                      'name': nameController.text,
                      'location': locationController.text,
                      'doctors': 0,
                      'patients': 0,
                      'status': 'Active',
                      'id': 'clinic_${DateTime.now().millisecondsSinceEpoch}',
                      'email': emailController.text,
                      'phone': phoneController.text,
                    });
                  });
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Clinic "${nameController.text}" added successfully! Admin can login with email: ${emailController.text}'),
                      backgroundColor: const Color(0xFF2E7D32),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding clinic: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Clinic'),
            ),
          ],
        );
      },
    );
  }

  // Function to show clinic details
  void _showClinicDetails(BuildContext context, Map<String, dynamic> clinic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(clinic['name'] as String),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${clinic['location']}'),
              const SizedBox(height: 8),
              Text('Doctors: ${clinic['doctors']}'),
              const SizedBox(height: 8),
              Text('Patients: ${clinic['patients']}'),
              const SizedBox(height: 8),
              Text('Status: ${clinic['status']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show edit clinic dialog
  void _showEditClinicDialog(BuildContext context, Map<String, dynamic> clinic) {
    final nameController = TextEditingController(text: clinic['name'] as String);
    final locationController = TextEditingController(text: clinic['location'] as String);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Clinic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Edit clinic logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clinic updated successfully!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Function to show delete confirmation
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> clinic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Clinic'),
          content: Text('Are you sure you want to delete ${clinic['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete clinic logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clinic deleted successfully!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}