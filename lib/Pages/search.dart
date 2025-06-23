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
    final targetRef = FirebaseFirestore.instance.collection('users').doc(targetId);

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
    } catch (e) {
      debugPrint('ERROR sending request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0A0F24);
    const Color accentColor = Color(0xFF00FFC5);
    const Color neonPink = Color(0xFFFF00C8);
    const Color textColor = Color(0xFFE4E4E4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 75, 71, 106), Color.fromARGB(255, 46, 40, 124), Color.fromARGB(255, 21, 21, 120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
        centerTitle: true,
        title: const Text(
          'Search People',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: accentColor,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1C1B33),
                hintText: 'Search usernames...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: neonPink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: neonPink),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: neonPink, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
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
                    return Card(
                      color: const Color(0xFF121426),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          doc['username'],
                          style: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                        trailing: busy
                            ? const Text(
                                'Requested / Friend',
                                style: TextStyle(color: Colors.grey),
                              )
                            : ElevatedButton(
                                onPressed: () => _sendRequest(doc),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: neonPink,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Add'),
                              ),
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
