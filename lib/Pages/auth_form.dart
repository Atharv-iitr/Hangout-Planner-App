import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Generate a random 6-digit OTP
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
        // LOGIN FLOW
        final userData = await authService.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!mounted) return;

        if (userData != null) {
          // Generate and print OTP
          _generatedOtp = _generateOtp();
          debugPrint('OTP for login: $_generatedOtp');
          // print('OTP for login: $_generatedOtp');
          setState(() {
            _otpSent = true;
            _pendingUserData = userData;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wrong username or password'),
            ),
          );
        }
      } else {
        // REGISTER FLOW
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();

        // Generate and print OTP
        _generatedOtp = _generateOtp();
        debugPrint('OTP for registration: $_generatedOtp');
        // print('OTP for registration: $_generatedOtp');
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
      if (widget.isLogin) {
        // Login: sign in with email and password
        final authService = AuthService();
        try {
          await authService.signInWithEmailAndPassword(
            _pendingUserData!['email'],
            _pendingUserData!['password'],
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed after OTP.')),
          );
        }
      } else {
        // Register: create user
        final authService = AuthService();
        try {
          await authService.registerWithUsername(
            _pendingUserData!['username'],
            _pendingUserData!['password'],
            _pendingUserData!['name'],
            _pendingUserData!['phoneNumber'],
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed after OTP.')),
          );
        }
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.isLogin ? 'Sign In' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _otpSent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter the 6-digit OTP (check terminal/output)',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtpAndProceed,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Verify OTP'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!widget.isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        if (value.length < 4) {
                          return 'Username must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(widget.isLogin ? 'Sign In' : 'Sign Up'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
