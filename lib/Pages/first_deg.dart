import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirstDeg extends StatefulWidget {
  final String? userUid;
  final int depth;
  final String? centerName;
  final List<String> excludedUids;

  const FirstDeg({
    super.key,
    this.userUid,
    this.depth = 0,
    this.centerName,
    this.excludedUids = const [],
  });

  @override
  State<FirstDeg> createState() => _FirstDegState();
}

class _FirstDegState extends State<FirstDeg> {
  bool isLoading = true;
  List<Map<String, String>> friends = [];
  late String centerName;
  int currentPage = 0;
  static const int friendsPerPage = 8;

  @override
  void initState() {
    super.initState();
    centerName = widget.centerName ?? 'Unknown';
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
      final username = userDoc.data()?['username'] ?? 'Unknown';

      if (widget.depth == 0) {
        if (mounted) setState(() => centerName = username);
      }

      final friendsList = (userDoc.data()?['friends'] as List?) ?? [];
      List<Map<String, String>> fetchedFriends = [];

      for (final friend in friendsList) {
        final friendUid = friend['uid'];
        if (widget.excludedUids.contains(friendUid)) continue;

        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();
        final friendName = friendDoc.data()?['username'] ?? 'Unknown';

        fetchedFriends.add({'uid': friendUid, 'username': friendName});
      }

      if (mounted) {
        setState(() {
          friends = fetchedFriends;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading friends: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (friends.length / friendsPerPage).ceil();
    final startIndex = currentPage * friendsPerPage;
    final endIndex = min(startIndex + friendsPerPage, friends.length);
    final visibleFriends = friends.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text("$centerName's Friends"),
        backgroundColor: const Color(0xFF1C1B33),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF101722), Color(0xFF2E2C56)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : friends.isEmpty
              ? const Center(
                  child: Text(
                    "No friends found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final center = Offset(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2 - 30,
                          );
                          const double nodeRadius = 40;
                          const double orbitRadius = 120;

                          List<Offset> friendPositions = [];
                          for (int i = 0; i < visibleFriends.length; i++) {
                            final angle = 2 * pi * i / visibleFriends.length;
                            final dx = center.dx + orbitRadius * cos(angle);
                            final dy = center.dy + orbitRadius * sin(angle);
                            friendPositions.add(Offset(dx, dy));
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: KeyedSubtree(
                              key: ValueKey(currentPage),
                              child: Stack(
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
                                    child: _buildNode(
                                      centerName,
                                      color: const Color(0xFF8144D6),
                                    ),
                                  ),
                                  for (
                                    int i = 0;
                                    i < visibleFriends.length;
                                    i++
                                  )
                                    Positioned(
                                      left: friendPositions[i].dx - nodeRadius,
                                      top: friendPositions[i].dy - nodeRadius,
                                      width: nodeRadius * 2,
                                      height: nodeRadius * 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (widget.depth < 1) {
                                            final currentUserUid =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid ??
                                                '';
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => FirstDeg(
                                                  userUid:
                                                      visibleFriends[i]['uid'],
                                                  centerName:
                                                      visibleFriends[i]['username'],
                                                  depth: widget.depth + 1,
                                                  excludedUids: [
                                                    ...widget.excludedUids,
                                                    ...friends.map(
                                                      (f) => f['uid']!,
                                                    ),
                                                    currentUserUid,
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "You can only view up to second-degree friends.",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: _buildNode(
                                          visibleFriends[i]['username'] ??
                                              'Unknown',
                                          color: const Color(0xFF28E8F2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 130.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: currentPage > 0
                                ? () => setState(() => currentPage--)
                                : null,
                            child: const Text("Previous Friends"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                            ),
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
        ),
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
            color: color.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
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

  LinePainter({required this.center, required this.friendPositions});

  @override
  void paint(Canvas canvas, Size size) {
    const double nodeRadius = 40;
    final Paint linePaint = Paint()
      ..color = const Color(0xFF4DD0E1)
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
