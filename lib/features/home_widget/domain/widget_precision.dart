import '../../../core/session/session_record.dart';
import 'widget_streak.dart';

/// Totali di un giorno per il widget della precisione.
class DayTotals {
  const DayTotals({required this.correct, required this.attempts, required this.sessions});

  /// Note cantate correttamente.
  final int correct;

  /// Note valutate (corrette + errori).
  final int attempts;

  /// Sessioni registrate (anche senza note valutate).
  final int sessions;

  @override
  bool operator ==(Object other) =>
      other is DayTotals &&
      other.correct == correct &&
      other.attempts == attempts &&
      other.sessions == sessions;

  @override
  int get hashCode => Object.hash(correct, attempts, sessions);
}

/// Dati condivisi con il widget nativo della precisione: i totali per giorno
/// dal lunedì della settimana scorsa a oggi. Il widget ricava da solo la
/// settimana in corso, così resta corretto anche ad app chiusa (cambio di
/// giorno o di settimana).
class WidgetPrecisionData {
  const WidgetPrecisionData(this.days);

  static const empty = WidgetPrecisionData({});

  /// Giorno locale `yyyy-MM-dd` → totali.
  final Map<String, DayTotals> days;

  /// Ogni nota pesa uguale: si sommano note corrette e valutate. La stessa
  /// sessione salvata due volte (stesso istante ed esercizio) conta una volta.
  factory WidgetPrecisionData.fromSessions(Iterable<SessionRecord> sessions, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(today.year, today.month, today.day - (today.weekday - 1) - 7);
    final seen = <String>{};
    final totals = <String, (int, int, int)>{};
    for (final session in sessions) {
      if (!seen.add('${session.timestamp.toIso8601String()}|${session.exerciseId}')) {
        continue;
      }
      final local = session.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(from) || day.isAfter(today)) {
        continue;
      }
      final key = WidgetStreakData.formatDay(day);
      final (correct, attempts, count) = totals[key] ?? (0, 0, 0);
      totals[key] = (correct + session.correct, attempts + session.totalAttempts, count + 1);
    }
    return WidgetPrecisionData({
      for (final entry in totals.entries)
        entry.key: DayTotals(
          correct: entry.value.$1,
          attempts: entry.value.$2,
          sessions: entry.value.$3,
        ),
    });
  }

  /// Formato letto dal codice nativo: `giorno:corrette:valutate:sessioni`
  /// separati da `;`, in ordine di data.
  String encode() {
    final keys = days.keys.toList()..sort();
    return [
      for (final key in keys)
        '$key:${days[key]!.correct}:${days[key]!.attempts}:${days[key]!.sessions}',
    ].join(';');
  }

  static WidgetPrecisionData decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return empty;
    }
    final days = <String, DayTotals>{};
    for (final item in raw.split(';')) {
      final parts = item.split(':');
      if (parts.length != 4) {
        continue;
      }
      final numbers = parts.skip(1).map(int.tryParse).toList();
      if (numbers.any((n) => n == null || n < 0)) {
        continue;
      }
      days[parts[0]] =
          DayTotals(correct: numbers[0]!, attempts: numbers[1]!, sessions: numbers[2]!);
    }
    return WidgetPrecisionData(days);
  }

  @override
  bool operator ==(Object other) => other is WidgetPrecisionData && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// Stato di un giorno nel widget della precisione.
enum PrecisionDayStatus {
  /// Note valutate: la precisione del giorno c'è.
  measured,

  /// Sessioni senza note valutate (es. interrotte subito).
  activityOnly,

  /// Nessuna sessione.
  empty,

  /// Giorno non ancora arrivato.
  future,
}

enum PrecisionMessage { empty, improved, high, mid, low }

/// Contenuto del widget della precisione: settimana in corso da lunedì a
/// domenica (ora locale). Stessa logica nel codice nativo
/// (IntoniaPrecisionWidgetProvider.kt, IntoniaWidget.swift).
class PrecisionWidgetView {
  const PrecisionWidgetView({
    required this.days,
    required this.dayPercents,
    required this.todayIndex,
    required this.percent,
    required this.previousPercent,
    required this.message,
  });

  /// Sette giorni, da lunedì (indice 0) a domenica.
  final List<PrecisionDayStatus> days;

  /// Precisione di ogni giorno misurato (null altrimenti).
  final List<int?> dayPercents;
  final int todayIndex;

  /// Precisione media della settimana; null se nessuna nota valutata.
  final int? percent;
  final int? previousPercent;
  final PrecisionMessage message;

  factory PrecisionWidgetView.of(WidgetPrecisionData data, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = today.weekday - 1;
    // Date costruite per giorno di calendario: l'ora legale non sposta nulla.
    DateTime day(int offset) => DateTime(today.year, today.month, today.day - todayIndex + offset);

    int? percentOf(int correct, int attempts) =>
        attempts == 0 ? null : (correct * 100 / attempts).round();

    var previousCorrect = 0;
    var previousAttempts = 0;
    for (var i = -7; i < 0; i++) {
      final totals = data.days[WidgetStreakData.formatDay(day(i))];
      previousCorrect += totals?.correct ?? 0;
      previousAttempts += totals?.attempts ?? 0;
    }

    var correct = 0;
    var attempts = 0;
    final days = <PrecisionDayStatus>[];
    final dayPercents = <int?>[];
    for (var i = 0; i < 7; i++) {
      final totals = i > todayIndex ? null : data.days[WidgetStreakData.formatDay(day(i))];
      correct += totals?.correct ?? 0;
      attempts += totals?.attempts ?? 0;
      days.add(i > todayIndex
          ? PrecisionDayStatus.future
          : totals == null || totals.sessions == 0
              ? PrecisionDayStatus.empty
              : totals.attempts > 0
                  ? PrecisionDayStatus.measured
                  : PrecisionDayStatus.activityOnly);
      dayPercents.add(totals == null ? null : percentOf(totals.correct, totals.attempts));
    }
    final percent = percentOf(correct, attempts);
    final previous = percentOf(previousCorrect, previousAttempts);
    return PrecisionWidgetView(
      days: days,
      dayPercents: dayPercents,
      todayIndex: todayIndex,
      percent: percent,
      previousPercent: previous,
      message: percent == null
          ? PrecisionMessage.empty
          : previous != null && percent > previous
              ? PrecisionMessage.improved
              : percent >= 80
                  ? PrecisionMessage.high
                  : percent >= 60
                      ? PrecisionMessage.mid
                      : PrecisionMessage.low,
    );
  }
}
