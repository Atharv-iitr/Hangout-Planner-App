import 'package:flutter/material.dart';


void main() => runApp(const HomePage());

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DrawerExample(),
      debugShowCheckedModeBanner: false,
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
                setState(() {
                  selectedPage = 'Invites';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Friends'),
              onTap: () {
                setState(() {
                  selectedPage = 'Friends';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.notification_add),
              title: const Text('Notifications'),
              onTap: () {
                setState(() {
                  selectedPage = 'Notifications';
                });
              },
            ),
          ],
        ),
      ),
      body: Center(child: Text('Page: $selectedPage')),
      
    );
  }
}
