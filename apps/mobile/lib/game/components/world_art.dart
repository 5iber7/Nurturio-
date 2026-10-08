import 'dart:math' as math;

import 'package:flutter/material.dart';

class WorldArt extends StatelessWidget {
  final String world;
  final double height;
  final double progress;
  const WorldArt({
    super.key,
    required this.world,
    this.height = 180,
    this.progress = 0,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Illustration of ${world == 'honey'
            ? 'a beehive'
            : world == 'olive'
            ? 'an olive grove'
            : world == 'chicken'
            ? 'a chicken coop'
            : 'a garden'}',
    child: CustomPaint(
      size: Size(double.infinity, height),
      painter: WorldPainter(world, progress),
    ),
  );
}

class WorldPainter extends CustomPainter {
  final String world;
  final double progress;
  final double time;
  WorldPainter(this.world, this.progress, {this.time = 0});
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 400, s.height / 230);
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    void box(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double r = 10,
    ]) => c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = color,
    );
    const green = Color(0xFF6E9661),
        dark = Color(0xFF456A43),
        wood = Color(0xFFBA8050),
        gold = Color(0xFFEDAE45);
    oval(-30, 135, 470, 160, const Color(0xFFE1E8C5));
    oval(245, 25, 55, 55, const Color(0xFFFFDEA0));
    for (var i = 0; i < 6; i++) {
      box(25 + i * 63, 170 + (i % 2) * 12, 3, 26, green, 2);
      oval(
        17 + i * 63,
        163 + (i % 2) * 12,
        20,
        12,
        i.isEven ? gold : const Color(0xFFDDA4A4),
      );
    }
    if (world == 'honey') {
      box(146, 101, 103, 77, gold, 8);
      box(139, 89, 117, 17, wood, 4);
      box(138, 174, 120, 13, wood, 4);
      for (var y = 119; y < 170; y += 19) {
        box(152, y.toDouble(), 90, 3, const Color(0xFFD49435), 1);
      }
      box(180, 162, 34, 9, const Color(0xFF795548), 4);
      box(161, 180, 8, 25, wood, 2);
      box(228, 180, 8, 25, wood, 2);
      for (var i = 0; i < 4; i++) {
        final x = 75 + i * 76 + math.sin(time + i) * 9,
            y = 58 + (i % 2) * 45 + math.cos(time + i) * 7;
        oval(x, y - 5, 13, 12, const Color(0xFFFDFBF2));
        oval(x + 10, y - 5, 13, 12, const Color(0xFFFDFBF2));
        oval(x, y, 25, 17, gold);
        box(x + 8, y + 1, 4, 15, const Color(0xFF795548), 1);
        oval(x + 19, y + 4, 3, 3, dark);
      }
    } else if (world == 'olive') {
      for (var i = 0; i < 3; i++) {
        final x = 60.0 + i * 112;
        box(x + 29, 95, 14, 87, wood, 4);
        oval(x - 8, 43, 97, 80, dark);
        oval(x + 17, 30, 66, 66, green);
        for (var j = 0; j < 5; j++) {
          oval(
            x + 12 + (j % 3) * 22,
            65.0 + (j ~/ 3) * 25,
            9,
            12,
            const Color(0xFF354C2E),
          );
        }
      }
      box(161, 181, 76, 27, wood, 5);
      oval(169, 184, 11, 12, dark);
      oval(188, 189, 11, 12, dark);
      oval(209, 184, 11, 12, dark);
    } else if (world == 'chicken') {
      box(132, 80, 139, 109, wood, 5);
      final roof = Path()
        ..moveTo(116, 85)
        ..lineTo(200, 28)
        ..lineTo(286, 85)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFFB66E55));
      box(176, 119, 44, 70, const Color(0xFF785B3F), 18);
      box(145, 98, 24, 22, const Color(0xFFFFDEA0), 3);
      box(242, 186, 73, 9, wood, 2);
      for (var i = 0; i < 2; i++) {
        final x = 65.0 + i * 243;
        oval(x, 151, 45, 36, const Color(0xFFFFF8EB));
        oval(x + 27, 134, 24, 25, const Color(0xFFFFF8EB));
        oval(x + 30, 129, 14, 9, const Color(0xFFD77860));
        oval(x + 39, 142, 3, 3, dark);
        final beak = Path()
          ..moveTo(x + 49, 144)
          ..lineTo(x + 60, 149)
          ..lineTo(x + 49, 152);
        c.drawPath(beak, Paint()..color = gold);
        box(x + 14, 182, 3, 13, gold, 1);
        box(x + 29, 182, 3, 13, gold, 1);
      }
    } else {
      for (var i = 0; i < 3; i++) {
        final x = 45.0 + i * 110;
        box(x, 164, 83, 33, wood, 4);
        box(x + 5, 161, 73, 13, const Color(0xFF795548), 3);
        box(x + 36, 85 - progress * 25, 6, 78 + progress * 25, green, 2);
        oval(x + 15, 110, 25, 16, green);
        oval(x + 39, 97, 29, 18, dark);
        if (i == 0) {
          oval(x + 23, 79, 17, 17, const Color(0xFFD97658));
          oval(x + 46, 90, 17, 17, const Color(0xFFD97658));
        } else if (i == 1) {
          for (var j = 0; j < 6; j++) {
            final a = j * math.pi / 3;
            oval(
              x + 31 + math.cos(a) * 18,
              57 + math.sin(a) * 18,
              23,
              23,
              gold,
            );
          }
          oval(x + 34, 63, 18, 18, wood);
        } else {
          oval(x + 17, 128, 21, 14, green);
          oval(x + 44, 133, 20, 12, green);
        }
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(WorldPainter old) =>
      old.world != world || old.progress != progress || old.time != time;
}
