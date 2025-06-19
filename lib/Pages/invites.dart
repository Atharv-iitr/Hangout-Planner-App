import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: const Text("Invites")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('invites')
            .where('toUid', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final invites = snapshot.data!.docs;

          if (invites.isEmpty) {
            return const Center(child: Text('No invites.'));
          }

          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final fromUid = invite['fromUid'];
              final isPermission = invite['type'] == 'permission';

             return FutureBuilder<String>(
  future: getUsername(fromUid),
  builder: (context, userSnap) {
    if (!userSnap.hasData) return const ListTile(title: Text("Loading..."));

    final senderUsername = userSnap.data!;
    final isPermission = invite['type'] == 'permission';

    final title = isPermission ? "Permission Request" : "Plan Invite";
    final subtitle = isPermission
        ? "Grant permission to send invite to ${invite.data().containsKey('secondaryName') ? invite['secondaryName'] : '2nd-degree user'}?"
        : (invite['plan'] ?? 'No plan');

    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InviteDetailsPage(
              senderUsername: senderUsername,
              plan: invite['plan'] ?? 'No plan',
              description: invite['description'] ?? 'No description',
              inviteId: invite.id,
              inviteData: invite.data(), // ✅ optional, if you're using it later
            ),
          ),
        );
      },
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

      // ✅ Grant permission
      await FirebaseFirestore.instance.collection('users').doc(fromUid).update({
        'pseudoPrimaries': FieldValue.arrayUnion([secondaryUid])
      });

      // ✅ Send actual invite
      await FirebaseFirestore.instance.collection('invites').add({
        'fromUid': fromUid,
        'toUid': secondaryUid,
        'plan': plan,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'normal',
      });

      // 🧹 Delete permission invite
      await FirebaseFirestore.instance.collection('invites').doc(inviteId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Permission granted. Invite sent to $secondaryName!"),
        ));
        Navigator.pop(context);
      }
      return;
    }

    // ✅ Normal plan invite acceptance
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

    // 🧹 Delete the invite
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
    final secondName = inviteData['secondaryName'] ;

    return Scaffold(
      appBar: AppBar(title: Text(isPermission ? "Permission Request" : "Plan Invite")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: $senderUsername", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Plan:", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(plan, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            Text("Description:", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(description),
            if (isPermission) ...[
              const SizedBox(height: 30),
              Text(
                "Grant permission to send invite to $secondName?",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => acceptInvite(context),
                child: Text(isPermission ? "Grant" : "Accept"),
                ),
                OutlinedButton(
                  onPressed: () => rejectInvite(context),
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
