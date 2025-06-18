import 'package:flutter/material.dart';

class MakePlan extends StatelessWidget {
  const MakePlan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Make Your Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.cyanAccent,
          ),
        ),
        centerTitle: true,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter your plan...',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.edit),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(18),
                          ),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "Enter the plan's description...",
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.description),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(18),
                          ),
                          style: TextStyle(fontSize: 16),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom-center FAB
            Positioned(
              bottom: 350,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 160,
                  height: 55,
                  child: FloatingActionButton.extended(
                    backgroundColor: const Color(0xFF00F5FF), 
                    foregroundColor: Colors.black, 
                    elevation: 6,
                    onPressed: () {
                      Navigator.pushNamed(context, '/firstdeg');
                    },
                    label: const Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
