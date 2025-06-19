import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'first_deg.dart'; // 🔄 Make sure this import points to your FirstDeg file

class MakePlan extends StatefulWidget {
  const MakePlan({super.key});

  @override
  State<MakePlan> createState() => _MakePlanState();
}

class _MakePlanState extends State<MakePlan> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Make Your Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your plan...',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.edit),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(18),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            hintText: "Enter the plan's description...",
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.description),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(18),
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 350,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 160,
                  height: 55,
                  child: FloatingActionButton.extended(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: Colors.black,
                    elevation: 6,
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      final desc = _descController.text.trim();

                      if (title.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter both title and description')),
                        );
                        return;
                      }

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You must be logged in to create a plan')),
                        );
                        return;
                      }

                      // 🔥 Create plan in Firestore
                      await FirebaseFirestore.instance.collection('plans').add({
                        'title': title,
                        'description': desc,
                        'fromUid': user.uid,
                        'acceptedBy': [user.uid],
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      // ✅ Navigate to FirstDeg with data
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FirstDeg(
                            planTitle: title,
                            planDesc: desc,
                          ),
                        ),
                      );
                    },
                    label: const Text(
                      'Next',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
