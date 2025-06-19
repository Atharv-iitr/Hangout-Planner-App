import 'package:flutter/material.dart';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangout_planner/Pages/otp_page.dart';

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
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      if (widget.isLogin) {
        // Sign in with username and password
        final userCredential = await authService.signInWithUsername(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (userCredential != null) {
          // User successfully signed in with username/password, retrieve phone number
          final userData = await authService.getCurrentUserData();
          final phoneNumber = userData?['phoneNumber'] as String?;

          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            // Verify phone number (send OTP)
            await authService.verifyPhoneNumber(phoneNumber);

            if (!mounted) return;

            // Navigate to OTP page for verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPPage(
                  phoneNumber: phoneNumber,
                  isRegistration: false,
                ),
              ),
            ).then((_) {
              setState(() => _isLoading = false);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number not found for this user.')),
            );
            setState(() => _isLoading = false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong username or password')),
          );
          setState(() => _isLoading = false);
        }
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
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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