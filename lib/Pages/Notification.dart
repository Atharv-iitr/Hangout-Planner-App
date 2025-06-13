import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _respond(String requesterId, bool accepted, BuildContext c, String userid ) async {
    final meId = FirebaseAuth.instance.currentUser!.uid;
    final users = FirebaseFirestore.instance.collection('users');

    final meSnap = await users.doc(meId).get();
    final myData = meSnap.data()!;
    final myFriends = List<Map<String, dynamic>>.from(myData['friends'] ?? []);
    final nextMyPriority = (myFriends.map((f) => f['priority'] as int).fold(0, max)) + 1;

    final reqSnap = await users.doc(requesterId).get();
    final reqData = reqSnap.data()!;
    final reqFriends = List<Map<String, dynamic>>.from(reqData['friends'] ?? []);
    final nextReqPriority = (reqFriends.map((f) => f['priority'] as int).fold(0, max)) + 1;

    final batch = FirebaseFirestore.instance.batch();

    if (accepted) {
      batch.update(users.doc(meId), {
        'friends': FieldValue.arrayUnion([{'uid': requesterId, 'priority': nextMyPriority}]),
      });
      batch.update(users.doc(requesterId), {
        'friends': FieldValue.arrayUnion([{'uid': meId, 'priority': nextReqPriority}]),
      });
    }

    // Remove from both pending lists
    batch.update(users.doc(meId), {
      'incomingRequests': FieldValue.arrayRemove([requesterId])
    });
    batch.update(users.doc(requesterId), {
      'outgoingRequests': FieldValue.arrayRemove([meId])
    });

    await batch.commit();

    if (c.mounted) {
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Text(accepted
          ? 'You are now friends with $userid'
          : 'Rejected friend request'),
    ),
  );
}

  }

  @override
  Widget build(BuildContext context) {
    final meId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(meId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>;
          final incoming = List<String>.from(data['incomingRequests'] ?? []);
          if (incoming.isEmpty) return const Center(child: Text('No new requests'));

          return ListView(
            children: incoming.map((reqId) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(reqId).get(),
                builder: (context, s2) {
                  if (!s2.hasData) return const ListTile();
                  final uname = s2.data!['username'] ?? '';
                  return ListTile(
                    title: Text('$uname wants to be your friend'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _respond(reqId, true, context, uname),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _respond(reqId, false, context ,uname),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
