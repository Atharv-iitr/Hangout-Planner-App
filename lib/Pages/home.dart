import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hangout_planner/Pages/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    AuthService().signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
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
                  // Get the raw username without email domain
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
              onTap: () {
                Navigator.pushNamed(context, '/invitespage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Friends'),
              onTap: () {
                Navigator.pushNamed(context, '/friendspage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notification_add),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pushNamed(context, '/Notificationpage');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String userName = 'User';
            if (snapshot.hasData && snapshot.data!.exists) {
              userName = snapshot.data!['name'] ?? 'User';
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $userName!',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          // Bottom-left FAB
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: "fab1",
              onPressed: () {
                Navigator.pushNamed(context, '/search');
              },
              child: const Icon(Icons.search),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "fab2",
              onPressed: () {
                Navigator.pushNamed(context, '/makeplan');
              },
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
