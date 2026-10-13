import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../domain/mascot_mood.dart';

/// Mascotte di Intonia: un diapason antropomorfo con occhi, bocca, piccoli
/// arti ed effetti luminosi neon (ciano, blu, viola, magenta).
///
/// Disegnata interamente con [CustomPainter], senza asset né dipendenze: le
/// parti (corpo, occhi, bocca, braccia, onde, scintille) sono parametri della
/// posa e si animano separatamente. Il cambio di [mood] è interpolato.
///
/// Con le animazioni di sistema disattivate (accessibilità) la mascotte resta
/// ferma nella posa del suo stato.
///
/// Oltre allo stato di base [mood] può mostrare reazioni temporanee:
/// [reaction] (eventi dell'app), il saluto iniziale ([greetOnAppear]) e una
/// piccola festa quando viene toccata ([interactive]).
class IntoniaMascot extends StatefulWidget {
  const IntoniaMascot({
    this.mood = MascotMood.idle,
    this.size = 96,
    this.semanticLabel,
    this.reaction,
    this.greetOnAppear = false,
    this.interactive = true,
    super.key,
  });

  /// Stato di base.
  final MascotMood mood;

  /// Reazione temporanea; ne parte una nuova quando cambia il suo id.
  final MascotReaction? reaction;

  /// Saluta con la mano quando compare.
  final bool greetOnAppear;

  /// Se true, toccandola fa un saltello di gioia.
  final bool interactive;

  /// Lato del riquadro quadrato occupato dalla mascotte.
  final double size;

  /// Etichetta per l'accessibilità; se null la mascotte è decorativa.
  final String? semanticLabel;

  @override
  State<IntoniaMascot> createState() => _IntoniaMascotState();
}

class _IntoniaMascotState extends State<IntoniaMascot> with TickerProviderStateMixin {
  /// Ciclo continuo dei movimenti (oscillazione, vibrazione, onde).
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Transizione tra la posa precedente e quella nuova a ogni cambio di stato.
  late final AnimationController _change = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );

  late MascotMood _previousMood = widget.mood;
  late MascotMood _shownMood = widget.mood;
  MascotMood? _reactionMood;
  Timer? _reactionTimer;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    // Una reazione già presente al montaggio è un evento passato: non si
    // ripete. Il saluto iniziale sì.
    if (widget.greetOnAppear) {
      _react(MascotMood.greeting, const Duration(milliseconds: 1800), animate: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsDisabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncLoop();
  }

  @override
  void didUpdateWidget(IntoniaMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reaction = widget.reaction;
    if (reaction != null && reaction != oldWidget.reaction) {
      _react(reaction.mood, reaction.duration);
    } else if (oldWidget.mood != widget.mood) {
      _showMood();
    }
  }

  /// Stato effettivamente mostrato: la reazione in corso, se c'è, altrimenti
  /// lo stato di base.
  MascotMood get _effectiveMood => _reactionMood ?? widget.mood;

  void _react(MascotMood mood, Duration duration, {bool animate = true}) {
    _reactionTimer?.cancel();
    _reactionMood = mood;
    _reactionTimer = Timer(duration, () {
      if (!mounted) {
        return;
      }
      setState(() => _reactionMood = null);
      _showMood();
    });
    if (animate) {
      _showMood();
    } else {
      _shownMood = mood;
      _previousMood = mood;
    }
  }

  /// Avvia la transizione verso lo stato effettivo, se è cambiato.
  void _showMood() {
    final next = _effectiveMood;
    if (next == _shownMood) {
      return;
    }
    _previousMood = _shownMood;
    _shownMood = next;
    if (_animationsDisabled) {
      _change.value = 1;
    } else {
      _change.forward(from: 0);
    }
  }

  void _handleTap() {
    setState(() => _react(MascotMood.success, const Duration(milliseconds: 1200)));
    // Riparte la transizione anche se era già contenta: rifà il saltello.
    if (!_animationsDisabled) {
      _change.forward(from: 0);
    }
  }

  void _syncLoop() {
    if (_animationsDisabled) {
      _loop.stop();
      _loop.value = 0;
      _change.value = 1;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _loop.dispose();
    _change.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;
    final mascot = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: MascotPainter(
          loop: _loop,
          change: _change,
          mood: _shownMood,
          previousMood: _previousMood,
          onDark: onDark,
        ),
      ),
    );
    final interactive = widget.interactive
        ? GestureDetector(behavior: HitTestBehavior.opaque, onTap: _handleTap, child: mascot)
        : mascot;
    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: interactive)
        : Semantics(label: label, image: true, child: interactive);
  }
}

/// Parametri della posa in un riquadro logico 100×100.
@immutable
class MascotPose {
  const MascotPose({
    required this.dy,
    required this.tilt,
    required this.glow,
    required this.jitter,
    required this.smile,
    required this.happyEyes,
    required this.eyeOpen,
    required this.leftArm,
    required this.rightArm,
    required this.waves,
    required this.sparkles,
    this.lookX = 0,
  });

  /// Spostamento verticale (negativo = in alto).
  final double dy;

  /// Inclinazione in radianti attorno alla base.
  final double tilt;

  /// Intensità del bagliore 0..1.
  final double glow;

  /// Spostamento laterale delle punte del diapason (vibrazione).
  final double jitter;

  /// Ampiezza del sorriso 0..1.
  final double smile;

  /// 0 = occhi ovali, 1 = occhi "felici" ad arco.
  final double happyEyes;

  /// 1 = occhi aperti, 0 = chiusi (battito di ciglia).
  final double eyeOpen;

  /// Sollevamento delle braccia in radianti (0 = rilassate verso il basso).
  final double leftArm;
  final double rightArm;

  /// Intensità delle onde sonore 0..1.
  final double waves;

  /// Intensità delle scintille 0..1.
  final double sparkles;

  /// Spostamento orizzontale dello sguardo (occhi), in unità logiche.
  final double lookX;

  /// Posa dello stato [mood] all'istante [t] del ciclo (0..1).
  factory MascotPose.of(MascotMood mood, double t) {
    final phase = 2 * math.pi * t;
    switch (mood) {
      case MascotMood.idle:
        return MascotPose(
          dy: math.sin(phase) * 1.2,
          tilt: math.sin(phase) * 0.04,
          glow: 0.55 + 0.1 * math.sin(phase),
          jitter: 0,
          smile: 0.45,
          happyEyes: 0,
          eyeOpen: _blink(t),
          leftArm: 0.15 + 0.08 * math.sin(phase),
          rightArm: 0.15 + 0.08 * math.sin(phase + math.pi),
          waves: 0,
          sparkles: 0,
          lookX: _glance(t),
        );
      case MascotMood.listening:
        return MascotPose(
          dy: math.sin(phase * 2) * 0.6,
          tilt: 0,
          glow: 0.78 + 0.1 * math.sin(phase * 2),
          // ~10 Hz: vibrazione visibile ma non frenetica.
          jitter: 1.1 * math.sin(phase * 24),
          smile: 0.35,
          happyEyes: 0,
          eyeOpen: _blink(t),
          leftArm: 0.45,
          rightArm: 0.45,
          waves: 1,
          sparkles: 0,
        );
      case MascotMood.success:
        return MascotPose(
          dy: -(math.sin(phase * 2).abs()) * 3,
          tilt: math.sin(phase * 2) * 0.05,
          glow: 1,
          jitter: 0,
          smile: 1,
          happyEyes: 1,
          eyeOpen: 1,
          leftArm: 1.25 + 0.15 * math.sin(phase * 2),
          rightArm: 1.25 + 0.15 * math.sin(phase * 2 + math.pi),
          waves: 0,
          sparkles: 1,
        );
      case MascotMood.retry:
        return MascotPose(
          dy: math.sin(phase) * 0.8,
          tilt: -0.14 + 0.02 * math.sin(phase),
          glow: 0.6,
          jitter: 0,
          smile: 0.25,
          happyEyes: 0,
          eyeOpen: _blink(t),
          leftArm: -0.1,
          rightArm: 0.9 + 0.2 * math.sin(phase * 2),
          waves: 0,
          sparkles: 0,
          lookX: -0.8,
        );
      case MascotMood.greeting:
        return MascotPose(
          dy: -(math.sin(phase * 2).abs()) * 1.2,
          tilt: 0.06 + 0.03 * math.sin(phase * 4),
          glow: 0.85,
          jitter: 0,
          smile: 0.85,
          happyEyes: 0.7,
          eyeOpen: 1,
          leftArm: 0.2,
          // Saluto: il braccio destro alzato oscilla avanti e indietro.
          rightArm: 1.45 + 0.4 * math.sin(phase * 5),
          waves: 0,
          sparkles: 0.35,
        );
    }
  }

  /// Sguardo che si sposta ogni tanto a destra e a sinistra (a riposo).
  static double _glance(double t) {
    if (t >= 0.2 && t < 0.42) {
      return -1.2 * math.sin((t - 0.2) / 0.22 * math.pi);
    }
    if (t >= 0.55 && t < 0.77) {
      return 1.2 * math.sin((t - 0.55) / 0.22 * math.pi);
    }
    return 0;
  }

  /// Battito di ciglia breve verso la fine di ogni ciclo.
  static double _blink(double t) {
    const start = 0.92, end = 0.98;
    if (t < start || t > end) {
      return 1;
    }
    final k = (t - start) / (end - start);
    return (1 - math.sin(k * math.pi)).clamp(0.08, 1.0);
  }

  static MascotPose lerp(MascotPose a, MascotPose b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return MascotPose(
      dy: l(a.dy, b.dy),
      tilt: l(a.tilt, b.tilt),
      glow: l(a.glow, b.glow),
      jitter: l(a.jitter, b.jitter),
      smile: l(a.smile, b.smile),
      happyEyes: l(a.happyEyes, b.happyEyes),
      eyeOpen: l(a.eyeOpen, b.eyeOpen),
      leftArm: l(a.leftArm, b.leftArm),
      rightArm: l(a.rightArm, b.rightArm),
      waves: l(a.waves, b.waves),
      sparkles: l(a.sparkles, b.sparkles),
      lookX: l(a.lookX, b.lookX),
    );
  }
}

/// Disegna la mascotte; si ridisegna da solo quando [loop] o [change]
/// avanzano, senza ricostruire il widget.
class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.loop,
    required this.change,
    required this.mood,
    required this.previousMood,
    required this.onDark,
  }) : super(repaint: Listenable.merge([loop, change]));

  final Animation<double> loop;
  final Animation<double> change;
  final MascotMood mood;
  final MascotMood previousMood;
  final bool onDark;

  static const cyan = Color(0xFF22D3EE);
  static const blue = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
  static const magenta = Color(0xFFE879F9);
  static const _core = Color(0xFFF5F3FF);
  static const _ink = Color(0xFF1E1B4B);

  /// Posa corrente, interpolata tra lo stato precedente e quello attuale.
  MascotPose get pose {
    final t = loop.value;
    final k = Curves.easeOutCubic.transform(change.value.clamp(0.0, 1.0));
    final target = MascotPose.of(mood, t);
    if (k >= 1 || previousMood == mood) {
      return target;
    }
    return MascotPose.lerp(MascotPose.of(previousMood, t), target, k);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.scale(s);

    // Saltello extra all'ingresso nello stato di successo.
    final hop = mood == MascotMood.success || mood == MascotMood.greeting
        ? -math.sin(math.pi * change.value.clamp(0.0, 1.0)) * 6
        : 0.0;
    canvas.translate(0, p.dy + hop);
    // Rotazione attorno alla base (la sfera).
    const pivot = Offset(50, 86);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(p.tilt);
    canvas.translate(-pivot.dx, -pivot.dy);

    final gradient = const LinearGradient(colors: [cyan, blue, violet, magenta])
        .createShader(const Rect.fromLTRB(18, 10, 82, 90));

    _paintWaves(canvas, p);
    _paintArms(canvas, p);
    _paintBody(canvas, p, gradient);
    _paintFace(canvas, p);
    _paintSparkles(canvas, p);

    canvas.restore();
  }

  Path _bodyPath(double jitter) {
    return Path()
      ..moveTo(33 - jitter, 13)
      ..lineTo(33, 50)
      ..arcTo(Rect.fromCircle(center: const Offset(50, 50), radius: 17), math.pi, -math.pi, false)
      ..lineTo(67 + jitter, 13)
      ..moveTo(50, 67)
      ..lineTo(50, 79);
  }

  void _paintBody(Canvas canvas, MascotPose p, Shader gradient) {
    final body = _bodyPath(p.jitter);
    const ball = Offset(50, 85);

    // Bagliore neon.
    final glowAlpha = (0.30 + 0.55 * p.glow) * (onDark ? 1 : 0.55);
    final blur = MaskFilter.blur(BlurStyle.normal, 3 + 3 * p.glow);
    final glowColor = Colors.white.withValues(alpha: glowAlpha.clamp(0.0, 1.0));
    canvas.drawPath(
      body,
      Paint()
        ..shader = gradient
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..maskFilter = blur,
    );
    canvas.drawCircle(
      ball,
      9,
      Paint()
        ..shader = gradient
        ..color = glowColor
        ..maskFilter = blur,
    );

    // Corpo: tubo neon con bordo sfumato; su sfondo scuro l'anima è bianca.
    canvas.drawPath(
      body,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(ball, 5.5, Paint()..shader = gradient);
    if (onDark) {
      canvas.drawPath(
        body,
        Paint()
          ..color = _core
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(ball, 3.8, Paint()..color = _core);
    }
  }

  void _paintFace(Canvas canvas, MascotPose p) {
    final ink = onDark ? _core : _ink;
    final happy = p.happyEyes.clamp(0.0, 1.0);

    // Occhi ovali (con battito di ciglia).
    if (happy < 1) {
      final eyePaint = Paint()..color = ink.withValues(alpha: 1 - happy);
      final h = 6.2 * p.eyeOpen.clamp(0.08, 1.0);
      for (final x in const [44.5, 55.5]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + p.lookX, 44), width: 4.4, height: h),
          eyePaint,
        );
      }
    }
    // Occhi felici ad arco.
    if (happy > 0) {
      final arc = Paint()
        ..color = ink.withValues(alpha: happy)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (final x in const [44.5, 55.5]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 2.6, 45)
            ..quadraticBezierTo(x, 41, x + 2.6, 45),
          arc,
        );
      }
    }

    // Bocca: arco che si allarga con il sorriso.
    final w = 7 + 5 * p.smile;
    final depth = 1 + 4.5 * p.smile;
    canvas.drawPath(
      Path()
        ..moveTo(50 - w / 2, 52)
        ..quadraticBezierTo(50, 52 + depth * 1.6, 50 + w / 2, 52),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintArms(Canvas canvas, MascotPose p) {
    void arm(Offset shoulder, double angle, Color color, double bend) {
      final dir = Offset(math.cos(angle), -math.sin(angle));
      final normal = Offset(-dir.dy, dir.dx);
      final hand = shoulder + dir * 15;
      final control = shoulder + dir * 8 + normal * bend;
      final path = Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(control.dx, control.dy, hand.dx, hand.dy);
      final glow = Paint()
        ..color = color.withValues(alpha: (0.25 + 0.4 * p.glow) * (onDark ? 1 : 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, glow);
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, stroke);
      canvas.drawCircle(hand, 2.9, Paint()..color = color);
    }

    arm(const Offset(30, 48), math.pi + 0.35 - p.leftArm, cyan, 3);
    arm(const Offset(70, 48), -0.35 + p.rightArm, magenta, -3);
  }

  void _paintWaves(Canvas canvas, MascotPose p) {
    if (p.waves <= 0.01) {
      return;
    }
    const center = Offset(50, 40);
    for (var k = 0; k < 3; k++) {
      final phase = (loop.value * 2 + k / 3) % 1.0;
      final radius = 22 + phase * 16;
      final alpha = (p.waves * (1 - phase) * 0.85).clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          rect, math.pi - 0.55, 1.1, false, paint..color = cyan.withValues(alpha: alpha));
      canvas.drawArc(rect, -0.55, 1.1, false, paint..color = magenta.withValues(alpha: alpha));
    }
  }

  void _paintSparkles(Canvas canvas, MascotPose p) {
    if (p.sparkles <= 0.01) {
      return;
    }
    const spots = [Offset(16, 20), Offset(84, 14), Offset(88, 50), Offset(12, 54)];
    const colors = [cyan, magenta, violet, blue];
    for (var i = 0; i < spots.length; i++) {
      final pulse = 0.6 + 0.4 * math.sin(2 * math.pi * (loop.value * 2 + i / 4));
      final r = 6 * pulse * p.sparkles;
      final c = spots[i];
      final star = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(star, Paint()..color = colors[i].withValues(alpha: p.sparkles));
    }
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.previousMood != previousMood ||
      oldDelegate.onDark != onDark ||
      oldDelegate.loop != loop ||
      oldDelegate.change != change;
}
