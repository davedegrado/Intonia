import 'package:flutter/material.dart';

import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../../../core/session/range_record.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/confetti.dart';
import '../../mascot/presentation/intonia_mascot.dart';

/// Scelta dell'utente sul riepilogo del test di estensione.
enum RangeResultAction { done, retry }

/// Confronto con il test precedente.
enum RangeComparison {
  first('Ecco la tua estensione!'),
  better('Nuovo record!'),
  same('Estensione confermata!'),
  worse('Ecco la tua estensione di oggi');

  const RangeComparison(this.title);

  final String title;

  bool get celebrates => this == first || this == better;

  static RangeComparison of(int span, int? previousSpan) {
    if (previousSpan == null) {
      return first;
    }
    return span > previousSpan
        ? better
        : span == previousSpan
            ? same
            : worse;
  }
}

/// Riepilogo a schermo intero del test di estensione: la mascotte presenta
/// il range trovato, che si apre su una piccola tastiera dalla nota di
/// partenza fino alla più grave e alla più acuta.
class RangeResultScreen extends StatefulWidget {
  const RangeResultScreen({
    required this.lowestMidi,
    required this.highestMidi,
    required this.startMidi,
    required this.notation,
    this.previousSpan,
    super.key,
  });

  final int lowestMidi;
  final int highestMidi;
  final int startMidi;
  final NoteNotation notation;

  /// Ampiezza in semitoni del test precedente, se c'è.
  final int? previousSpan;

  int get span => highestMidi - lowestMidi;

  static Route<RangeResultAction> route(RangeResultScreen screen) {
    return PageRouteBuilder<RangeResultAction>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<RangeResultScreen> createState() => _RangeResultScreenState();
}

class _RangeResultScreenState extends State<RangeResultScreen> with SingleTickerProviderStateMixin {
  static const _background = [Color(0xFF1B1640), Color(0xFF03011A)];
  static const _soft = Color(0xFFC7D2FE);
  static const _violet = Color(0xFFA855F7);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
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
    final theme = Theme.of(context);
    final comparison = RangeComparison.of(widget.span, widget.previousSpan);
    final reveal = CurvedAnimation(parent: _intro, curve: const Interval(0, 0.3));
    final opening = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    final details = CurvedAnimation(parent: _intro, curve: const Interval(0.55, 0.8));
    final delta = widget.previousSpan == null ? null : widget.span - widget.previousSpan!;
    final noteStyle = theme.textTheme.displaySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

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
            if (comparison.celebrates)
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: ConfettiPainter(_intro))),
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
                        child: const IntoniaMascot(mood: MascotMood.success, size: 140),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: reveal,
                      child: Text(
                        comparison.title,
                        key: const ValueKey('range-result-title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: opening,
                      builder: (context, _) {
                        final t = opening.value;
                        final low = widget.startMidi + (widget.lowestMidi - widget.startMidi) * t;
                        final high = widget.startMidi + (widget.highestMidi - widget.startMidi) * t;
                        final shownSpan = (widget.span * t).round();
                        return Column(
                          children: [
                            SizedBox(
                              height: 74,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _KeyboardRangePainter(
                                  lowest: widget.lowestMidi,
                                  highest: widget.highestMidi,
                                  start: widget.startMidi,
                                  shownLow: low,
                                  shownHigh: high,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            NoteRangeText(
                              low: spelledMidi(low.round()),
                              high: spelledMidi(high.round()),
                              notation: widget.notation,
                              style: noteStyle,
                              octaveColor: _soft,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatSpan(shownSpan)} ($shownSpan semitoni)',
                              key: const ValueKey('range-result-span'),
                              style: theme.textTheme.titleMedium?.copyWith(color: _soft),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (delta != null)
                      FadeTransition(
                        opacity: details,
                        child: Text(
                          delta > 0
                              ? '+$delta ${delta == 1 ? 'semitono' : 'semitoni'} rispetto all\'ultimo test'
                              : delta == 0
                                  ? 'Stessa ampiezza dell\'ultimo test'
                                  : '$delta ${delta == -1 ? 'semitono' : 'semitoni'} rispetto all\'ultimo test: capita, la voce cambia di giorno in giorno',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: delta > 0 ? const Color(0xFF34D399) : _soft,
                            fontWeight: FontWeight.w700,
                          ),
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
                        onPressed: () => Navigator.of(context).pop(RangeResultAction.done),
                        child: const Text('Continua'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: _soft),
                      onPressed: () => Navigator.of(context).pop(RangeResultAction.retry),
                      icon: const Icon(Icons.replay),
                      label: const Text('Riprova il test'),
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
}

/// Piccola tastiera con il range evidenziato, che si apre dalla nota di
/// partenza ([shownLow]–[shownHigh] animati) fino al risultato.
class _KeyboardRangePainter extends CustomPainter {
  _KeyboardRangePainter({
    required this.lowest,
    required this.highest,
    required this.start,
    required this.shownLow,
    required this.shownHigh,
  });

  final int lowest;
  final int highest;
  final int start;
  final double shownLow;
  final double shownHigh;

  static const _blackSemitones = {1, 3, 6, 8, 10};
  static const _colors = [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFEC4899)];

  @override
  void paint(Canvas canvas, Size size) {
    // Ottave intere attorno al range (almeno DO3–SI4).
    final first = ((lowest < 48 ? lowest : 48) ~/ 12) * 12;
    final last = ((highest > 71 ? highest : 71) ~/ 12) * 12 + 11;
    final whites = [
      for (var m = first; m <= last; m++)
        if (!_blackSemitones.contains(m % 12)) m,
    ];
    final keyWidth = size.width / whites.length;
    final whiteIndex = {for (var i = 0; i < whites.length; i++) whites[i]: i};
    final gradient = LinearGradient(colors: _colors).createShader(Offset.zero & size);

    bool lit(int midi) => midi >= shownLow.round() && midi <= shownHigh.round();

    // Tasti bianchi.
    for (var i = 0; i < whites.length; i++) {
      final rect = Rect.fromLTWH(i * keyWidth + 0.5, 0, keyWidth - 1, size.height);
      final paint = Paint();
      if (lit(whites[i])) {
        paint.shader = gradient;
      } else {
        paint.color = Colors.white.withValues(alpha: 0.85);
      }
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect,
            bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3)),
        paint,
      );
    }
    // Tasti neri.
    for (var m = first; m <= last; m++) {
      if (!_blackSemitones.contains(m % 12)) {
        continue;
      }
      final left = whiteIndex[m - 1];
      if (left == null) {
        continue;
      }
      final x = (left + 1) * keyWidth - keyWidth * 0.3;
      final rect = Rect.fromLTWH(x, 0, keyWidth * 0.6, size.height * 0.6);
      final paint = Paint();
      if (lit(m)) {
        paint.shader = gradient;
      } else {
        paint.color = const Color(0xFF16162B);
      }
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
    }
    // Nota di partenza.
    final startX = whiteIndex.containsKey(start)
        ? (whiteIndex[start]! + 0.5) * keyWidth
        : (whiteIndex[start - 1]! + 1) * keyWidth;
    canvas.drawCircle(
      Offset(startX, size.height - 10),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_KeyboardRangePainter oldDelegate) =>
      oldDelegate.shownLow != shownLow || oldDelegate.shownHigh != shownHigh;
}
