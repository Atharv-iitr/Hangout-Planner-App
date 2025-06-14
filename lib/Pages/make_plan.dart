import 'package:flutter/material.dart';

class MakePlan extends StatelessWidget {
  const MakePlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Make your plan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 150),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your plan...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom-center FAB
          Positioned(
            bottom: 200, // bottom padding
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 150, // wider button
                height: 60,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/firstdeg');
                  },

                  label: const Text('Next'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}