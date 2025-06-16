import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchUsers(_searchController.text.trim());
    });
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final meId = FirebaseAuth.instance.currentUser!.uid;
    final querySnap = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    if (!mounted) return; 
    setState(() {
      _results = querySnap.docs.where((doc) => doc.id != meId).toList();
    });
  }

  Future<bool> _isFriendOrRequested(doc) async {
    final me = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final data = me.data()!;

    final friends = (data['friends'] as List)
        .map((e) => e['uid'] as String)
        .toList();
    final outgoing = List<String>.from(data['outgoingRequests'] ?? []);
    return friends.contains(doc.id) || outgoing.contains(doc.id);
  }

  void _sendRequest(DocumentSnapshot target) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in')),
      );
      return;
    }

    final meId = user.uid;
    final targetId = target.id;

    final meRef = FirebaseFirestore.instance.collection('users').doc(meId);
    final targetRef =
        FirebaseFirestore.instance.collection('users').doc(targetId);

    try {
      await Future.wait([
        meRef.set({
          'outgoingRequests': FieldValue.arrayUnion([targetId])
        }, SetOptions(merge: true)),
        targetRef.set({
          'incomingRequests': FieldValue.arrayUnion([meId])
        }, SetOptions(merge: true)),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
    } catch (e, stack) {
      debugPrint('ERROR sending request: $e');
      debugPrint('Stacktrace: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search People',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search usernames...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final doc = _results[i];
                return FutureBuilder<bool>(
                  future: _isFriendOrRequested(doc),
                  builder: (context, snap) {
                    final busy = snap.data ?? false;
                    return ListTile(
                      title: Text(doc['username']),
                      trailing: busy
                          ? const Text('Already requested or friends')
                          : ElevatedButton(
                              onPressed: () => _sendRequest(doc),
                              child: const Text('Add Friend'),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
