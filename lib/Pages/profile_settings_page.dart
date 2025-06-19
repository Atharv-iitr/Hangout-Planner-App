import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _currentProfileImageUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        _bioController.text = data?['biodata'] as String? ?? '';
        _currentProfileImageUrl = data?['profileImageUrl'] as String?;
        setState(() {});
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return _currentProfileImageUrl;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');
    await storageRef.putFile(_pickedImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final imageUrl = await _uploadImage();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'biodata': _bioController.text.trim(),
          'profileImageUrl': imageUrl,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonPurple = Color(0xFF9D00FF);
    const neonBlue = Color(0xFF00FFFF);
    const neonPink = Color(0xFFFF00D6);
    const darkBackground = Color(0xFF0D0D0D);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: Colors.black,
        foregroundColor: neonPink,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonPink.withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[900],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                              ? NetworkImage(_currentProfileImageUrl!) as ImageProvider
                              : null),
                      child: (_pickedImage == null && (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty))
                          ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: neonBlue,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to change profile picture',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _bioController,
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Biodata (Tell us about yourself)',
                    labelStyle: const TextStyle(color: neonPink),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: neonBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: neonPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: neonBlue, width: 2),
                    ),
                    hintText: 'e.g., "Passionate about tech, loves hiking, and enjoys coffee."',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some biodata';
                    }
                    if (value.length < 20) {
                      return 'Biodata must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: neonPurple,
                    foregroundColor: Colors.white,
                    shadowColor: neonPurple,
                    elevation: 10,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
