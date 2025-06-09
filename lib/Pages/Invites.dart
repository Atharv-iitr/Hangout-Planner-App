import 'package:flutter/material.dart';

class InvitesPage extends StatelessWidget {
  const InvitesPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invites',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        ),
        centerTitle: true,
      ),
    );

  }
}