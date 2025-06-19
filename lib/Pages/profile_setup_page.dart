import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupPage extends StatefulWidget {
  final String username;
  final String password;
  final String name;
  final String phoneNumber;

  const ProfileSetupPage({
    Key? key,
    required this.username,
    required this.password,
    required this.name,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _pickedImage;
  final TextEditingController _biodataController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImageFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });
    }
  }

  Future<void> _submitProfileSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? photoURL;
      if (_pickedImage != null) {
        // Upload image to Firebase Storage
        photoURL = await _authService.uploadProfilePicture(
            _pickedImage!, FirebaseAuth.instance.currentUser!.uid);
      }

      await _authService.registerWithUsername(
        widget.username,
        widget.password,
        widget.name,
        widget.phoneNumber,
        photoURL,
        _biodataController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Profile setup failed')),
      );
    } catch (e) {
      debugPrint('Error during profile setup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred during profile setup.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _biodataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!) as ImageProvider
                      : null,
                  child: _pickedImage == null
                      ? Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.grey.shade800,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _biodataController,
                decoration: const InputDecoration(
                  labelText: 'Tell us about yourself (Biodata)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitProfileSetup,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Complete Registration'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}