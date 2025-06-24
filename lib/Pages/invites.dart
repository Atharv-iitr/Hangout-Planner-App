import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Color theme from the drawer screenshot
const Color drawerBackground = Color(0xFF0B082D);
const Color neonCyan = Color(0xFF00F2FF);
const Color mutedText = Color(0xFFCCCCCC);
const Color gradientStart = Color(0xFF003F7D);
const Color gradientEnd = Color(0xFF00C2FF);

class InvitesPage extends StatelessWidget {
  const InvitesPage({super.key});

  Future<String> getUsername(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists ? doc['username'] ?? 'Unknown' : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: drawerBackground,
      appBar: AppBar(
        title: const Text("Invites"),
        backgroundColor: drawerBackground,
        foregroundColor: neonCyan,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('invites')
            .where('toUid', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final invites = snapshot.data!.docs;

          if (invites.isEmpty) {
            return const Center(
              child: Text('No invites.', style: TextStyle(color: mutedText)),
            );
          }

          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final fromUid = invite['fromUid'];

              return FutureBuilder<String>(
                future: getUsername(fromUid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const ListTile(title: Text("Loading...", style: TextStyle(color: mutedText)));
                  }

                  final senderUsername = userSnap.data!;
                  final isPermission = invite['type'] == 'permission';
                  final title = isPermission ? " 🔐 Permission Request" : "📅 Plan Invite";
                  final subtitle = isPermission
                      ? "Grant invite permission to ${invite.data().containsKey('secondaryName') ? invite['secondaryName'] : 'someone'}?"
                      : (invite['plan'] ?? 'No plan');

                  return Card(
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(title, style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
                      subtitle: Text(subtitle, style: const TextStyle(color: mutedText)),
                      trailing: const Icon(Icons.chevron_right, color: neonCyan),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InviteDetailsPage(
                              senderUsername: senderUsername,
                              plan: invite['plan'] ?? 'No plan',
                              description: invite['description'] ?? 'No description',
                              inviteId: invite.id,
                              inviteData: invite.data(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class InviteDetailsPage extends StatelessWidget {
  final String senderUsername;
  final String plan;
  final String description;
  final String inviteId;
  final Map<String, dynamic> inviteData;

  const InviteDetailsPage({
    super.key,
    required this.senderUsername,
    required this.plan,
    required this.description,
    required this.inviteId,
    required this.inviteData,
  });

  void acceptInvite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final type = inviteData['type'] ?? 'normal';
    final fromUid = inviteData['fromUid'];
    final toUid = inviteData['toUid'];

    if (type == 'permission') {
      final secondaryUid = inviteData['secondaryUid'];
      final secondaryName = inviteData['secondaryName'];

      await FirebaseFirestore.instance.collection('users').doc(fromUid).update({
        'pseudoPrimaries': FieldValue.arrayUnion([secondaryUid])
      });

      await FirebaseFirestore.instance.collection('invites').add({
        'fromUid': fromUid,
        'toUid': secondaryUid,
        'plan': plan,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'normal',
      });

      await FirebaseFirestore.instance.collection('invites').doc(inviteId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Permission granted. Invite sent to $secondaryName!"),
        ));
        Navigator.pop(context);
      }
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('plans')
        .where('fromUid', isEqualTo: fromUid)
        .where('title', isEqualTo: plan)
        .where('description', isEqualTo: description)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final planDoc = query.docs.first;
      await planDoc.reference.update({
        'acceptedBy': FieldValue.arrayUnion([user.uid]),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseFirestore.instance.collection('invites').doc(inviteId).delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accepted invite")));
      Navigator.pop(context);
    }
  }

  void rejectInvite(BuildContext context) {
    FirebaseFirestore.instance.collection('invites').doc(inviteId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rejected invite")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPermission = inviteData['type'] == 'permission';
    final secondName = inviteData['secondaryName'];

    return Scaffold(
      backgroundColor: drawerBackground,
      appBar: AppBar(
        title: Text(isPermission ? "Permission Request" : "Plan Invite"),
        backgroundColor: drawerBackground,
        foregroundColor: neonCyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: $senderUsername", style: const TextStyle(color: neonCyan, fontSize: 16)),
            const SizedBox(height: 16),
            Text("Plan:", style: const TextStyle(color: neonCyan, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(plan, style: const TextStyle(color: mutedText)),
            const SizedBox(height: 20),
            Text("Description:", style: const TextStyle(color: neonCyan, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: mutedText)),
            if (isPermission) ...[
              const SizedBox(height: 30),
              Text(
                "Grant permission to send invite to $secondName?",
                style: const TextStyle(color: neonCyan, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => acceptInvite(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text(isPermission ? "Grant" : "Accept"),
                ),
                OutlinedButton(
                  onPressed: () => rejectInvite(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: neonCyan),
                    foregroundColor: neonCyan,
                  ),
                  child: Text(isPermission ? "Deny" : "Reject"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
