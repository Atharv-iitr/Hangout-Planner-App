import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hangout_planner/Pages/home.dart';

class ProfileSetupPage extends StatefulWidget {
  final String uid;

  const ProfileSetupPage({super.key, required this.uid});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _profileImageUrl;
  void _pickImage() {
   
    setState(() {
      _profileImageUrl =
          'https://via.placeholder.com/150';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dummy image set (actual upload not implemented).')),
      );
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'biodata': _bioController.text.trim(),
        'profileImageUrl': _profileImageUrl,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        automaticallyImplyLeading: false,
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
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap to add profile picture',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _bioController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Biodata (Tell us about yourself)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    hintText: 'e.g., "Passionate about tech, loves hiking, and enjoys coffee."',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some biodata';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}