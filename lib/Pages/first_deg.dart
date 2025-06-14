import 'package:flutter/material.dart';
import 'dart:math';

class FirstDeg extends StatelessWidget {
  const FirstDeg({super.key});

  Widget node(String label) {
    return Container(
      width: 60,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your 1st degree friends')),
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: Stack(
            children: [
              // Arrows layer
              CustomPaint(
                size: const Size(400, 400),
                painter: ArrowPainter(),
              ),

              // Nodes
              Positioned(top: 50, left: 170, child: node("Top")),
              Positioned(top: 310, left: 170, child: node("Bottom")),

              Positioned(top: 90, left: 10, child: node("L1")),
              Positioned(top: 170, left: 10, child: node("L2")),
              Positioned(top: 250, left: 10, child: node("L3")),

              Positioned(top: 90, right: 10, child: node("R1")),
              Positioned(top: 170, right: 10, child: node("R2")),
              Positioned(top: 250, right: 10, child: node("R3")),

              Positioned(top: 170, left: 170, child: node("Center")),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw lines with arrowheads
class ArrowPainter extends CustomPainter {
  final center = const Offset(200, 190); // Center node center position

  void drawArrow(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Draw line
    canvas.drawLine(from, to, paint);

    // Draw arrowhead
    const arrowSize = 8.0;
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - arrowSize * cos(angle - pi / 6),
                to.dy - arrowSize * sin(angle - pi / 6))
      ..lineTo(to.dx - arrowSize * cos(angle + pi / 6),
                to.dy - arrowSize * sin(angle + pi / 6))
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Define node positions (approximate centers of their containers)
    final top = const Offset(200, 70);
    final bottom = const Offset(200, 330);
    final l1 = const Offset(40, 110);
    final l2 = const Offset(40, 190);
    final l3 = const Offset(40, 270);
    final r1 = const Offset(360, 110);
    final r2 = const Offset(360, 190);
    final r3 = const Offset(360, 270);

    for (final from in [top, bottom, l1, l2, l3, r1, r2, r3]) {
      drawArrow(canvas, from, center);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
