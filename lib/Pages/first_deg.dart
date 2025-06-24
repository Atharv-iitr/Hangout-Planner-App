import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 

class FirstDeg extends StatefulWidget {
  final String? userUid;
  final int depth;
  final String? centerName;
  final List<String> excludedUids;

  final String planTitle; 
  final String planDesc;  

  const FirstDeg({
    super.key,
    this.userUid,
    this.depth = 0,
    this.centerName,
    this.excludedUids = const [],
    required this.planTitle,  
    required this.planDesc,   
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final username = userDoc.data()?['username'] ?? 'Unknown';

      if (widget.depth == 0 && mounted) {
        setState(() => centerName = username);
      }

      final friendsList = (userDoc.data()?['friends'] as List?) ?? [];
      List<Map<String, String>> fetched = [];

      for (final friend in friendsList) {
        final friendUid = friend['uid'];
        if (widget.excludedUids.contains(friendUid)) continue;
        final friendDoc = await FirebaseFirestore.instance.collection('users').doc(friendUid).get();
        final friendName = friendDoc.data()?['username'] ?? 'Unknown';
        fetched.add({'uid': friendUid, 'username': friendName});
      }

      if (mounted) {
        setState(() {
          friends = fetched;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading friends: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
   Future<void> _sendPermissionRequest(String approverUid, String targetUid) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  //  Fetch username of the 2nd-degree friend (target)
  final targetDoc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
  final secondaryName = targetDoc.data()?['username'] ?? 'Unknown';
   //  Fetch primary friend's name
  final primaryDoc = await FirebaseFirestore.instance.collection('users').doc(approverUid).get();
  final primaryName = primaryDoc.data()?['username'] ?? 'Unknown';
  //  Send permission request with secondaryName
  await FirebaseFirestore.instance.collection('invites').add({
    'type': 'permission',
    'fromUid': currentUser.uid,
    'toUid': approverUid,
    'secondaryUid': targetUid,
    'secondaryName': secondaryName, //  Added for display
    'plan': widget.planTitle,
    'description': widget.planDesc,
    'timestamp': FieldValue.serverTimestamp()
  });

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Permission request sent to $primaryName!")),
  );
}

Future<void> _sendDirectInvite(String targetUid) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  await FirebaseFirestore.instance.collection('invites').add({
    'fromUid': currentUser.uid,
    'toUid': targetUid,
    'plan': widget.planTitle,
    'description': widget.planDesc,
    'timestamp': FieldValue.serverTimestamp(),
    'type': 'normal',
  });

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Invite sent!")),
  );
}


  Future<void> _sendInvite({
  required String targetUid,
  required String viaFirstDegreeUid,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
  final pseudoPrimaries = List<String>.from(userDoc.data()?['pseudoPrimaries'] ?? []);

  if (pseudoPrimaries.contains(targetUid)) {
    //  Already approved, send actual invite
    await FirebaseFirestore.instance.collection('invites').add({
      'fromUid': currentUser.uid,
      'toUid': targetUid,
      'plan': widget.planTitle,
      'description': widget.planDesc,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'normal',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invite sent!")));
  } else {
    //  Not approved yet → send permission request to 1st-degree friend
    await _sendPermissionRequest(viaFirstDegreeUid, targetUid);
  }
}



  @override
  Widget build(BuildContext context) {
    final totalPages = max((friends.length / friendsPerPage).ceil(),1);
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
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final center = Offset(
                            constraints.maxWidth / 2,
                            constraints.maxHeight / 2 - 30,
                          );
                          const double nodeRadius = 40;
                          const double orbitRadius = 120;

                          if (visibleFriends.isEmpty) {
                            return Stack(
                              children: [
                               Positioned(
  left: center.dx - nodeRadius,
  top: center.dy - nodeRadius,
  width: nodeRadius * 2,
  height: nodeRadius * 2,
  child: GestureDetector(
    onTap: () {
      //  Invite the primary friend directly
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Invite?"),
            content: const Text("Send this plan invite to this friend?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendDirectInvite(widget.userUid!);

                },
                child: const Text("Send"),
              ),
            ],
          );
        },
      );
    },
    child: _buildNode(centerName, color: const Color(0xFF8144D6)),
  ),
),
                              ],
                            );
                          }

                          List<Offset> positions = [];
                          for (int i = 0; i < visibleFriends.length; i++) {
                            final angle = 2 * pi * i / visibleFriends.length;
                            final dx = center.dx + orbitRadius * cos(angle);
                            final dy = center.dy + orbitRadius * sin(angle);
                            positions.add(Offset(dx, dy));
                          }

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: KeyedSubtree(
                              key: ValueKey(currentPage),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: LinePainter(center: center, friendPositions: positions),
                                  ),
                                  Positioned(
  left: center.dx - nodeRadius,
  top: center.dy - nodeRadius,
  width: nodeRadius * 2,
  height: nodeRadius * 2,
  child: GestureDetector(
    onTap: () {
      //  Invite the primary friend directly
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text("Invite?"),
            content: const Text("Send this plan invite to this friend?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendDirectInvite(widget.userUid!);

                },
                child: const Text("Send"),
              ),
            ],
          );
        },
      );
    },
    child: _buildNode(centerName, color: const Color(0xFF8144D6)),
  ),
),

                                  for (int i = 0; i < visibleFriends.length; i++)
                                    Positioned(
                                      left: positions[i].dx - nodeRadius,
                                      top: positions[i].dy - nodeRadius,
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
                                                builder: (_) => FirstDeg(
                                                  userUid: visibleFriends[i]['uid'],
                                                  centerName: visibleFriends[i]['username'],
                                                  depth: widget.depth + 1,
                                                  excludedUids: [
                                                    ...widget.excludedUids,
                                                    ...friends.map((f) => f['uid']!),
                                                    currentUserUid,
                                                  ],
                                                  planTitle: widget.planTitle,
                                                  planDesc: widget.planDesc,
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Show invite dialog
                                            showDialog(
                                              context: context,
                                              builder: (_) {
                                                return AlertDialog(
                                                  title: const Text("Invite?"),
                                                  content: const Text("Send this plan invite to user?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _sendInvite(
  targetUid: visibleFriends[i]['uid']!,
  viaFirstDegreeUid: widget.userUid!, // this is the primary friend you accessed 2nd-degree from
);

                                                      },
                                                      child: const Text("Send"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: _buildNode(
                                          visibleFriends[i]['username']!,
                                          color: widget.depth < 1
                                              ? const Color(0xFF28E8F2)
                                              : Colors.grey.shade700,
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
                      padding: const EdgeInsets.only(bottom: 130),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5FF),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                            ),
                            onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                            child: const Text("Previous Friends"),
                          ),
                          if (totalPages > 0)
                            Text(
                              '${currentPage + 1} / $totalPages',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F5FF),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                            ),
                            onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          child: Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
    const nodeRadius = 40.0;
    final paint = Paint()..color = const Color(0xFF4DD0E1)..strokeWidth = 2;

    for (var pos in friendPositions) {
      final dir = (pos - center).normalize();
      canvas.drawLine(center + dir * nodeRadius, pos - dir * nodeRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

extension Normalize on Offset {
  Offset normalize() {
    final len = distance;
    return len == 0 ? this : this / len;
  }
}