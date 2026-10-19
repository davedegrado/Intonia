import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../../core/session/session_record.dart';
import '../../access/application/access_providers.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/intonia_mascot.dart';
import '../../profile/application/history_providers.dart';
import '../domain/progress_summary.dart';

/// Palette delle due card illustrate: la notte indaco di Intonia, uguale in
/// tutti i temi (sono illustrazioni, come la scena del tema Neon).
class _Night {
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B57), Color(0xFF241A63), Color(0xFF161443)],
  );
  static const border = Color(0xFF3B3592);
  static const cyan = Color(0xFF5EEAF4);
  static const sky = Color(0xFF7DD3FC);
  static const violet = Color(0xFFA855F7);
  static const magenta = Color(0xFFE879F9);
  static const text = Colors.white;
  static const muted = Color(0xFFC7C9F2);
  static const onDot = Color(0xFF1B1846);

  /// Colore del giorno [index] (0 = lunedì) dal ciano al viola.
  static Color day(int index) => Color.lerp(cyan, violet, index / 6)!;

  static BoxDecoration card(BuildContext context) {
    final glow = context.decor.ambient;
    return BoxDecoration(
      gradient: background,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border.withValues(alpha: 0.9)),
      boxShadow: [
        BoxShadow(
          color:
              (glow ? const Color(0xFF7C5CFA) : Colors.black).withValues(alpha: glow ? 0.28 : 0.18),
          blurRadius: glow ? 22 : 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

List<SessionRecord> _sessions(WidgetRef ref) =>
    ref.watch(sessionHistoryProvider).value ?? const <SessionRecord>[];

/// Widget della serie: la mascotte originale di Intonia a sinistra, tra luce
/// ciano e viola e nuvole, e i giorni di fila in grande a destra. Dati reali
/// ([StreakSummary], stesso conteggio della serie in alto).
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = StreakSummary.from(_sessions(ref), ref.watch(clockProvider)());
    final message = switch (summary.phase) {
      StreakPhase.none => l10n.streakCardStart,
      StreakPhase.keepGoing => l10n.streakCardKeepGoing,
      StreakPhase.started => l10n.streakCardStarted,
      StreakPhase.active => l10n.streakCardActive,
    };

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Più alta della card della precisione; cresce con la larghezza.
      final height = (width * 0.42).clamp(150.0, 200.0);
      final numberSize = height * 0.5;
      return Semantics(
        container: true,
        label: '${l10n.statusStreakSemantics(summary.days)}. $message',
        child: ExcludeSemantics(
          child: Container(
            key: const ValueKey('home-streak'),
            height: height,
            decoration: _Night.card(context),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: math.min(width * 0.5, height * 1.35),
                  child: _MascotScene(height: height, celebrating: summary.days > 0),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 18, 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Il numero si rimpicciolisce (anche in altezza) se il
                        // testo ingrandito non ci starebbe col messaggio.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [_Night.cyan, _Night.sky, Color(0xFF8B9CFA)],
                                  ).createShader(bounds),
                                  child: Text(
                                    '${summary.days}',
                                    key: const ValueKey('home-streak-days'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: numberSize,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                      letterSpacing: -2,
                                      shadows: const [
                                        Shadow(color: Color(0x6622D3EE), blurRadius: 18)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.streakCardDays(summary.days),
                                  style: TextStyle(
                                    color: _Night.text,
                                    fontSize: numberSize * 0.3,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.06),
                        Text(
                          message,
                          key: const ValueKey('home-streak-message'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _Night.muted,
                            fontSize: (numberSize * 0.2).clamp(13.0, 17.0),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Metà illustrata: alone, nuvole viola, poche note e la mascotte originale
/// (sempre quadrata: proporzioni intatte).
class _MascotScene extends StatelessWidget {
  const _MascotScene({required this.height, required this.celebrating});

  final double height;
  final bool celebrating;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final mascot = math.min(height * 0.92, w * 0.8);
      Widget at(double left, double top, Widget child) =>
          Positioned(left: left * w, top: top * height, child: child);
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Alone ciano e viola dietro la mascotte.
          Positioned(
            left: w * 0.5 - mascot * 0.75,
            top: height * 0.5 - mascot * 0.7,
            width: mascot * 1.5,
            height: mascot * 1.4,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x5522D3EE),
                  Color(0x337C5CFA),
                  Color(0x007C5CFA),
                ], stops: [
                  0,
                  0.45,
                  1
                ]),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _CloudsPainter())),
          at(
              0.08,
              0.16,
              Icon(Icons.music_note_rounded,
                  size: height * 0.16, color: _Night.cyan.withValues(alpha: 0.85))),
          at(
              0.22,
              0.30,
              Icon(Icons.music_note_rounded,
                  size: height * 0.09, color: _Night.sky.withValues(alpha: 0.6))),
          at(
              0.80,
              0.12,
              Icon(Icons.favorite_rounded,
                  size: height * 0.13, color: _Night.magenta.withValues(alpha: 0.75))),
          at(
              0.84,
              0.52,
              Icon(Icons.queue_music_rounded,
                  size: height * 0.15, color: _Night.sky.withValues(alpha: 0.75))),
          at(0.06, 0.62, _Sparkle(size: height * 0.05)),
          at(0.70, 0.05, _Sparkle(size: height * 0.04)),
          Positioned(
            left: (w - mascot) / 2,
            top: (height - mascot) / 2 + height * 0.02,
            child: IntoniaMascot(
              key: const ValueKey('home-streak-mascot'),
              mood: celebrating ? MascotMood.success : MascotMood.idle,
              size: mascot,
              interactive: false,
            ),
          ),
        ],
      );
    });
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.8),
          boxShadow: [BoxShadow(color: _Night.cyan.withValues(alpha: 0.8), blurRadius: size * 2)],
        ),
      );
}

/// Nuvole viola morbide nella parte bassa della scena.
class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void cloud(List<(double, double, double)> puffs, Color top, Color bottom) {
      final path = Path();
      for (final (x, y, r) in puffs) {
        path.addOval(Rect.fromCircle(center: Offset(x * w, y * h), radius: r * h));
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4)),
      );
    }

    cloud([(0.05, 1.0, 0.3), (0.28, 0.95, 0.24), (0.48, 1.05, 0.26)], const Color(0xFF5B3FC4),
        const Color(0xFF2B1F78));
    cloud([(0.62, 1.0, 0.24), (0.86, 0.94, 0.26), (1.05, 1.02, 0.28)], const Color(0xFF6A46D6),
        const Color(0xFF33238A));
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => false;
}

/// Widget della precisione settimanale: media della settimana in corso in
/// alto e i sette giorni, da lunedì a domenica, collegati da una linea.
class WeeklyPrecisionCard extends ConsumerWidget {
  const WeeklyPrecisionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final week = WeeklyPrecision.from(_sessions(ref), ref.watch(clockProvider)());
    final percent = week.percent;
    final message = percent == null
        ? l10n.precisionCardEmpty
        : week.improved
            ? l10n.precisionCardImproved
            : percent >= 80
                ? l10n.precisionCardHigh
                : percent >= 60
                    ? l10n.precisionCardMid
                    : l10n.precisionCardLow;
    final names = l10n.weekdaysShort.split(',');

    final title = Row(
      children: [
        const Icon(Icons.graphic_eq_rounded, color: _Night.cyan, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.precisionCardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _Night.text, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    final average = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: percent == null ? l10n.precisionCardEmpty : l10n.precisionCardSemantics(percent),
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                percent == null ? '—' : '$percent%',
                key: const ValueKey('precision-card-percent'),
                style: TextStyle(
                  color: percent == null ? _Night.muted : _Night.cyan,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  shadows: const [Shadow(color: Color(0x5522D3EE), blurRadius: 14)],
                ),
              ),
            ),
          ),
        ),
        Text(l10n.precisionCardPeriod,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _Night.muted, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
    final pill = Container(
      key: const ValueKey('precision-card-message'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Night.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _Night.text, fontSize: 13, fontWeight: FontWeight.w600, height: 1.25),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.music_note_rounded, color: _Night.magenta, size: 20),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      // Su schermi larghi la disposizione della reference: media a sinistra,
      // giorni a destra. Sui telefoni media sopra, giorni sotto.
      final wide = constraints.maxWidth >= 600;
      final days = _WeekRow(week: week, names: names);
      return Container(
        key: const ValueKey('precision-card'),
        decoration: _Night.card(context),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: wide
            ? Row(
                children: [
                  SizedBox(
                    width: math.min(240.0, constraints.maxWidth * 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        title,
                        const SizedBox(height: 2),
                        average,
                        const SizedBox(height: 8),
                        pill,
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(child: days),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  title,
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Il messaggio ha più spazio della media (al massimo
                      // "100%"), che col testo grande si rimpicciolisce.
                      Flexible(flex: 2, child: average),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Align(alignment: Alignment.centerRight, child: pill),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  days,
                ],
              ),
      );
    });
  }
}

/// Sette indicatori collegati da una linea sottile, dal ciano al viola.
/// Ogni stato ha anche un simbolo o un contorno diverso (non solo il colore).
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.names});

  final WeeklyPrecision week;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(builder: (context, constraints) {
      final slot = constraints.maxWidth / 7;
      final dot = math.min(34.0, slot * 0.78);
      const labelStyle = TextStyle(fontSize: 13);
      final labelHeight = MediaQuery.textScalerOf(context).scale(labelStyle.fontSize!) * 1.35;
      return SizedBox(
        height: dot + 6 + labelHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: dot,
              child: CustomPaint(painter: _ConnectorPainter(days: week.days, dot: dot)),
            ),
            Row(
              children: [
                for (final (index, day) in week.days.indexed)
                  SizedBox(
                    width: slot,
                    child: Semantics(
                      label: _semantics(l10n, names[index], day),
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            _DayDot(index: index, day: day, size: dot),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: labelHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  names[index],
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: day.status == DayStatus.future
                                        ? _Night.muted.withValues(alpha: 0.55)
                                        : _Night.text,
                                    fontSize: 13,
                                    fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static String _semantics(AppLocalizations l10n, String name, DayPrecision day) =>
      switch (day.status) {
        DayStatus.measured => l10n.precisionDayMeasured(name, day.percent!),
        DayStatus.activityOnly => l10n.precisionDayActivity(name),
        DayStatus.empty => l10n.precisionDayEmpty(name),
        DayStatus.future => l10n.precisionDayFuture(name),
      };
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.index, required this.day, required this.size});

  final int index;
  final DayPrecision day;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _Night.day(index);
    final key = ValueKey('precision-day-$index-${day.status.name}');
    return switch (day.status) {
      // Precisione misurata: pieno, con la spunta.
      DayStatus.measured => Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color.lerp(color, Colors.white, 0.25)!, color]),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 10)],
          ),
          child: Icon(Icons.check_rounded, size: size * 0.6, color: _Night.onDot),
        ),
      // Allenamento senza note valutate: tenue, con un trattino.
      DayStatus.activityOnly => Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.22),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(Icons.remove_rounded, size: size * 0.55, color: color),
        ),
      // Nessuna attività: vuoto; oggi con un anello più marcato.
      DayStatus.empty => Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF15133C),
            border: Border.all(
              color: day.isToday ? color : _Night.muted.withValues(alpha: 0.4),
              width: day.isToday ? 2.5 : 1.5,
            ),
          ),
        ),
      // Futuro: contorno appena accennato.
      DayStatus.future => Container(
          key: key,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _Night.muted.withValues(alpha: 0.22), width: 1.5),
          ),
        ),
    };
  }
}

/// Linea sottile fra i centri dei giorni: luminosa fra due giorni con
/// attività, tenue altrove.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.days, required this.dot});

  final List<DayPrecision> days;
  final double dot;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / 7;
    final y = dot / 2;
    bool active(DayPrecision d) =>
        d.status == DayStatus.measured || d.status == DayStatus.activityOnly;
    for (var i = 0; i < 6; i++) {
      final from = Offset(slot * (i + 0.5) + dot / 2, y);
      final to = Offset(slot * (i + 1.5) - dot / 2, y);
      if (to.dx <= from.dx) {
        continue;
      }
      final lit = active(days[i]) && active(days[i + 1]);
      final paint = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      if (lit) {
        paint.shader = LinearGradient(colors: [_Night.day(i), _Night.day(i + 1)])
            .createShader(Rect.fromPoints(from, to));
      } else {
        paint.color = _Night.muted.withValues(alpha: 0.18);
      }
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) => old.days != days || old.dot != dot;
}
