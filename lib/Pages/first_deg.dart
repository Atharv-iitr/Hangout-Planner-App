import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirstDeg extends StatefulWidget {
  final String? userUid;
  final int depth;

  const FirstDeg({super.key, this.userUid, this.depth = 0});

  @override
  State<FirstDeg> createState() => _FirstDegState();
}

class _FirstDegState extends State<FirstDeg> {
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
      });
    } catch (e) {
      debugPrint("Error loading friends: $e");
      setState(() => isLoading = false);
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final center = Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2,
                    );
                    const double nodeRadius = 40;
                    const double orbitRadius = 120;

                    List<Offset> friendPositions = [];
                    for (int i = 0; i < friends.length; i++) {
                      final angle = 2 * pi * i / friends.length;
                      final dx = center.dx + orbitRadius * cos(angle);
                      final dy = center.dy + orbitRadius * sin(angle);
                      friendPositions.add(Offset(dx, dy));
                    }

                    return Stack(
                      children: [
                        // Draw lines
                        CustomPaint(
                          size: Size.infinite,
                          painter: LinePainter(
                            center: center,
                            friendPositions: friendPositions,
                          ),
                        ),
                        // Center node
                        Positioned(
                          left: center.dx - nodeRadius,
                          top: center.dy - nodeRadius,
                          width: nodeRadius * 2,
                          height: nodeRadius * 2,
                          child: _buildNode(centerName, color: Colors.blueAccent),
                        ),
                        // Friend nodes
                        for (int i = 0; i < friends.length; i++)
                          Positioned(
                            left: friendPositions[i].dx - nodeRadius,
                            top: friendPositions[i].dy - nodeRadius,
                            width: nodeRadius * 2,
                            height: nodeRadius * 2,
                            child: GestureDetector(
                              onTap: () {
                                if (widget.depth < 1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FirstDeg(
                                        userUid: friends[i]['uid'],
                                        depth: widget.depth + 1,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Optional: show a snackbar when limit reached
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "You can only view up to second-degree friends.",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: _buildNode(
                                friends[i]['username'] ?? 'Unknown',
                                color: widget.depth < 1
                                    ? Colors.orangeAccent
                                    : Colors.grey, // Visually indicate disabled
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildNode(String name, {required Color color}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset center;
  final List<Offset> friendPositions;

  LinePainter({
    required this.center,
    required this.friendPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double nodeRadius = 40;
    final Paint linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (final friendPos in friendPositions) {
      final direction = (friendPos - center).normalize();
      final start = center + direction * nodeRadius;
      final end = friendPos - direction * nodeRadius;
      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension for vector normalization
extension Normalize on Offset {
  Offset normalize() {
    final len = distance;
    return len == 0 ? this : this / len;
  }
}
