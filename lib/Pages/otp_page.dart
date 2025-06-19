import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:hangout_planner/Pages/profile_setup_page.dart';

class OTPPage extends StatefulWidget {
  final String phoneNumber;
  final bool isRegistration;
  final String? username;
  final String? password;
  final String? name;

  const OTPPage({
    Key? key,
    required this.phoneNumber,
    required this.isRegistration,
    this.username,
    this.password,
    this.name,
  }) : super(key: key);

  @override
  State<OTPPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OTPPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.verifyPhoneNumber(widget.phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: ${e.message}')),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _verifyOtp() async {
    final otpCode = _otpController.text.trim();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const testNumbers = ['+919845302237', '+917738296484','+917496047741','+918851178719'];

      String fullPhoneNumber = widget.phoneNumber.startsWith('+') ? widget.phoneNumber : '+91${widget.phoneNumber}';

      if (kDebugMode && testNumbers.contains(fullPhoneNumber)) {
        debugPrint('Test: OTP accepted without Firebase verification');
        if (widget.isRegistration) {
          if (!mounted) return;
          // Navigate to profile setup page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupPage(
                username: widget.username!,
                password: widget.password!,
                name: widget.name!,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          _navigateToHome();
        }
        return;
      }

      final user = await _authService.verifyOTP(otpCode);

      if (!mounted) return;

      if (user != null) {
        debugPrint('Firebase sign-in successful');
        if (widget.isRegistration) {
          // Navigate to profile setup page 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupPage(
                username: widget.username!,
                password: widget.password!,
                name: widget.name!,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          _navigateToHome();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verification failed')),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verification error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'OTP verification failed')),
      );
    } catch (e) {
      debugPrint('Unexpected error during OTP verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('OTP sent to ${widget.phoneNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Verify OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}