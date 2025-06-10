import 'package:flutter/material.dart';
import 'package:hangout_planner/Pages/invites.dart';
import 'package:hangout_planner/Pages/friends.dart';
import 'package:hangout_planner/Pages/Notification.dart';
/// Flutter code sample for [Drawer].

void main() => runApp(const HomePage());

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const DrawerExample(),
      debugShowCheckedModeBanner: false,
      routes: {
        
        '/invitespage': (context) => const InvitesPage(),
        '/friendspage': (context) => const FriendsPage(),
        '/Notificationpage': (context) => const NotificationsPage()
      },
    );
  }
}

class DrawerExample extends StatefulWidget {
  const DrawerExample({super.key});

  @override
  State<DrawerExample> createState() => _DrawerExampleState();
}

class _DrawerExampleState extends State<DrawerExample> {
  String selectedPage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangout Planner',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        
        ),
        actions: [
          IconButton(
            onPressed: (){
              
            },
            icon: const Icon(Icons.account_circle_outlined),
            iconSize: 32,
            padding: const EdgeInsets.fromLTRB(0, 6, 8, 0),
          ),
        ],
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Invites'),
              onTap: () {
                Navigator.pushNamed(context,'/invitespage');
                
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Friends'),
              onTap: () {
                 Navigator.pushNamed(context,'/friendspage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notification_add),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pushNamed(context,'/Notificationpage');
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Page: $selectedPage')),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Action when pressed
        },
        icon: const Icon(Icons.edit),
        label: const Text("Make Plan"),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Bottom-right
    );
      
    
  }
}
