import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'first_deg.dart'; // <-- Import your FirstDeg widget

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;

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
                  accountEmail: Text(userUsername.isNotEmpty ? '@$userUsername' : ''),
                  currentAccountPicture: user?.photoURL != null
                      ? CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!))
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : const FirstDeg(), // <-- Use FirstDeg directly
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 60, // Increased from 16 to 80 to move up
            left: 16,
            child: FloatingActionButton(
              heroTag: "fab1",
              onPressed: () => Navigator.pushNamed(context, '/search'),
              child: const Icon(Icons.search),
            ),
          ),
          Positioned(
            bottom: 60, // Increased from 16 to 80 to move up
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
