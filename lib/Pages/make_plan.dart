import 'package:flutter/material.dart';


class MakePlan extends StatelessWidget {
  const MakePlan({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Plan',
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