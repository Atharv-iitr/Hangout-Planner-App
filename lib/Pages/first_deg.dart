import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:graphview/GraphView.dart';

class FirstDeg extends StatefulWidget {
  final String? userUid; // <-- Add this

  const FirstDeg({super.key, this.userUid}); // <-- Add this

  @override
  State<FirstDeg> createState() => _FirstDegState();
}

class _FirstDegState extends State<FirstDeg> {
  final Graph graph = Graph();
  late Node centerNode;

  bool isLoading = true;
  List<Map<String, String>> friends = [];
  String centerName = 'You';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = widget.userUid ?? user.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final username = userDoc.data()?['username'] ?? 'You';
      centerName = username;
      centerNode = Node.Id(centerName);

      final friendsList = (userDoc.data()?['friends'] as List?) ?? [];

      List<Map<String, String>> fetchedFriends = [];

      for (final friend in friendsList) {
        final friendUid = friend['uid'];
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        final friendName = friendDoc.data()?['username'] ?? 'Unknown';
        fetchedFriends.add({'uid': friendUid, 'username': friendName});
      }

      setState(() {
        friends = fetchedFriends;
        isLoading = false;
        _buildGraph();
      });
    } catch (e) {
      debugPrint("Error loading friends: $e");
      setState(() => isLoading = false);
    }
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    graph.addNode(centerNode);
    for (final friend in friends) {
      final node = Node.Id(friend['username']);
      graph.addEdge(centerNode, node);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$centerName's Friends")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : friends.isEmpty
              ? const Center(child: Text("No friends found"))
              : InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: FruchtermanReingoldAlgorithm(),
                    builder: (Node node) {
                      final name = node.key!.value as String;
                      return personNode(name);
                    },
                  ),
                ),
    );
  }

  Widget personNode(String name) {
    if (name == centerName) {
      // Center node (You or friend)
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    // Find the friend's UID
    final friend = friends.firstWhere((f) => f['username'] == name, orElse: () => {});
    final friendUid = friend['uid'];

    return GestureDetector(
      onTap: () {
        if (friendUid != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirstDeg(userUid: friendUid),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange[200],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}