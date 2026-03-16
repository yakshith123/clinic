import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<Map<String, dynamic>> doctors = [
    {
      'name': 'Dr. Sarah Johnson',
      'email': 'sarah.johnson@clinic.com',
      'specialty': 'Cardiology',
      'clinic': 'Green Valley Clinic',
      'status': 'Active',
      'phone': '+1234567890',
      'department': 'Cardiology',
    },
    {
      'name': 'Dr. Emily Rodriguez',
      'email': 'emily.rodriguez@clinic.com',
      'specialty': 'Pediatrics',
      'clinic': 'Downtown Medical',
      'status': 'Active',
      'phone': '+1234567891',
      'department': 'Pediatrics',
    },
    {
      'name': 'Dr. Robert Kim',
      'email': 'robert.kim@clinic.com',
      'specialty': 'General Practice',
      'clinic': 'Sunrise Health',
      'status': 'Active',
      'phone': '+1234567892',
      'department': 'General Medicine',
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
                'Doctor Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddDoctorDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
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
          
          // Doctor List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return _buildDoctorCard(context, doctor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    final statusColor = doctor['status'] == 'Active' 
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
              statusColor.withOpacity(0.03),
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
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF1565C0),
                      child: Icon(
                        Ionicons.medical,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor['email'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doctor['specialty']} • ${doctor['clinic']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey,
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
                          _showDoctorDetails(context, doctor);
                          break;
                        case 'edit':
                          _showEditDoctorDialog(context, doctor);
                          break;
                        case 'status':
                          _toggleDoctorStatus(context, doctor);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, doctor);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility, color: Colors.blue),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.green),
                          title: Text('Edit Doctor'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'status',
                        child: ListTile(
                          leading: Icon(Icons.toggle_on, color: Colors.orange),
                          title: Text('Toggle Status'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Doctor'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  doctor['status'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show add doctor dialog with improved UI
  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final specialtyController = TextEditingController();
    final phoneController = TextEditingController();
    final departmentController = TextEditingController();
    String selectedClinic = 'default_hospital';
    
    final clinics = [
      'Green Valley Clinic',
      'Downtown Medical Center', 
      'Sunrise Health Clinic',
      'Central Wellness Center',
      'Riverside Medical',
      'Mountain View Clinic',
      'Harbor Health Center',
      'Pine Medical Clinic'
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.medical_services, color: Color(0xFF1565C0)),
              SizedBox(width: 12),
              Text('Add New Doctor'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      prefixIcon: Icon(Icons.person, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Specialty Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Medical Specialty',
                      prefixIcon: Icon(Icons.local_hospital, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Department Field
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business, color: Color(0xFF1565C0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Clinic Selection Dropdown
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: selectedClinic,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Clinic',
                        prefixIcon: Icon(Icons.business, color: Color(0xFF1565C0)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      items: clinics.map((String clinic) {
                        return DropdownMenuItem<String>(
                          value: clinic.toLowerCase().replaceAll(' ', '_'),
                          child: Text(clinic),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedClinic = newValue;
                        }
                      },
                    ),
                  ),
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
                    emailController.text.isEmpty ||
                    specialtyController.text.isEmpty) {
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
                          Text('Adding doctor...'),
                        ],
                      ),
                    );
                  },
                );
                
                try {
                  // Add doctor to local list (in real app, this would call API)
                  setState(() {
                    doctors.add({
                      'name': nameController.text,
                      'email': emailController.text,
                      'specialty': specialtyController.text,
                      'clinic': clinics.firstWhere(
                        (clinic) => clinic.toLowerCase().replaceAll(' ', '_') == selectedClinic,
                        orElse: () => 'Default Clinic'
                      ),
                      'status': 'Active',
                      'phone': phoneController.text.isEmpty ? '+1234567890' : phoneController.text,
                      'department': departmentController.text.isEmpty ? 'General' : departmentController.text,
                    });
                  });
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Doctor "${nameController.text}" added successfully!'),
                      backgroundColor: const Color(0xFF1565C0),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding doctor: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Add Doctor'),
            ),
          ],
        );
      },
    );
  }

  // Function to toggle doctor status
  void _toggleDoctorStatus(BuildContext context, Map<String, dynamic> doctor) {
    setState(() {
      final currentIndex = doctors.indexOf(doctor);
      doctors[currentIndex] = Map<String, dynamic>.from(doctor);
      doctors[currentIndex]['status'] = doctor['status'] == 'Active' ? 'Inactive' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Doctor status updated to ${doctors.firstWhere((d) => d['email'] == doctor['email'])['status']}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Function to show doctor details
  void _showDoctorDetails(BuildContext context, Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF1565C0)),
              const SizedBox(width: 12),
              Text(doctor['name'] as String),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email:', doctor['email'] as String),
              const SizedBox(height: 8),
              _buildDetailRow('Specialty:', doctor['specialty'] as String),
              const SizedBox(height: 8),
              _buildDetailRow('Clinic:', doctor['clinic'] as String),
              const SizedBox(height: 8),
              _buildDetailRow('Department:', doctor['department'] as String),
              const SizedBox(height: 8),
              _buildDetailRow('Phone:', doctor['phone'] as String),
              const SizedBox(height: 8),
              _buildDetailRow('Status:', doctor['status'] as String),
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

  // Helper function to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  // Function to show edit doctor dialog
  void _showEditDoctorDialog(BuildContext context, Map<String, dynamic> doctor) {
    final nameController = TextEditingController(text: doctor['name'] as String);
    final emailController = TextEditingController(text: doctor['email'] as String);
    final specialtyController = TextEditingController(text: doctor['specialty'] as String);
    final phoneController = TextEditingController(text: doctor['phone'] as String);
    final departmentController = TextEditingController(text: doctor['department'] as String);
    
    // List of available clinics
    final availableClinics = [
      'Green Valley Clinic',
      'Downtown Medical Center', 
      'Sunrise Health Clinic',
      'Central Wellness Center',
      'Riverside Medical',
      'Mountain View Clinic',
      'Harbor Health Center',
      'Pine Medical Clinic'
    ];
    
    String selectedClinic = doctor['clinic'] as String;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.green),
              SizedBox(width: 12),
              Text('Edit Doctor'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Name',
                      prefixIcon: Icon(Icons.person, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Medical Specialty',
                      prefixIcon: Icon(Icons.local_hospital, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
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
              onPressed: () {
                // Update doctor in local list
                setState(() {
                  final currentIndex = doctors.indexOf(doctor);
                  doctors[currentIndex] = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'specialty': specialtyController.text,
                    'clinic': selectedClinic,
                    'status': doctor['status'],
                    'phone': phoneController.text,
                    'department': departmentController.text,
                  };
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doctor updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Function to show delete confirmation
  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete Doctor'),
            ],
          ),
          content: Text('Are you sure you want to delete ${doctor['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Remove doctor from local list
                setState(() {
                  doctors.removeWhere((d) => d['email'] == doctor['email']);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doctor deleted successfully!'),
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