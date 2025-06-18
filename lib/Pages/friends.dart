import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, String>> _friends = [];
  List<Map<String, String>> _filteredFriends = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends = _friends
          .where((friend) => friend['username']!.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final friendsList = (userDoc.data()?['friends'] as List?) ?? [];

      List<Map<String, String>> friends = [];
      for (final friend in friendsList) {
        final friendUid = friend['uid'];
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        final username = friendDoc.data()?['username'] ?? 'Unknown';
        friends.add({'uid': friendUid, 'username': username});
      }

      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading friends: $e");
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final friendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid);

      final userDoc = await userRef.get();
      final userFriends = List.from(userDoc.data()?['friends'] ?? []);
      userFriends.removeWhere((f) => f['uid'] == friendUid);
      await userRef.update({'friends': userFriends});

      final friendDoc = await friendRef.get();
      final theirFriends = List.from(friendDoc.data()?['friends'] ?? []);
      theirFriends.removeWhere((f) => f['uid'] == user.uid);
      await friendRef.update({'friends': theirFriends});

      _loadFriends(); // Refresh UI
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Friend removed')),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error removing friend: $e");
      }
    }
  }

  Future<void> _confirmAndRemove(String friendUid, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Remove Friend', style: TextStyle(color: Colors.cyanAccent)),
        content: Text('Remove $username?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _removeFriend(friendUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F3F),
        title: const Text("Your Friends", style: TextStyle(color: Colors.cyanAccent)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1C1B33),
                      prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                      hintText: 'Search friends...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.redAccent),
                              onPressed: () {
                                _searchController.clear();
                                _filterFriends();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredFriends.isEmpty
                      ? const Center(
                          child: Text(
                            "No matching friends found.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            return Card(
                              color: const Color(0xFF1F1F3F),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Colors.cyanAccent),
                                title: Text(
                                  friend['username'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  tooltip: "Remove friend",
                                  onPressed: () => _confirmAndRemove(
                                    friend['uid']!,
                                    friend['username']!,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
