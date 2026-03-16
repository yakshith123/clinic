import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/queue_service.dart';
import '../auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // User enters only 10 digits
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  List<String> _selectedClinicIds = [];
  String? _selectedDepartment;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingClinics = true;
  List<Map<String, dynamic>> _clinics = [];

  @override
  void initState() {
    super.initState();
    _loadClinics();  // Changed to load clinics
  }

  Future<void> _loadClinics() async {
    setState(() {
      _isLoadingClinics = true;
    });
    try {
      print('\n🔄 Loading clinics from Firebase Firestore via backend API...');
      final clinics = await QueueService.getAllClinics();
      _clinics = clinics.map((clinic) => {
        'id': clinic.id,
        'name': clinic.name,
      }).toList();
      
      print('\n✅ Loaded ${_clinics.length} clinics from Firebase:');
      for (var clinic in _clinics) {
        print('   • ${clinic['name']} (ID: ${clinic['id']})');
      }
      print('');
      
      if (_clinics.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ No clinics found in Firebase. Please add clinics from the web app.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadClinics(),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading clinics from Firebase: $e');
      _clinics = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load clinics from Firebase: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadClinics(),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingClinics = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // For doctors, use the first selected clinic ID as the primary and save all selected as associated
      
      // Try to create account via backend first, fall back to local if that fails
      bool success = false;
      try {
        // Add +91 prefix if not present
        String phoneNumber = _phoneController.text.trim();
        if (!phoneNumber.startsWith('+91')) {
          phoneNumber = '+91$phoneNumber';
        }
        
        await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: phoneNumber,
          role: UserRole.doctor,  // Always doctor
          hospitalId: _selectedClinicIds.isNotEmpty ? _selectedClinicIds[0] : null,
          associatedClinicIds: _selectedClinicIds.isNotEmpty ? List.from(_selectedClinicIds) : null,
          department: _selectedDepartment,
        );

        if (authProvider.errorMessage == null && authProvider.currentUser != null) {
          success = true;
        }
      } catch (e) {
        print('Backend signup failed: $e');
        
        // Show detailed error message
        String errorMsg = 'Registration failed. Please try again.';
        String errorStr = e.toString();
        
        if (errorStr.contains('already exists') || errorStr.contains('Already registered')) {
          errorMsg = '📧 Email already registered!\n\nPlease login with your existing account or use a different email.';
        } else if (errorStr.contains('403')) {
          errorMsg = '⚠️ Registration not allowed.\n\nThis phone number is already registered.';
        } else if (errorStr.contains('400')) {
          errorMsg = '❌ Invalid details.\n\nPlease check your information and try again.';
        } else if (errorStr.contains('Connection refused') || errorStr.contains('SocketException')) {
          errorMsg = '🌐 Network error.\n\nPlease check your internet connection.';
        } else {
          errorMsg = '❌ ${errorStr.replaceAll("Exception: ", "")}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: errorMsg.contains('login') ? 'Login' : 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  if (errorMsg.contains('login')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  } else {
                    // Retry - just close the snackbar
                  }
                },
              ),
            ),
          );
        }
        return;
      }

      // If backend signup failed, skip local account creation for now
      if (!success) {
        success = false;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Welcome to Clinikx.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to trigger AuthWrapper
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
        
      } else if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      

    }
  }

  // Method to show clinic selection dialog for multiple selection
  Future<void> _selectClinics() async {
    List<String> selected = List.from(_selectedClinicIds);
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Clinics'),
              content: _isLoadingClinics
                  ? const Text('Loading clinics from backend...')
                  : _clinics.isEmpty
                      ? SizedBox(
                          height: 100,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No clinics available.\nPlease contact admin to add clinics.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = _clinics[index];
                              bool isSelected = selected.contains(clinic['id']);
                              
                              return CheckboxListTile(
                                title: Text(clinic['name']),
                                subtitle: Text(
                                  'ID: ${clinic['id']}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                value: isSelected,
                                activeColor: const Color(0xFF1976D2),
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selected.add(clinic['id']);
                                    } else {
                                      selected.remove(clinic['id']);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedClinicIds = selected;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildClinicSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Clinics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              _selectedClinicIds.isEmpty
                  ? 'Tap to select clinics...'
                  : '${_selectedClinicIds.length} clinic(s) selected',
              style: TextStyle(
                color: _selectedClinicIds.isEmpty ? Colors.grey : Colors.black,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isLoadingClinics ? null : _selectClinics,
          ),
        ),
        if (_selectedClinicIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedClinicIds.map((clinicId) {
                final clinic = _clinics.firstWhere(
                  (c) => c['id'] == clinicId,
                  orElse: () => <String, String>{'id': clinicId, 'name': 'Unknown Clinic'}, // Explicitly define the map type
                );
                return Chip(
                  label: Text(clinic['name']?.toString() ?? 'Unknown Clinic'),
                  backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                  deleteIconColor: const Color(0xFF2E7D32),
                  onDeleted: () {
                    setState(() {
                      _selectedClinicIds.remove(clinicId);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        if (_isLoadingClinics)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: const Text(
                      'Clinikx',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  Card(
                    elevation: 15,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Name Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(14),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Name required';
                                    }
                                    if (value.length < 2) {
                                      return '2+ characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(14),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 15),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email required';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Phone Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    prefixText: '+91 ',
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(14),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Phone required';
                                    }
                                    // Remove any spaces or special characters
                                    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                    if (cleanValue.length < 10) {
                                      return 'Enter valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Clinic Selection
                              _buildClinicSelection(),
                              const SizedBox(height: 16),
                              
                              // Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(14),
                                    isDense: true,
                                  ),
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password required';
                                    }
                                    if (value.length < 6) {
                                      return '6+ characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Confirm Password Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(14),
                                    isDense: true,
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  style: const TextStyle(fontSize: 15),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirm password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords mismatch';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Signup Button
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0D47A1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return ElevatedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleSignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  "Already have an account? Sign in",
                                  style: TextStyle(
                                    color: Color(0xFF1976D2),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
























