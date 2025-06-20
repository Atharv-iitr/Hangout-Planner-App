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

  void _confirmDelete(BuildContext context, DocumentSnapshot plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final fromUid = plan['fromUid'];
    final isCreator = fromUid == uid;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1B33),
        title: const Text("Remove Plan", style: TextStyle(color: Colors.white)),
        content: Text(
          isCreator
              ? "You're the creator. Do you want to delete this plan for everyone?"
              : "Do you want to leave this plan?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (isCreator) {
                  await FirebaseFirestore.instance.collection('plans').doc(plan.id).delete();
                } else {
                  await FirebaseFirestore.instance.collection('plans').doc(plan.id).update({
                    'acceptedBy': FieldValue.arrayRemove([uid])
                  });
                }
                await _loadPlans();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isCreator ? "Plan deleted." : "You left the plan."),
                    backgroundColor: const Color(0xFF0B082D),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Error removing plan."),
                    backgroundColor: Colors.redAccent,
                  ));
                }
              }
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFF0B082D),
      appBar: AppBar(
        title: const Text("My Plans", style: TextStyle(color: Color(0xFF00F2FF))),
        backgroundColor: const Color(0xFF0B082D),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00F2FF)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)))
          : _plans.isEmpty
              ? const Center(child: Text("No plans yet.", style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final title = plan['title'] ?? 'Untitled';
                    final description = plan['description'] ?? 'No description';

                    return Card(
                      color: const Color(0xFF1C1B33),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(title,
                            style: const TextStyle(color: Color(0xFF00F2FF), fontWeight: FontWeight.bold)),
                        subtitle: Text(description,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, plan),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlanDetailsPage(
                                planId: plan.id,
                                title: title,
                                description: description,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class PlanDetailsPage extends StatelessWidget {
  final String planId;
  final String title;
  final String description;

  const PlanDetailsPage({
    super.key,
    required this.planId,
    required this.title,
    required this.description,
  });

  Future<List<String>> _getUsernames(List<dynamic> uids) async {
    List<String> usernames = [];
    for (final uid in uids) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      usernames.add(doc.data()?['username'] ?? 'Unknown');
    }
    return usernames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B082D),
      appBar: AppBar(
        title: const Text("Plan Details", style: TextStyle(color: Color(0xFF00F2FF))),
        backgroundColor: const Color(0xFF0B082D),
        iconTheme: const IconThemeData(color: Color(0xFF00F2FF)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('plans').doc(planId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final acceptedUids = data['acceptedBy'] ?? [];

          return FutureBuilder<List<String>>(
            future: _getUsernames(acceptedUids),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)));

              final usernames = userSnap.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Title:", style: TextStyle(color: neonCyan, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    const Text("Description:", style: TextStyle(color: neonCyan, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
                    const Text("People Joining:", style: TextStyle(color: neonCyan, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: usernames.isEmpty
                          ? const Text("No one has joined this plan yet.", style: TextStyle(color: Colors.white70))
                          : ListView.builder(
                              itemCount: usernames.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: const Icon(Icons.person, color: neonCyan),
                                title: Text(usernames[index], style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Neon color constant used in both classes
const neonCyan = Color(0xFF00F2FF);
