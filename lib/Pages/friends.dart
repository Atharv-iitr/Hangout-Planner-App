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
          .where((friend) =>
              friend['username']!.toLowerCase().contains(query))
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

      if (kDebugMode) {
        debugPrint("Loaded friends: $friends");
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final friendRef =
          FirebaseFirestore.instance.collection('users').doc(friendUid);

      // Remove friend from current user's list
      final userDoc = await userRef.get();
      final userFriends = List.from(userDoc.data()?['friends'] ?? []);
      userFriends.removeWhere((f) => f['uid'] == friendUid);
      await userRef.update({'friends': userFriends});

      // Remove current user from friend's list
      final friendDoc = await friendRef.get();
      final theirFriends = List.from(friendDoc.data()?['friends'] ?? []);
      theirFriends.removeWhere((f) => f['uid'] == user.uid);
      await friendRef.update({'friends': theirFriends});

      if (kDebugMode) {
        debugPrint("Removed friendship between ${user.uid} and $friendUid");
      }

      _loadFriends(); // Refresh UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove $username as a friend?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(title: const Text("Your Friends")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search friends...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                      ? const Center(child: Text("No matching friends found."))
                      : ListView.builder(
                          itemCount: _filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(friend['username'] ?? 'Unknown'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                tooltip: "Remove friend",
                                onPressed: () => _confirmAndRemove(
                                    friend['uid']!, friend['username']!),
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
