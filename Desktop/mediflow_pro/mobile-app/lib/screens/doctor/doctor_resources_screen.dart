import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../services/ad_service.dart';
import '../../models/resource.dart';
import '../../services/queue_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DoctorResourcesScreen extends StatefulWidget {
  final String? selectedClinicId;

  const DoctorResourcesScreen({super.key, this.selectedClinicId});

  @override
  State<DoctorResourcesScreen> createState() => _DoctorResourcesScreenState();
}

class _DoctorResourcesScreenState extends State<DoctorResourcesScreen> {
  List<Resource> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final resources = await QueueService.getResourcesByDoctor(authProvider.currentUser!.id);
        setState(() {
          _resources = resources;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading resources: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadResources,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resource Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage equipment and consultant appointments',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Resource Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddResourceDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Schedule New Resource'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Resource Stats
            const Row(
              children: [
                Expanded(
                  child: _ResourceStatCard(
                    title: 'Pending Approval',
                    count: '3',
                    icon: Ionicons.time,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _ResourceStatCard(
                    title: 'Scheduled Today',
                    count: '2',
                    icon: Ionicons.calendar,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _ResourceStatCard(
                    title: 'Completed',
                    count: '15',
                    icon: Ionicons.checkmark_done,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _ResourceStatCard(
                    title: 'Total Resources',
                    count: '28',
                    icon: Ionicons.business,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Resource List
            const Text(
              'Upcoming Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _ResourceList(
              selectedClinicId: widget.selectedClinicId,
              resources: _resources,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Schedule New Resource'),
          content: _AddResourceForm(
            selectedClinicId: widget.selectedClinicId,
            onResourceAdded: () {
              _loadResources();
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _ResourceList extends StatelessWidget {
  final String? selectedClinicId;
  final List<Resource> resources;
  final bool isLoading;

  const _ResourceList({
    this.selectedClinicId,
    required this.resources,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (resources.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No resources scheduled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Schedule resources to manage equipment and consultants',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Filter resources based on selected clinic
    List<Resource> filteredResources = resources;
    if (selectedClinicId != null) {
      filteredResources = resources.where((resource) => resource.hospitalId == selectedClinicId).toList();
    }

    // Create a list with alternating resources and ads
    List<Widget> items = [];
    for (int i = 0; i < filteredResources.length; i++) {
      items.add(_buildResourceCard(context, filteredResources[i]));
      
      // Add an ad every 3 resources
      if ((i + 1) % 3 == 0 && i < filteredResources.length - 1) {
        items.add(AdService.buildBannerAd());
      }
    }

    return Column(
      children: items,
    );
  }

  Widget _buildResourceCard(BuildContext context, Resource resource) {
    Color statusColor = resource.isApproved 
        ? Colors.green 
        : Colors.orange;
    IconData typeIcon = resource.type == ResourceType.equipment
        ? Icons.precision_manufacturing
        : resource.type == ResourceType.staff
            ? Icons.person
            : Icons.local_pharmacy;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          '${resource.name} (${resource.company})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Scheduled: ${resource.timeSlot}'),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(typeIcon, color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200), // Limit height to prevent overflow
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResourceInfo(Icons.person, 'Contact: ${resource.contactPerson}'),
                    const SizedBox(height: 8),
                    _buildResourceInfo(Icons.phone, 'Phone: ${resource.contactPhone}'),
                    const SizedBox(height: 8),
                    _buildResourceInfo(Icons.email, 'Email: ${resource.contactEmail}'),
                    const SizedBox(height: 12),
                    _buildResourceInfo(Icons.calendar_today, 'Date: ${resource.scheduledDate.toString().substring(0, 10)}'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Chip(
                          label: Text(resource.isApproved ? 'Approved' : 'Pending'),
                          backgroundColor: resource.isApproved 
                              ? Colors.green[100] 
                              : Colors.orange[100],
                          labelStyle: TextStyle(
                            color: resource.isApproved 
                                ? Colors.green[800] 
                                : Colors.orange[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(resource.type.toString().split('.').last),
                          backgroundColor: Colors.blue[100],
                          labelStyle: TextStyle(color: Colors.blue[800]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!resource.isApproved)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveResource(context, resource.id),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _startResource(context, resource),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rescheduleResource(context, resource),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reschedule'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _rescheduleResource(BuildContext context, Resource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Resource'),
        content: _RescheduleResourceForm(
          resource: resource,
          onRescheduled: () {
            // Refresh the resource list
            Navigator.pop(context);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startResource(BuildContext context, Resource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Resource'),
        content: Text('Are you sure you want to start "${resource.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate starting the resource
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource started successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _approveResource(BuildContext context, String resourceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Resource'),
        content: Text('Are you sure you want to approve this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate approving the resource
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resource approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

class _ResourceStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _ResourceStatCard({
    required this.title,
    required this.count,
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
              count,
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

class _AddResourceForm extends StatefulWidget {
  final String? selectedClinicId;
  final VoidCallback onResourceAdded;

  const _AddResourceForm({
    this.selectedClinicId,
    required this.onResourceAdded,
  });

  @override
  State<_AddResourceForm> createState() => _AddResourceFormState();
}

class _AddResourceFormState extends State<_AddResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedType = 'Equipment';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _timeSlot = '';

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser == null) {
          return;
        }

        // Create the time slot string
        final hour = _selectedTime.hour.toString().padLeft(2, '0');
        final minute = _selectedTime.minute.toString().padLeft(2, '0');
        _timeSlot = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} $hour:$minute';

        // Create resource
        final resource = await QueueService.createResource(
          name: _nameController.text,
          company: _companyController.text,
          contactPerson: _contactController.text,
          contactPhone: _phoneController.text,
          contactEmail: _emailController.text,
          type: _selectedType == 'Equipment' 
              ? ResourceType.equipment 
              : _selectedType == 'Staff' 
                  ? ResourceType.staff 
                  : ResourceType.medication,
          doctorId: authProvider.currentUser!.id,
          hospitalId: widget.selectedClinicId ?? authProvider.currentUser!.hospitalId ?? '',
          scheduledDate: _selectedDate,
          timeSlot: _timeSlot,
        );

        // Success
        widget.onResourceAdded();
      } catch (e) {
        print('Error creating resource: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating resource: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Resource Name',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter resource name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Resource Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
                DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                DropdownMenuItem(value: 'Medication', child: Text('Medication')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company/Organization',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact person';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Schedule Resource'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RescheduleResourceForm extends StatefulWidget {
  final Resource resource;
  final VoidCallback onRescheduled;

  const _RescheduleResourceForm({
    required this.resource,
    required this.onRescheduled,
  });

  @override
  State<_RescheduleResourceForm> createState() => _RescheduleResourceFormState();
}

class _RescheduleResourceFormState extends State<_RescheduleResourceForm> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    // Parse the current date and time from the resource's timeSlot
    _selectedDate = widget.resource.scheduledDate;
    // Extract time from timeSlot - assuming format is "DD/MM/YYYY HH:MM"
    final timePart = widget.resource.timeSlot.split(' ').last;
    final timeComponents = timePart.split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(timeComponents[0]) ?? 0,
      minute: int.tryParse(timeComponents[1]) ?? 0,
    );
  }

  Future<void> _rescheduleResource() async {
    try {
      // Update resource with new date/time
      // In a real implementation, you would call the API to update the resource
      widget.onRescheduled();
    } catch (e) {
      print('Error rescheduling resource: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling resource: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Reschedule Resource',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ListTile(
            title: const Text('New Date'),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          
          ListTile(
            title: const Text('New Time'),
            subtitle: Text(_selectedTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _rescheduleResource,
                child: const Text('Reschedule'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}