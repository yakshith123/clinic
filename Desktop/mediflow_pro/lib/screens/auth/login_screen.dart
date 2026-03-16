import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart'; // Import AuthService for Google Sign-In
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../screens/doctor/doctor_dashboard_screen.dart';
import '../../screens/patient/qr_registration_screen.dart';
import 'package:pinput/pinput.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); // User enters only 10 digits
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _showOtpInput = false;
  String _loginMethod = 'email'; // 'email', 'phone'
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        email: _emailController.text.trim(), 
        password: _passwordController.text
      );
      
      // Only proceed with navigation if the widget is still mounted
      if (!mounted) return;
      
      if (authProvider.currentUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          switch (authProvider.currentUser!.role) {
            case UserRole.doctor:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
            case UserRole.patient:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const QRRegistrationScreen()),
              );
            default:
              // Default to doctor dashboard for unknown roles
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
          }
        });
      } else if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NEW: Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      // Only proceed with navigation if the widget is still mounted
      if (!mounted) return;
      
      if (authProvider.errorMessage == null && authProvider.currentUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          switch (authProvider.currentUser!.role) {
            case UserRole.doctor:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
            case UserRole.patient:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const QRRegistrationScreen()),
              );
            default:
              // Default to doctor dashboard for unknown roles
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
          }
        });
      } else if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTPAndLogin() async {
    if (_otpController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add +91 prefix if not present
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+91')) {
        phoneNumber = '+91$phoneNumber';
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.verifyOTP(phoneNumber, _otpController.text.trim());

      if (!mounted) return;
      
      // Check if login was successful
      if (authProvider.errorMessage == null && authProvider.currentUser != null) {
        print('✅ Login successful! User authenticated.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          switch (authProvider.currentUser!.role) {
            case UserRole.doctor:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
            case UserRole.patient:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const QRRegistrationScreen()),
              );
            default:
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const DoctorDashboardScreen()),
              );
          }
        });
      } else {
        // Show error message from auth provider
        final errorMsg = authProvider.errorMessage ?? 'Invalid OTP code';
        print('❌ Verification failed: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Verify OTP error: $e');
      String errorMsg = 'Verification failed. Please try again.';
      
      // Extract meaningful error message from exception
      String errorStr = e.toString();
      
      // Check for specific error types
      if (errorStr.contains('Phone number not registered') || 
          errorStr.contains('not registered')) {
        errorMsg = '📝 Phone number not registered.\n\nPlease create an account first by signing up with your details.';
      } else if (errorStr.contains('Invalid OTP')) {
        errorMsg = '🔢 Invalid OTP code.\n\nPlease check and enter the correct OTP.';
      } else if (errorStr.contains('Too many failed attempts')) {
        errorMsg = '⚠️ Too many failed attempts.\n\nPlease request a new OTP.';
      } else if (errorStr.contains('403')) {
        // Backend returned forbidden - likely not registered
        errorMsg = '📝 Phone number not registered.\n\nPlease create an account first by signing up.';
      } else if (errorStr.contains('400')) {
        // Bad request - invalid OTP or other issue
        errorMsg = '❌ Verification failed.\n\n${errorStr.replaceAll("Exception: ", "")}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: errorMsg.contains('not registered') ? 'Sign Up' : 'Retry',
              textColor: Colors.white,
              onPressed: () {
                if (errorMsg.contains('not registered')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                } else {
                  // Retry - clear OTP field
                  _otpController.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle phone number login with OTP
  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a phone number'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Add +91 prefix if not present
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+91')) {
        phoneNumber = '+91$phoneNumber';
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.requestOTP(phoneNumber);

      if (!mounted) return;
      
      if (authProvider.errorMessage == null) {
        setState(() {
          _showOtpInput = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone number'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  
                  // Login Card - Professional and Compact
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
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              
                              const Text(
                                'Sign in to your account',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Login Method Toggle
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _loginMethod = 'email';
                                            _showOtpInput = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _loginMethod == 'email' ? const Color(0xFF1976D2) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Email',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _loginMethod == 'email' ? Colors.white : Colors.grey[700],
                                              fontWeight: _loginMethod == 'email' ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _loginMethod = 'phone';
                                            _showOtpInput = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _loginMethod == 'phone' ? const Color(0xFF1976D2) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Phone',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _loginMethod == 'phone' ? Colors.white : Colors.grey[700],
                                              fontWeight: _loginMethod == 'phone' ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Conditional input fields based on login method
                              if (_loginMethod == 'email') ...[
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
                                      labelText: 'Email Address',
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
                              ] else ...[
                                // Phone Number Field
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
                                      labelText: 'Phone Number',
                                      prefixText: '+91 ',
                                      prefixIcon: Icon(
                                        Icons.phone,
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
                                        return 'Phone number required';
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

                                const SizedBox(height: 16),

                                // OTP Input Field
                                if (_showOtpInput) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    alignment: Alignment.center,
                                    child: Pinput(
                                      controller: _otpController,
                                      length: 6,
                                      pinContentAlignment: Alignment.center,
                                      defaultPinTheme: PinTheme(
                                        width: 50,
                                        height: 50,
                                        textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                      ),
                                      focusedPinTheme: PinTheme(
                                        width: 55,
                                        height: 55,
                                        textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF1976D2)),
                                        ),
                                      ),
                                      submittedPinTheme: PinTheme(
                                        width: 55,
                                        height: 55,
                                        textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF1976D2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 20),

                              // Login Button - Updated to handle different login methods
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
                                          : _loginMethod == 'email' 
                                              ? _handleLogin 
                                              : (_showOtpInput ? _verifyOTPAndLogin : _handlePhoneLogin),
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
                                          : Text(
                                              _loginMethod == 'email' 
                                                  ? 'Sign In' 
                                                  : (_showOtpInput ? 'Verify OTP' : 'Send OTP'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // NEW: Google Sign-In Button
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return ElevatedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleGoogleSignIn,
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
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.account_circle,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Sign in with Google',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Divider with "OR"
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Sign Up Button - Subtle
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1976D2),
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