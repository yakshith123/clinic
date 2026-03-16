import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../models/ad.dart';
import '../../models/clinic.dart';
import '../../services/queue_service.dart';
import '../../models/user.dart' as ModelUser;

class AdManagementScreen extends StatefulWidget {
  const AdManagementScreen({super.key});

  @override
  State<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends State<AdManagementScreen> {
  List<Ad> _ads = [];
  bool _isLoading = true;
  String _selectedClinicId = '';
  List<Clinic> _clinics = [];
  bool _isLoadingClinics = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _loadAds();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await QueueService.getAllClinics();
      setState(() {
        _clinics = clinics;
        _isLoadingClinics = false;
        if (clinics.isNotEmpty) {
          _selectedClinicId = clinics.first.id ?? '';
        }
      });
    } catch (e) {
      print('Error loading clinics: $e');
      setState(() {
        _isLoadingClinics = false;
      });
    }
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ads = await AdService.getAds(clinicId: _selectedClinicId.isEmpty ? null : _selectedClinicId);
      setState(() {
        _ads = ads;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading ads: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ads: $e')),
        );
      }
    }
  }

  void _showAddAdDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AdEditorDialog(
          clinicId: _selectedClinicId,
          onAdSaved: () {
            Navigator.pop(context);
            _loadAds();
          },
        );
      },
    );
  }

  void _showEditAdDialog(Ad ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AdEditorDialog(
          ad: ad,
          clinicId: _selectedClinicId,
          onAdSaved: () {
            Navigator.pop(context);
            _loadAds();
          },
        );
      },
    );
  }

  Future<void> _deleteAd(String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Are you sure you want to delete this ad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdService.deleteAd(adId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad deleted successfully'), backgroundColor: Colors.green),
        );
        _loadAds();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting ad: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    
    // Check if user is admin
    if (currentUser?.role != ModelUser.UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Ads'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Admin access required',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Ads'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAds,
          ),
        ],
      ),
      body: Column(
        children: [
          // Clinic selector
          if (!_isLoadingClinics && _clinics.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Clinic: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedClinicId.isEmpty ? null : _selectedClinicId,
                      hint: const Text('All Clinics'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All Clinics')),
                        ..._clinics.map((clinic) => DropdownMenuItem(
                          value: clinic.id,
                          child: Text(clinic.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClinicId = value ?? '';
                        });
                        _loadAds();
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Ads list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAds,
                    child: _ads.isEmpty
                        ? _buildEmptyState()
                        : _buildAdsList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdDialog,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No Ads Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Tap + to create a new ad banner',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ads.length,
      itemBuilder: (context, index) {
        final ad = _ads[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            title: Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Priority: ${ad.priority}'),
                if (ad.clinicId != null) Text('Clinic Specific'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ad.isActive ? Colors.green[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ad.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: ad.isActive ? Colors.green[800] : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditAdDialog(ad);
                } else if (value == 'delete') {
                  _deleteAd(ad.id ?? '');
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AdEditorDialog extends StatefulWidget {
  final Ad? ad;
  final String clinicId;
  final VoidCallback onAdSaved;

  const _AdEditorDialog({this.ad, required this.clinicId, required this.onAdSaved});

  @override
  State<_AdEditorDialog> createState() => _AdEditorDialogState();
}

class _AdEditorDialogState extends State<_AdEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _targetUrlController;
  late TextEditingController _priorityController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad?.title ?? '');
    _imageUrlController = TextEditingController(text: widget.ad?.imageUrl ?? '');
    _targetUrlController = TextEditingController(text: widget.ad?.targetUrl ?? '');
    _priorityController = TextEditingController(text: widget.ad?.priority.toString() ?? '0');
    _isActive = widget.ad?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final ad = Ad(
        id: widget.ad?.id,
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        targetUrl: _targetUrlController.text.trim().isEmpty ? null : _targetUrlController.text.trim(),
        priority: int.tryParse(_priorityController.text) ?? 0,
        isActive: _isActive,
        clinicId: widget.clinicId.isEmpty ? null : widget.clinicId,
      );

      if (widget.ad == null) {
        await AdService.createAd(ad);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad created successfully'), backgroundColor: Colors.green),
        );
      } else {
        await AdService.updateAd(widget.ad!.id!, ad);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad updated successfully'), backgroundColor: Colors.green),
        );
      }

      widget.onAdSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving ad: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ad == null ? 'Create Ad' : 'Edit Ad'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Ad Title'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an image URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetUrlController,
                decoration: const InputDecoration(labelText: 'Target URL (Optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(labelText: 'Priority'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAd,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Save'),
        ),
      ],
    );
  }
}
