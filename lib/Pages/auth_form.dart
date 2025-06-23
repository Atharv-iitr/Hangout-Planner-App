import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangout_planner/Pages/auth.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  const AuthForm({super.key, required this.isLogin});

  @override
  AuthFormState createState() => AuthFormState();
}

class AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  String? _generatedOtp;
  bool _otpSent = false;
  Map<String, dynamic>? _pendingUserData;

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      if (widget.isLogin) {
        final userData = await authService.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (userData != null) {
          _generatedOtp = _generateOtp();
          debugPrint('OTP for login: $_generatedOtp');

          setState(() {
            _otpSent = true;
            _pendingUserData = userData;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong username or password')),
          );
        }
      } else {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();

        _generatedOtp = _generateOtp();
        debugPrint('OTP for registration: $_generatedOtp');

        setState(() {
          _otpSent = true;
          _pendingUserData = {
            'username': username,
            'password': password,
            'name': name,
            'phoneNumber': phone,
          };
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndProceed() async {
    if (_otpController.text.trim() == _generatedOtp) {
      final authService = AuthService();

      try {
        if (widget.isLogin) {
          await authService.signInWithEmailAndPassword(
            _pendingUserData!['email'],
            _pendingUserData!['password'],
          );
        } else {
          await authService.registerWithUsername(
            _pendingUserData!['username'],
            _pendingUserData!['password'],
            _pendingUserData!['name'],
            _pendingUserData!['phoneNumber'],
          );
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isLogin ? 'Login failed after OTP.' : 'Registration failed after OTP.',
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP.')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neonColor = Colors.cyanAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.isLogin ? 'SIGN IN' : 'SIGN UP',
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _otpSent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🔐 Enter the 6-digit OTP (check terminal)',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildNeonInputField(
                      controller: _otpController,
                      label: 'OTP',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 20),
                    _buildNeonButton(
                      text: 'Verify OTP',
                      onPressed: _isLoading ? null : _verifyOtpAndProceed,
                      loading: _isLoading,
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!widget.isLogin) ...[
                        _buildNeonInputField(
                          controller: _nameController,
                          label: 'Name',
                        ),
                        const SizedBox(height: 16),
                        _buildNeonInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildNeonInputField(
                        controller: _usernameController,
                        label: 'Username',
                      ),
                      const SizedBox(height: 16),
                      _buildNeonInputField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      _buildNeonButton(
                        text: widget.isLogin ? 'Sign In' : 'Sign Up',
                        onPressed: _isLoading ? null : _submit,
                        loading: _isLoading,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNeonInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.cyanAccent),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.purpleAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '⚠️ $label is required';
        }
        if (label == 'Username' && value.contains(' ')) {
          return '⚠️ No spaces allowed in username';
        }
        if (label == 'Username' && value.length < 4) {
          return '⚠️ Must be at least 4 characters';
        }
        if (label == 'Phone Number' && value.length < 10) {
          return '⚠️ Enter a valid phone number';
        }
        if (label == 'Password' && value.length < 6) {
          return '⚠️ Must be at least 6 characters';
        }
        if (label == 'OTP' && value.length != 6) {
          return '⚠️ OTP must be 6 digits';
        }
        return null;
      },
    );
  }

  Widget _buildNeonButton({
    required String text,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}


