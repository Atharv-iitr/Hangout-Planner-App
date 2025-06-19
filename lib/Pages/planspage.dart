import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<DocumentSnapshot> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    try {
      final created = await FirebaseFirestore.instance
          .collection('plans')
          .where('fromUid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      final accepted = await FirebaseFirestore.instance
          .collection('plans')
          .where('acceptedBy', arrayContains: uid)
          .orderBy('timestamp', descending: true)
          .get();

      final all = {
  for (var doc in [...created.docs, ...accepted.docs]) doc.id: doc
}.values.toList();

// 🔁 Sort by timestamp descending
all.sort((a, b) {
  final tsA = a['timestamp'] as Timestamp?;
  final tsB = b['timestamp'] as Timestamp?;
  if (tsA == null && tsB == null) return 0;
  if (tsA == null) return 1;
  if (tsB == null) return -1;
  return tsB.compareTo(tsA);
});

      setState(() {
        _plans = all;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching plans: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Plans"),
        backgroundColor: const Color(0xFF1C1B33),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(child: Text("No plans yet."))
              : ListView.builder(
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final title = plan['title'] ?? 'Untitled';
                    final description = plan['description'] ?? 'No description';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: Text(title),
                                content: Text(description),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
