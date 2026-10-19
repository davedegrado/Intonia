import '../../../core/session/session_record.dart';

/// Dati condivisi con il widget nativo (Android/iOS). Il widget ricalcola da
/// solo lo stato del giorno (gira anche quando l'app è chiusa), quindi si
/// salvano il giorno dell'ultimo allenamento e la serie a quella data.
class WidgetStreakData {
  const WidgetStreakData({required this.lastTrainingDay, required this.streakAtLastTraining});

  /// Nessun allenamento registrato.
  static const empty = WidgetStreakData(lastTrainingDay: null, streakAtLastTraining: 0);

  /// Giorno locale dell'ultimo allenamento, formato `yyyy-MM-dd`.
  final String? lastTrainingDay;

  /// Giorni consecutivi di allenamento terminati in [lastTrainingDay].
  final int streakAtLastTraining;

  factory WidgetStreakData.fromSessions(Iterable<DateTime> timestamps) {
    if (timestamps.isEmpty) {
      return empty;
    }
    final last = timestamps.reduce((a, b) => a.isAfter(b) ? a : b);
    return WidgetStreakData(
      lastTrainingDay: formatDay(last),
      streakAtLastTraining: computeStreak(timestamps, last),
    );
  }

  static String formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is WidgetStreakData &&
      other.lastTrainingDay == lastTrainingDay &&
      other.streakAtLastTraining == streakAtLastTraining;

  @override
  int get hashCode => Object.hash(lastTrainingDay, streakAtLastTraining);
}

enum WidgetStatus {
  /// Serie di almeno due giorni, oggi già fatto.
  trainedToday,

  /// Primo giorno della serie, fatto oggi.
  firstDay,

  /// Allenato ieri: la serie è viva ma va allungata oggi.
  keepStreak,

  /// Nessuna serie in corso.
  start,
}

/// Contenuto del widget della serie a una certa data. La stessa logica è
/// replicata nel codice nativo (IntoniaWidgetProvider.kt, IntoniaWidget.swift).
class WidgetView {
  const WidgetView({
    required this.status,
    required this.streak,
    required this.label,
    required this.message,
  });

  final WidgetStatus status;

  /// Giorni di fila mostrati in grande (0 se la serie non è in corso).
  final int streak;

  /// "giorni di fila" accanto al numero, su due righe.
  final String label;
  final String message;

  factory WidgetView.of(WidgetStreakData data, DateTime now) {
    final today = WidgetStreakData.formatDay(now);
    final yesterday = WidgetStreakData.formatDay(DateTime(now.year, now.month, now.day - 1));
    final streak = data.streakAtLastTraining;
    final alive =
        streak > 0 && (data.lastTrainingDay == today || data.lastTrainingDay == yesterday);
    final days = alive ? streak : 0;
    final status = !alive
        ? WidgetStatus.start
        : data.lastTrainingDay == yesterday
            ? WidgetStatus.keepStreak
            : streak == 1
                ? WidgetStatus.firstDay
                : WidgetStatus.trainedToday;
    return WidgetView(
      status: status,
      streak: days,
      label: days == 1 ? 'giorno\ndi fila' : 'giorni\ndi fila',
      message: switch (status) {
        WidgetStatus.trainedToday => 'Continua così, sei sulla strada giusta!',
        WidgetStatus.firstDay => 'Primo giorno: ottimo inizio!',
        WidgetStatus.keepStreak => 'Allenati oggi per non perdere la serie!',
        WidgetStatus.start => 'Inizia oggi la tua serie!',
      },
    );
  }
}
