import 'dart:math' as math;

import 'package:flutter/material.dart';

class PlantArt extends StatelessWidget {
  final String plant;
  final double progress;
  const PlantArt({super.key, required this.plant, required this.progress});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustrated growth stage of $plant',
    child: CustomPaint(
      size: const Size(double.infinity, 165),
      painter: PlantPainter(plant, progress),
    ),
  );
}

class PlantPainter extends CustomPainter {
  final String plant;
  final double progress;
  PlantPainter(this.plant, this.progress);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 320, size.height / 180);
    const green = Color(0xFF6E9661),
        dark = Color(0xFF456A43),
        gold = Color(0xFFEDAE45);
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    oval(0, 130, 320, 70, const Color(0xFFE7EDD7));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(85, 135, 150, 30),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFBA8050),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(91, 133, 138, 13),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF795548),
    );
    final height = 20.0 + progress.clamp(0, 1).toDouble() * 75;
    final top = 137.0 - height;
    c.drawLine(
      const Offset(160, 140),
      Offset(160, top),
      Paint()
        ..color = dark
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    oval(138, top + 12, 23, 13, green);
    oval(160, top + 4, 25, 14, dark);
    if (progress > .35) {
      oval(132, top + 34, 28, 16, green);
      oval(160, top + 30, 30, 17, green);
    }
    if (plant == 'lettuce') {
      for (var i = 0; i < 5; i++) {
        oval(125.0 + i * 6, 100.0 + i % 2 * 9, 32, 25, green);
      }
    }
    if (plant == 'carrot' && progress > .5) {
      final root = Path()
        ..moveTo(151, 141)
        ..lineTo(170, 141)
        ..lineTo(160, 172)
        ..close();
      c.drawPath(root, Paint()..color = const Color(0xFFDB8D67));
    }
    if (progress > .65 &&
        ['sunflower', 'marigold', 'strawberry'].contains(plant)) {
      for (var i = 0; i < 7; i++) {
        final a = i * math.pi * 2 / 7;
        oval(
          151 + math.cos(a) * 14,
          top - 9 + math.sin(a) * 14,
          18,
          18,
          plant == 'strawberry'
              ? const Color(0xFFFFF8EB)
              : plant == 'marigold'
              ? const Color(0xFFE89842)
              : gold,
        );
      }
      oval(151, top - 9, 18, 18, const Color(0xFFBA8050));
    }
    if (progress > .8 && ['tomato', 'strawberry'].contains(plant)) {
      oval(130, top + 25, 19, 20, const Color(0xFFD97658));
      oval(175, top + 18, 18, 20, const Color(0xFFD97658));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(PlantPainter old) =>
      old.plant != plant || old.progress != progress;
}
