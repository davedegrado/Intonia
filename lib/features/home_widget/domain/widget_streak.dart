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
  /// Allenamento di oggi già fatto.
  trainedToday,

  /// Allenato ieri: la serie è viva ma va allungata oggi.
  keepStreak,

  /// Nessuna serie in corso.
  start,
}

/// Contenuto del widget a una certa data. La stessa logica è replicata nel
/// codice nativo (IntoniaWidgetProvider.kt, IntoniaWidget.swift).
class WidgetView {
  const WidgetView({
    required this.status,
    required this.streak,
    required this.title,
    required this.message,
    required this.week,
  });

  final WidgetStatus status;
  final int streak;
  final String title;
  final String message;

  /// Ultimi 7 giorni, da 6 giorni fa (indice 0) a oggi (indice 6): `true` se
  /// il giorno fa parte della serie che termina in [WidgetStreakData.lastTrainingDay].
  final List<bool> week;

  factory WidgetView.of(WidgetStreakData data, DateTime now) {
    final today = WidgetStreakData.formatDay(now);
    final yesterday = WidgetStreakData.formatDay(DateTime(now.year, now.month, now.day - 1));
    final streak = data.streakAtLastTraining;
    final week = weekOf(data, now);
    if (data.lastTrainingDay == today && streak > 0) {
      return WidgetView(
        status: WidgetStatus.trainedToday,
        streak: streak,
        title: streakTitle(streak),
        message: 'Fatto! Sei inarrestabile ✨',
        week: week,
      );
    }
    if (data.lastTrainingDay == yesterday && streak > 0) {
      return WidgetView(
        status: WidgetStatus.keepStreak,
        streak: streak,
        title: streakTitle(streak),
        message: 'Allenati oggi: salva la serie! 🔥',
        week: week,
      );
    }
    return WidgetView(
      status: WidgetStatus.start,
      streak: 0,
      title: 'Allena l\'orecchio',
      message: 'Pronto ad allenarti? 🎵',
      week: week,
    );
  }

  static String streakTitle(int streak) =>
      streak == 1 ? '1 giorno di fila' : '$streak giorni di fila';

  static List<bool> weekOf(WidgetStreakData data, DateTime now) {
    final last = data.lastTrainingDay;
    final streak = data.streakAtLastTraining;
    if (last == null || streak <= 0) {
      return List.filled(7, false);
    }
    final lastDate = DateTime.parse(last);
    final first = WidgetStreakData.formatDay(
      DateTime(lastDate.year, lastDate.month, lastDate.day - (streak - 1)),
    );
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final day = WidgetStreakData.formatDay(DateTime(now.year, now.month, now.day - i));
          return day.compareTo(first) >= 0 && day.compareTo(last) <= 0;
        }(),
    ];
  }
}
