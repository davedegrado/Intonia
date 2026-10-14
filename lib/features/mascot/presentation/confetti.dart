import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Coriandoli che cadono una volta mentre [animation] va da 0 a 1
/// (schermate di risultato).
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _colors = [
    Color(0xFF22D3EE),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
  ];

  // Particelle deterministiche: stessa pioggia a ogni apertura.
  static final _pieces = List.generate(48, (i) {
    final random = math.Random(i * 7919);
    return (
      x: random.nextDouble(),
      delay: random.nextDouble() * 0.35,
      speed: 0.55 + random.nextDouble() * 0.45,
      drift: (random.nextDouble() - 0.5) * 0.25,
      spin: (random.nextDouble() - 0.5) * 12,
      color: _colors[i % _colors.length],
      wide: random.nextBool(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) {
      return;
    }
    for (final piece in _pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0) {
        continue;
      }
      final y = -20 + (size.height + 40) * local * piece.speed;
      final x = size.width * (piece.x + piece.drift * local);
      final opacity = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: piece.wide ? 10 : 6, height: 6),
          const Radius.circular(2),
        ),
        Paint()..color = piece.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => false;
}
