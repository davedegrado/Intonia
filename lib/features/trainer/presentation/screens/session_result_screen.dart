import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/l10n.dart';
import '../../../../core/session/session_record.dart';
import '../../../mascot/presentation/confetti.dart';
import '../../../mascot/presentation/intonia_mascot.dart';
import '../../domain/session_result.dart';

/// Scelta dell'utente sulla schermata di fine esercizio.
enum SessionResultAction { done, repeat }

/// Fine esercizio a schermo intero: la mascotte commenta com'è andata e
/// mostra la precisione (la stessa percentuale del profilo).
class SessionResultScreen extends StatefulWidget {
  const SessionResultScreen({required this.record, super.key});

  final SessionRecord record;

  /// Transizione a dissolvenza, a schermo intero sopra il trainer.
  static Route<SessionResultAction> route(SessionRecord record) {
    return PageRouteBuilder<SessionResultAction>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => SessionResultScreen(record: record),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen>
    with SingleTickerProviderStateMixin {
  static const _background = [Color(0xFF1B1640), Color(0xFF03011A)];
  static const _cyan = Color(0xFF22D3EE);
  static const _violet = Color(0xFFA855F7);
  static const _magenta = Color(0xFFEC4899);

  /// Conteggio della percentuale, comparsa dei contenuti e coriandoli.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final percent = record.accuracyPercent;
    final tier = ResultTier.of(percent);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final count = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    );
    final reveal = CurvedAnimation(parent: _intro, curve: const Interval(0, 0.3));
    final details = CurvedAnimation(parent: _intro, curve: const Interval(0.45, 0.75));

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _background,
          ),
        ),
        child: Stack(
          children: [
            if (tier.celebrates)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: ConfettiPainter(_intro)),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: reveal,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.6, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _intro,
                            curve: const Interval(0, 0.35, curve: Curves.elasticOut),
                          ),
                        ),
                        child: IntoniaMascot(
                          mood: tier.mood,
                          size: 160,
                          interactive: true,
                          semanticLabel: l10n.mascotSemanticLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: reveal,
                      child: Column(
                        children: [
                          Text(
                            tier.title(l10n),
                            key: const ValueKey('result-title'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tier.message(l10n),
                            textAlign: TextAlign.center,
                            style:
                                theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFFC7D2FE)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _AccuracyRing(progress: count, percent: percent),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: details,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _Stat(
                                label: l10n.sessionCorrect,
                                value: '${record.correct}',
                                color: _cyan),
                          ),
                          Expanded(
                            child: _Stat(
                                label: l10n.sessionErrors,
                                value: '${record.errors}',
                                color: _magenta),
                          ),
                          Expanded(
                            child: _Stat(
                              label: l10n.sessionDuration,
                              value: _formatDuration(l10n, record.durationSeconds),
                              color: _violet,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _violet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle:
                              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => Navigator.of(context).pop(SessionResultAction.done),
                        child: Text(l10n.sessionContinue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFC7D2FE)),
                      onPressed: () => Navigator.of(context).pop(SessionResultAction.repeat),
                      icon: const Icon(Icons.replay),
                      label: Text(l10n.sessionRepeat),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(AppLocalizations l10n, int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return minutes > 0 ? '$minutes:${rest.toString().padLeft(2, '0')}' : l10n.sessionSeconds(rest);
  }
}

/// Anello della precisione con la percentuale che conta da 0.
class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({required this.progress, required this.percent});

  final Animation<double> progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Semantics(
      label: l10n.sessionAccuracySemantics(percent),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 170,
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final shown = (percent * progress.value).round();
            return CustomPaint(
              painter: _RingPainter(fraction: percent / 100 * progress.value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$shown%',
                      key: const ValueKey('result-percent'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.sessionAccuracy,
                      style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFFC7D2FE)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.1),
    );
    if (fraction <= 0) {
      return;
    }
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF22D3EE)],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.fraction != fraction;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(value,
              style:
                  theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFFC7D2FE))),
        ],
      ),
    );
  }
}
