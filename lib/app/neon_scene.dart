import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Composizione del fondale Neon per ciascuna sezione.
enum SceneVariant {
  /// Home: scena attorno alla mascotte, onde sotto di lei.
  home(focus: 0.30, waves: 0.47, hills: true, intensity: 1),

  /// Estensione vocale: mascotte in alto, onde sotto il titolo.
  range(focus: 0.19, waves: 0.235, hills: true, intensity: 0.9),

  /// Elenchi (Esercizi, Profilo): solo luci soffuse e un'onda leggera.
  list(focus: 0.10, waves: 0.13, hills: false, intensity: 0.55);

  const SceneVariant({
    required this.focus,
    required this.waves,
    required this.hills,
    required this.intensity,
  });

  /// Altezza relativa del punto luce principale.
  final double focus;

  /// Altezza relativa delle onde musicali.
  final double waves;
  final bool hills;
  final double intensity;
}

/// Scaffold delle sezioni principali. La struttura (barra in alto, corpo) è
/// identica in tutti i temi; solo in Neon dietro compare il fondale
/// illustrato, che negli altri temi non viene proprio costruito.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    this.variant = SceneVariant.list,
    super.key,
  });

  final String title;
  final List<Widget> actions;
  final Widget body;
  final SceneVariant variant;

  @override
  Widget build(BuildContext context) {
    final ambient = context.decor.ambient;
    final scaffold = Scaffold(
      backgroundColor: ambient ? Colors.transparent : null,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: ambient ? Colors.transparent : null,
      ),
      body: body,
    );
    if (!ambient) {
      return scaffold;
    }
    return Stack(
      children: [
        Positioned.fill(child: NeonBackdrop(variant: variant)),
        scaffold,
      ],
    );
  }
}

/// Fondale Neon: sfumatura notturna, luci, onde musicali, colline, note e
/// scintille. Statico (nessuna animazione) e isolato in un RepaintBoundary.
class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({required this.variant, super.key});

  final SceneVariant variant;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        key: const ValueKey('neon-scene'),
        painter: NeonScenePainter(variant),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class NeonScenePainter extends CustomPainter {
  NeonScenePainter(this.variant);

  final SceneVariant variant;

  static const _cyan = Color(0xFF22D3EE);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFFA855F7);
  static const _magenta = Color(0xFFEC4899);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final k = variant.intensity;
    final rect = Offset.zero & size;

    // Notte: dall'indaco profondo al quasi nero.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181540), Color(0xFF0F0E2A), Color(0xFF0A0A1A)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Luci soffuse.
    void glow(Offset center, double radius, Color color, double alpha) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha * k), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final focusY = h * variant.focus;
    glow(Offset(w * 0.12, focusY - h * 0.08), w * 0.7, _violet, 0.30);
    glow(Offset(w * 0.95, focusY + h * 0.05), w * 0.6, _magenta, 0.18);
    glow(Offset(w * 0.5, focusY), w * 0.55, _indigo, 0.28);
    glow(Offset(0, h * 0.88), w * 0.6, _cyan, 0.10);

    // Colline in silhouette sotto la scena.
    if (variant.hills) {
      final base = h * (variant.waves + 0.04);
      _hill(canvas, size, base, const Color(0xFF221A56), 0.75, 0.18, 0);
      _hill(canvas, size, base + h * 0.025, const Color(0xFF1A1545), 0.85, 0.12, 1.7);
    }

    // Onde musicali.
    final waveY = h * variant.waves;
    final waveRect = Rect.fromLTWH(0, waveY - 40, w, 80);
    Shader waveShader(double alpha) => LinearGradient(
          colors: [
            for (final c in [_cyan, _indigo, _violet, _magenta]) c.withValues(alpha: alpha * k),
          ],
        ).createShader(waveRect);
    for (final (i, wave) in [
      (amp: 16.0, length: 1.15, phase: 0.0, width: 2.4, alpha: 0.75),
      (amp: 22.0, length: 0.85, phase: 1.3, width: 1.6, alpha: 0.5),
      (amp: 11.0, length: 1.45, phase: 2.6, width: 1.2, alpha: 0.4),
    ].indexed) {
      final path = Path();
      for (var x = 0.0; x <= w; x += 4) {
        final y =
            waveY + i * 9 + wave.amp * math.sin(x / (w * wave.length) * 2 * math.pi + wave.phase);
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      if (i == 0) {
        // Alone della prima onda.
        canvas.drawPath(
          path,
          Paint()
            ..shader = waveShader(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = waveShader(wave.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = wave.width,
      );
    }

    // Scintille e note: posizioni fisse (seed costante), niente ricalcoli.
    final random = math.Random(7);
    final sparkleBand = h * (variant.waves + 0.1);
    for (var i = 0; i < (24 * k).round(); i++) {
      final p = Offset(random.nextDouble() * w, random.nextDouble() * sparkleBand);
      canvas.drawCircle(
        p,
        0.8 + random.nextDouble() * 1.6,
        Paint()..color = Colors.white.withValues(alpha: (0.2 + random.nextDouble() * 0.5) * k),
      );
    }
    for (final (dx, dy, color, scale) in [
      (0.12, -0.10, _cyan, 1.0),
      (0.86, -0.06, _magenta, 0.8),
      (0.80, 0.08, _cyan, 0.6),
      (0.20, 0.07, _violet, 0.7),
    ]) {
      _star(canvas, Offset(w * dx, focusY + h * dy), 7 * scale, color.withValues(alpha: 0.8 * k));
    }
    if (variant != SceneVariant.list) {
      _note(canvas, Offset(w * 0.12, focusY - h * 0.04), 26, _cyan.withValues(alpha: 0.75));
      _note(canvas, Offset(w * 0.88, focusY - h * 0.12), 22, _violet.withValues(alpha: 0.7));
      if (variant == SceneVariant.home) {
        _note(canvas, Offset(w * 0.14, focusY + h * 0.12), 20, _magenta.withValues(alpha: 0.6));
      }
    }
  }

  void _hill(Canvas canvas, Size size, double base, Color color, double alpha, double height,
      double phase) {
    final w = size.width;
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= w; x += 6) {
      final y = base -
          size.height *
              0.02 *
              (1 + math.sin(x / w * 2.6 * math.pi + phase) + 0.5 * math.sin(x / w * 7 + phase));
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: alpha), const Color(0xFF0A0A1A).withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, base - size.height * height, w, size.height * 0.5)),
    );
  }

  /// Stella a quattro punte con alone.
  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas
      ..drawCircle(
        c,
        r * 1.6,
        Paint()
          ..color = color.withValues(alpha: color.a * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawPath(path, Paint()..color = color);
  }

  /// Croma stilizzata (testa, gambo, bandiera), disegnata con tracciati.
  void _note(Canvas canvas, Offset at, double size, Color color) {
    final paint = Paint()..color = color;
    final head = Rect.fromCenter(
      center: at + Offset(0, size * 0.35),
      width: size * 0.5,
      height: size * 0.36,
    );
    canvas
      ..drawCircle(
        head.center,
        size * 0.5,
        Paint()
          ..color = color.withValues(alpha: color.a * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..save()
      ..translate(head.center.dx, head.center.dy)
      ..rotate(-0.4)
      ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: head.width, height: head.height), paint)
      ..restore();
    final stemX = head.right - size * 0.04;
    canvas.drawRect(
        Rect.fromLTWH(stemX - size * 0.07, at.dy - size * 0.45, size * 0.07, size * 0.8), paint);
    final flag = Path()
      ..moveTo(stemX, at.dy - size * 0.45)
      ..quadraticBezierTo(stemX + size * 0.35, at.dy - size * 0.25, stemX + size * 0.2, at.dy)
      ..quadraticBezierTo(stemX + size * 0.22, at.dy - size * 0.2, stemX, at.dy - size * 0.25)
      ..close();
    canvas.drawPath(flag, paint);
  }

  @override
  bool shouldRepaint(NeonScenePainter oldDelegate) => oldDelegate.variant != variant;
}

/// Spazio della mascotte: stessa dimensione in tutti i temi; in Neon dietro
/// c'è un alone ciano/blu/magenta e una base luminosa.
class MascotStage extends StatelessWidget {
  const MascotStage({required this.size, required this.child, super.key});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final decor = context.decor;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (decor.ambient) ...[
            Positioned(
              left: -size * 0.25,
              right: -size * 0.25,
              top: -size * 0.2,
              bottom: -size * 0.3,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('mascot-halo'),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF22D3EE).withValues(alpha: 0.28),
                        decor.glow.withValues(alpha: 0.22),
                        const Color(0xFFEC4899).withValues(alpha: 0.10),
                        decor.glow.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.35, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ),
            // Base luminosa su cui "poggia" la mascotte.
            Positioned(
              bottom: -size * 0.04,
              child: IgnorePointer(
                child: Container(
                  width: size * 0.62,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(size * 0.31, size * 0.05)),
                    gradient: RadialGradient(
                      colors: [
                        decor.glow.withValues(alpha: 0.55),
                        decor.glow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

/// Pulsante d'azione principale a tutta larghezza (es. "Avvia test"): stessa
/// forma in tutti i temi, in Neon con sfumatura, bordo ciano e ombra colorata.
class HeroButton extends StatelessWidget {
  const HeroButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final decor = context.decor;
    return Semantics(
      button: true,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: decor.heroGradient,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(
            color: decor.ambient ? decor.heroBorder.withValues(alpha: 0.7) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: decor.ambient
              ? [
                  BoxShadow(
                    color: decor.glow.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(29),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: decor.onHero),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: decor.onHero,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Riquadro icona colorato (categorie, statistiche).
class AccentIcon extends StatelessWidget {
  const AccentIcon({required this.icon, required this.color, this.size = 48, super.key});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ambient = context.decor.ambient;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        color: ambient ? null : color.withValues(alpha: 0.14),
        gradient: ambient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.10)],
              )
            : null,
        border: Border.all(color: ambient ? color.withValues(alpha: 0.45) : Colors.transparent),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
