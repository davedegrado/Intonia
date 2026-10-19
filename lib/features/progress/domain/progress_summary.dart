import '../../../core/session/session_record.dart';

/// Stato di un giorno della settimana nel riepilogo della precisione.
enum DayStatus {
  /// Almeno una sessione con note valutate: la precisione del giorno c'è.
  measured,

  /// Sessioni registrate ma senza note valutate (es. interrotte subito):
  /// attività sì, precisione no.
  activityOnly,

  /// Nessuna sessione.
  empty,

  /// Giorno non ancora arrivato.
  future,
}

class DayPrecision {
  const DayPrecision({
    required this.day,
    required this.status,
    required this.correct,
    required this.attempts,
    required this.isToday,
  });

  /// Mezzanotte locale del giorno.
  final DateTime day;
  final DayStatus status;
  final int correct;
  final int attempts;
  final bool isToday;

  /// Precisione del giorno (0–100) se ci sono note valutate.
  int? get percent => attempts == 0 ? null : (correct * 100 / attempts).round();
}

/// Precisione della settimana in corso (da lunedì a domenica, ora locale).
///
/// "Precisione media" è la stessa misura del Profilo e della fine esercizio:
/// note cantate correttamente diviso note valutate (corrette + errori),
/// sommate su tutte le sessioni della settimana. Ogni nota pesa uguale, così
/// una sessione di due note non vale quanto una di cinquanta. Le sessioni
/// senza note valutate contano come attività ma non entrano nella media.
class WeeklyPrecision {
  const WeeklyPrecision({
    required this.days,
    required this.correct,
    required this.attempts,
    required this.previousPercent,
  });

  /// Sette giorni, da lunedì (indice 0) a domenica.
  final List<DayPrecision> days;
  final int correct;
  final int attempts;

  /// Precisione della settimana precedente, se misurata.
  final int? previousPercent;

  /// Precisione media (0–100); null se questa settimana non ci sono note
  /// valutate.
  int? get percent => attempts == 0 ? null : (correct * 100 / attempts).round();

  bool get hasData => attempts > 0;

  /// Migliorata rispetto alla settimana precedente (entrambe misurate).
  bool get improved => percent != null && previousPercent != null && percent! > previousPercent!;

  factory WeeklyPrecision.from(Iterable<SessionRecord> sessions, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    // Lunedì della settimana in corso; le date si costruiscono per giorno di
    // calendario, così il cambio dell'ora legale non sposta i confini.
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final previousMonday = DateTime(monday.year, monday.month, monday.day - 7);
    final unique = _deduplicate(sessions);

    final perDay = <DateTime, List<SessionRecord>>{};
    var previousCorrect = 0;
    var previousAttempts = 0;
    for (final session in unique) {
      final local = session.timestamp.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (!day.isBefore(monday) && !day.isAfter(today)) {
        perDay.putIfAbsent(day, () => []).add(session);
      } else if (!day.isBefore(previousMonday) && day.isBefore(monday)) {
        previousCorrect += session.correct;
        previousAttempts += session.totalAttempts;
      }
    }

    var correct = 0;
    var attempts = 0;
    final days = <DayPrecision>[];
    for (var i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final mine = perDay[day] ?? const <SessionRecord>[];
      final dayCorrect = mine.fold(0, (sum, s) => sum + s.correct);
      final dayAttempts = mine.fold(0, (sum, s) => sum + s.totalAttempts);
      correct += dayCorrect;
      attempts += dayAttempts;
      days.add(DayPrecision(
        day: day,
        status: day.isAfter(today)
            ? DayStatus.future
            : dayAttempts > 0
                ? DayStatus.measured
                : mine.isNotEmpty
                    ? DayStatus.activityOnly
                    : DayStatus.empty,
        correct: dayCorrect,
        attempts: dayAttempts,
        isToday: day == today,
      ));
    }
    return WeeklyPrecision(
      days: days,
      correct: correct,
      attempts: attempts,
      previousPercent:
          previousAttempts == 0 ? null : (previousCorrect * 100 / previousAttempts).round(),
    );
  }

  /// La stessa sessione salvata due volte (stesso istante ed esercizio)
  /// conta una volta sola.
  static List<SessionRecord> _deduplicate(Iterable<SessionRecord> sessions) {
    final seen = <String>{};
    return [
      for (final session in sessions)
        if (seen.add('${session.timestamp.toIso8601String()}|${session.exerciseId}')) session,
    ];
  }
}

/// Stato della serie per il widget della Home. Il conteggio è quello di
/// sempre ([computeStreak]): giorni consecutivi con almeno una sessione, fino
/// a oggi o a ieri.
enum StreakPhase {
  /// Nessuna serie in corso.
  none,

  /// Serie viva ma oggi non ci si è ancora allenati.
  keepGoing,

  /// Primo giorno della serie, fatto oggi.
  started,

  /// Serie di almeno due giorni, oggi già fatto.
  active,
}

class StreakSummary {
  const StreakSummary({required this.days, required this.phase});

  final int days;
  final StreakPhase phase;

  factory StreakSummary.from(Iterable<SessionRecord> sessions, DateTime now) {
    final timestamps = [for (final s in sessions) s.timestamp.toLocal()];
    final days = computeStreak(timestamps, now);
    final trainedToday =
        timestamps.any((t) => t.year == now.year && t.month == now.month && t.day == now.day);
    final phase = days == 0
        ? StreakPhase.none
        : !trainedToday
            ? StreakPhase.keepGoing
            : days == 1
                ? StreakPhase.started
                : StreakPhase.active;
    return StreakSummary(days: days, phase: phase);
  }
}
