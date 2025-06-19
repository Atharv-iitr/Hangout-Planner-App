import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:hangout_planner/Pages/profile_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  late Future<void> _fetchUserDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserDataFuture = _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _userData = await _authService.getCurrentUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
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
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
        elevation: 10,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F0F2D), // Dark cyberpunk background
        child: FutureBuilder<void>(
          future: _fetchUserDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (_userData == null) {
              return const Center(child: Text('User data not found.'));
            } else {
              final username = _userData!['username'] as String? ?? 'N/A';
              final biodata = _userData!['biodata'] as String? ?? 'No biodata available.';
              final profileImageUrl = _userData!['profileImageUrl'] as String? ?? '';

              return ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  // Custom DrawerHeader to display profile info
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black54,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.cyanAccent, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1, // Added to truncate long usernames
                          overflow: TextOverflow.ellipsis, // Added ellipsis for truncated usernames
                        ),
                        Text(
                          biodata,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2, // Truncate biodata if it exceeds 2 lines
                          overflow: TextOverflow.ellipsis, // Add ellipsis for truncated biodata
                        ),
                      ],
                    ),
                  ),
                  _buildCyberTile(
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Already on home page
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
                  _buildCyberTile(
                    icon: Icons.calendar_today,
                    title: 'Plans',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/planspage');
                    },
                  ),
                  _buildCyberTile(
                    icon: Icons.add_circle,
                    title: 'Make a Plan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/makeplan');
                    },
                  ),
                  _buildCyberTile(
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/search');
                    },
                  ),
                  _buildCyberTile( // New Settings Tile
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () async { // Changed to async
                      Navigator.pop(context); // Close the drawer
                      await Navigator.pushNamed(context, '/profilesettings'); // Wait for the settings page to close
                      _fetchUserData(); // Re-fetch user data after returning
                    },
                  ),
                ],
              );
            }
          },
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
            right: 165,
            child: FloatingActionButton.extended(
              backgroundColor: const Color.fromARGB(255, 1, 192, 255),
              heroTag: "fab2",
              onPressed: () => Navigator.pushNamed(context, '/planspage'),
              icon: const Icon(Icons.event_note, color: Colors.white),
              label: const Text("Plans"),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF00F5FF),
              heroTag: "fab1",
              onPressed: () => Navigator.pushNamed(context, '/search'),
              child: const Icon(Icons.search, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFF0266),
              heroTag: "fab3",
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
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
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
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  Future<List<Map<String, String>>> _resolveUsernames(List<Map<String, String>> friends) async {
    List<Map<String, String>> resolved = [];
    for (var friend in friends) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(friend['uid']).get();
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
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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
            final endIndex = min(startIndex + friendsPerPage, allFriends.length);
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5FF),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                        ),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5FF),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                        ),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage++;
                                  _controller.forward(from: 0);
                                });
                              }
                            : null,
                        child: const Text('Next Friends'),

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
      return LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2 - 100,
          );
          const double nodeRadius = 40;
          return Stack(
            children: [
              Positioned(
                left: center.dx - nodeRadius,
                top: center.dy - nodeRadius,
                width: nodeRadius * 2,
                height: nodeRadius * 2,
                child: _buildNode(centerName, color: Colors.deepPurpleAccent),
              ),
            ],
          );
        },
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
              painter: LinePainter(center: center, friendPositions: friendPositions),
            ),
            // Iterate over friend positions to create nodes
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
                            appBar: AppBar(
                                title: Text("${friends[i]['username']}'s Friends")),
                            body: FriendGraphWidget(
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
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("You can only view up to second-degree friends.")),
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
            // The center node should be placed here after the loop
            Positioned(
              left: center.dx - nodeRadius,
              top: center.dy - nodeRadius,
              width: nodeRadius * 2,
              height: nodeRadius * 2,
              child: _buildNode(centerName, color: Colors.deepPurpleAccent),
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

// Extension to add normalize method to Offset
extension Normalize on Offset {
  Offset normalize() {
    final len = distance;
    return len == 0 ? this : this / len;
  }
}