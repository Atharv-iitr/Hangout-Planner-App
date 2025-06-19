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
      title: const Text("Remove Plan"),
      content: Text(
        isCreator
          ? "You're the creator. Do you want to delete this plan for everyone?"
          : "Do you want to leave this plan?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);

            try {
              if (isCreator) {
                // 🔥 Delete the entire plan
                await FirebaseFirestore.instance.collection('plans').doc(plan.id).delete();
              } else {
                // ➖ Remove current user from acceptedBy
                await FirebaseFirestore.instance.collection('plans').doc(plan.id).update({
                  'acceptedBy': FieldValue.arrayRemove([uid])
                });
              }

              // 🧹 Refresh UI
              await _loadPlans();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isCreator ? "Plan deleted." : "You left the plan."))
                );
              }
            } catch (e) {
              debugPrint("Error removing plan: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error removing plan."))
                );
              }
            }
          },
          child: const Text("Yes", style: TextStyle(color: Colors.red)),
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

      // Merge and remove duplicates by ID
      final all = {
        for (var doc in [...created.docs, ...accepted.docs]) doc.id: doc
      }.values.toList();

      // Sort by timestamp descending
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
    trailing: IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
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
      appBar: AppBar(title: const Text("Plan Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('plans').doc(planId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final acceptedUids = data['acceptedBy'] ?? [];

          return FutureBuilder<List<String>>(
            future: _getUsernames(acceptedUids),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

              final usernames = userSnap.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Title:", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    Text("Description:", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description),
                    const SizedBox(height: 20),
                    Text("People Joining:", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Expanded(
                      child: usernames.isEmpty
                          ? const Text("No one has joined this plan yet.")
                          : ListView.builder(
                              itemCount: usernames.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(usernames[index]),
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
