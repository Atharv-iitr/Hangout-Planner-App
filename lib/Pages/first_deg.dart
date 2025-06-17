import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirstDeg extends StatefulWidget {
  final String? userUid;
  final int depth;
  final String? centerName;

  const FirstDeg({super.key, this.userUid, this.depth = 0, this.centerName});

  @override
  State<FirstDeg> createState() => _FirstDegState();
}

class _FirstDegState extends State<FirstDeg> {
  bool isLoading = true;
  List<Map<String, String>> friends = [];
  static Set<String> myPrimaryFriendUids = {}; // Set only once at root
  late String centerName;
  int currentPage = 0;
  static const int friendsPerPage = 8;

  @override
  void initState() {
    super.initState();
    centerName = widget.centerName ?? 'You';
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
      centerName = widget.centerName ?? username;

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

      // Only set myPrimaryFriendUids once (when depth == 0)
      if (widget.depth == 0 && myPrimaryFriendUids.isEmpty) {
        myPrimaryFriendUids = fetchedFriends.map((f) => f['uid']!).toSet();
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
    final totalPages = (friends.length / friendsPerPage).ceil();
    final startIndex = currentPage * friendsPerPage;
    final endIndex = min(startIndex + friendsPerPage, friends.length);
    final visibleFriends = friends.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(title: Text("$centerName's Friends")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : friends.isEmpty
              ? const Center(child: Text("No friends found"))
              : Column(
                  children: [
                    const SizedBox(height: 40), // Shifts graph down
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final center = Offset(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2 - 40, // Moves graph down
                          );
                          const double nodeRadius = 40;
                          const double orbitRadius = 120;

                          final List<Offset> friendPositions = List.generate(
                            visibleFriends.length,
                            (i) {
                              final angle = 2 * pi * i / visibleFriends.length;
                              final dx = center.dx + orbitRadius * cos(angle);
                              final dy = center.dy + orbitRadius * sin(angle);
                              return Offset(dx, dy);
                            },
                          );

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                            child: Stack(
                              key: ValueKey(currentPage),
                              children: [
                                CustomPaint(
                                  size: Size.infinite,
                                  painter: LinePainter(
                                    center: center,
                                    friendPositions: friendPositions,
                                  ),
                                ),
                                Positioned(
                                  left: center.dx - nodeRadius,
                                  top: center.dy - nodeRadius,
                                  width: nodeRadius * 2,
                                  height: nodeRadius * 2,
                                  child: _buildNode(centerName, color: Colors.blueAccent),
                                ),
                                for (int i = 0; i < visibleFriends.length; i++)
                                  Positioned(
                                    left: friendPositions[i].dx - nodeRadius,
                                    top: friendPositions[i].dy - nodeRadius,
                                    width: nodeRadius * 2,
                                    height: nodeRadius * 2,
                                    child: _buildFriendNode(visibleFriends[i]),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: currentPage > 0
                                ? () => setState(() => currentPage--)
                                : null,
                            child: const Text("Previous Friends"),
                          ),
                          ElevatedButton(
                            onPressed: currentPage < totalPages - 1
                                ? () => setState(() => currentPage++)
                                : null,
                            child: const Text("Next Friends"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFriendNode(Map<String, String> friend) {
    final friendUid = friend['uid']!;
    final isPrimaryFriend = myPrimaryFriendUids.contains(friendUid);

    Color nodeColor = isPrimaryFriend ? Colors.green : Colors.grey;
    bool isClickable = isPrimaryFriend;

    return GestureDetector(
      onTap: () {
        if (isClickable) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirstDeg(
                userUid: friend['uid'],
                centerName: friend['username'],
                depth: widget.depth + 1,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Only your friends are clickable."),
            ),
          );
        }
      },
      child: _buildNode(friend['username'] ?? 'Unknown', color: nodeColor),
    );
  }

  Widget _buildNode(String name, {required Color color}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
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

  LinePainter({required this.center, required this.friendPositions});

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

extension Normalize on Offset {
  Offset normalize() {
    final len = distance;
    return len == 0 ? this : this / len;
  }
}
