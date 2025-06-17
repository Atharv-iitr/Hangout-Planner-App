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
        title: const Text(
          'Hangout Planner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
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
                  accountName: Text(userName),
                  accountEmail: Text(
                    userUsername.isNotEmpty ? '@$userUsername' : '',
                  ),
                  currentAccountPicture: user?.photoURL != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoURL!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  decoration: const BoxDecoration(color: Colors.blue),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Invites'),
              onTap: () => Navigator.pushNamed(context, '/invitespage'),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Friends'),
              onTap: () => Navigator.pushNamed(context, '/friendspage'),
            ),
            ListTile(
              leading: const Icon(Icons.notification_add),
              title: const Text('Notifications'),
              onTap: () => Navigator.pushNamed(context, '/Notificationpage'),
            ),
          ],
        ),
      ),
      body: const FriendGraphWidget(),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: "fab1",
              onPressed: () => Navigator.pushNamed(context, '/search'),
              child: const Icon(Icons.search),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "fab2",
              onPressed: () => Navigator.pushNamed(context, '/makeplan'),
              icon: const Icon(Icons.edit),
              label: const Text("Make Plan"),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class FriendGraphWidget extends StatefulWidget {
  final String? userUid;
  final int depth;
  final String? title;

  const FriendGraphWidget({
    super.key,
    this.userUid,
    this.depth = 0,
    this.title,
  });

  @override
  State<FriendGraphWidget> createState() => _FriendGraphWidgetState();
}

class _FriendGraphWidgetState extends State<FriendGraphWidget> {
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : friends.isEmpty
        ? const Center(child: Text("No friends found"))
        : LayoutBuilder(
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
                    child: _buildNode(centerName, color: Colors.blueAccent),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    title: Text(
                                      "${friends[i]['username']}'s Friends",
                                    ),
                                  ),
                                  body: FriendGraphWidget(
                                    userUid: friends[i]['uid'],
                                    depth: widget.depth + 1,
                                    title: friends[i]['username'],
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
                              ? Colors.orangeAccent
                              : Colors.grey,
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
