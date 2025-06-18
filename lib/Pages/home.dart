import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 75, 71, 106),
                Color.fromARGB(255, 46, 40, 124),
                Color.fromARGB(255, 21, 21, 120),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Hangout Planner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.cyanAccent),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
        elevation: 10,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F0F2D), // Dark cyberpunk background
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String userName = 'User';
                String userUsername = '';

                if (snapshot.hasData && snapshot.data!.exists) {
                  userName = snapshot.data!['name'] ?? 'User';
                  userUsername = snapshot.data!['username'] ?? '';
                }

                return UserAccountsDrawerHeader(
                  accountName: Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    userUsername.isNotEmpty ? '@$userUsername' : '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  currentAccountPicture: user?.photoURL != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoURL!),
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.person, color: Colors.cyanAccent),
                        ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
            _buildCyberTile(
              icon: Icons.message,
              title: 'Invites',
              onTap: () => Navigator.pushNamed(context, '/invitespage'),
            ),
            _buildCyberTile(
              icon: Icons.account_circle,
              title: 'Friends',
              onTap: () => Navigator.pushNamed(context, '/friendspage'),
            ),
            _buildCyberTile(
              icon: Icons.notification_add,
              title: 'Notifications',
              onTap: () => Navigator.pushNamed(context, '/Notificationpage'),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FriendGraphWidget(userUid: user?.uid),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 16,
            left: 70,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF00F5FF),
              heroTag: "fab1",
              onPressed: () => Navigator.pushNamed(context, '/search'),
              child: const Icon(Icons.search, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 50,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFF0266),
              heroTag: "fab2",
              onPressed: () => Navigator.pushNamed(context, '/makeplan'),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Make Plan"),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

Widget _buildCyberTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.cyanAccent),
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
    hoverColor: Colors.cyan.withOpacity(0.1),
    onTap: onTap,
  );
}

class FriendGraphWidget extends StatefulWidget {
  final String? userUid;
  final int depth;
  final String? title;
  final List<String> excludedUids;

  const FriendGraphWidget({
    super.key,
    this.userUid,
    this.depth = 0,
    this.title,
    this.excludedUids = const [],
  });

  @override
  State<FriendGraphWidget> createState() => _FriendGraphWidgetState();
}

class _FriendGraphWidgetState extends State<FriendGraphWidget>
    with TickerProviderStateMixin {
  String centerName = 'You';
  List<Map<String, String>> allFriends = [];
  int currentPage = 0;
  static const int friendsPerPage = 8;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  Future<List<Map<String, String>>> _resolveUsernames(
    List<Map<String, String>> friends,
  ) async {
    List<Map<String, String>> resolved = [];
    for (var friend in friends) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friend['uid'])
          .get();
      final username = doc.data()?['username'] ?? 'Unknown';
      resolved.add({'uid': friend['uid']!, 'username': username});
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = widget.userUid ?? user?.uid;

    if (uid == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No data available.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final username = data['username'] ?? 'You';
        final friendsList = (data['friends'] as List?) ?? [];

        centerName = username;

        final List<Map<String, String>> friends = [];
        for (final friend in friendsList) {
          if (friend is Map && friend.containsKey('uid')) {
            final friendUid = friend['uid'];
            if (!widget.excludedUids.contains(friendUid)) {
              friends.add({'uid': friendUid, 'username': 'Loading...'});
            }
          }
        }

        return FutureBuilder<List<Map<String, String>>>(
          future: _resolveUsernames(friends),
          builder: (context, friendSnapshot) {
            if (!friendSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            allFriends = friendSnapshot.data!;
            _controller.forward(from: 0);

            final totalPages = (allFriends.length / friendsPerPage).ceil();
            final startIndex = currentPage * friendsPerPage;
            final endIndex = min(
              startIndex + friendsPerPage,
              allFriends.length,
            );
            final currentFriends = allFriends.sublist(startIndex, endIndex);

            return Stack(
              children: [
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _animation,
                    child: _buildGraph(context, currentFriends),
                  ),
                ),
                Positioned(
                  bottom: 150.0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage--;
                                  _controller.forward(from: 0);
                                });
                              }
                            : null,
                        child: const Text('Previous Friends'),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${currentPage + 1} / $totalPages',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage++;
                                  _controller.forward(from: 0);
                                });
                              }
                            : null,
                        child: const Text(
                          'Next Friends',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGraph(BuildContext context, List<Map<String, String>> friends) {
    if (friends.isEmpty) {
      return const Center(
        child: Text(
          'No friends found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2 - 100,
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
              child: _buildNode(centerName, color: Colors.deepPurpleAccent),
            ),
            for (int i = 0; i < friends.length; i++)
              Positioned(
                left: friendPositions[i].dx - nodeRadius,
                top: friendPositions[i].dy - nodeRadius,
                width: nodeRadius * 2,
                height: nodeRadius * 2,
                child: GestureDetector(
                  onTap: () {
                    if (widget.depth < 1) {
                      final currentUserUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: const Color(
                              0xFF0F0F2D,
                            ), // Dark cyberpunk background
                            appBar: AppBar(
                              backgroundColor: const Color(
                                0xFF1CB5E0,
                              ), // Neon blue gradient feel
                              elevation: 10,
                              shadowColor: Colors.cyanAccent.withOpacity(0.4),
                              title: Text(
                                "${friends[i]['username']}'s Friends",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              iconTheme: const IconThemeData(
                                color: Colors.black,
                              ),
                            ),
                            body: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0F0F2D),
                                    Color(0xFF000000),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: FriendGraphWidget(
                                userUid: friends[i]['uid'],
                                depth: widget.depth + 1,
                                title: friends[i]['username'],
                                excludedUids: [
                                  ...widget.excludedUids,
                                  ...allFriends.map((f) => f['uid']!),
                                  currentUserUid,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
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
                        ? const Color(0xFF00F5FF)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        );
      },
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
            spreadRadius: 4,
            offset: const Offset(0, 0),
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
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..strokeWidth = 1.8;

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
