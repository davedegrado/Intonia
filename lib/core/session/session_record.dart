import 'session_stats.dart';

/// Riassunto persistito di una sessione di allenamento completata o interrotta.
class SessionRecord {
  const SessionRecord({
    required this.timestamp,
    required this.exerciseId,
    required this.exerciseName,
    required this.correct,
    required this.errors,
    required this.durationSeconds,
    required this.perNote,
    this.minCorrectMidi,
    this.maxCorrectMidi,
  });

  factory SessionRecord.fromStats({
    required SessionStats stats,
    required String exerciseId,
    required String exerciseName,
  }) {
    final perNote = <int, List<int>>{};
    int? minCorrect;
    int? maxCorrect;
    for (final attempt in stats.attempts) {
      final midi = attempt.target.midiNumber;
      final counts = perNote.putIfAbsent(midi, () => [0, 0]);
      if (attempt.correct) {
        counts[0] += 1;
        final sung = attempt.detected.midiNumber;
        minCorrect = minCorrect == null || sung < minCorrect ? sung : minCorrect;
        maxCorrect = maxCorrect == null || sung > maxCorrect ? sung : maxCorrect;
      } else {
        counts[1] += 1;
      }
    }
    return SessionRecord(
      timestamp: stats.startedAt,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      correct: stats.correctNotes,
      errors: stats.errors,
      durationSeconds: stats.elapsed.inSeconds,
      perNote: perNote,
      minCorrectMidi: minCorrect,
      maxCorrectMidi: maxCorrect,
    );
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      correct: json['correct'] as int,
      errors: json['errors'] as int,
      durationSeconds: json['durationSeconds'] as int,
      perNote: {
        for (final entry in (json['perNote'] as Map<String, dynamic>).entries)
          int.parse(entry.key): [
            for (final count in entry.value as List<dynamic>) count as int,
          ],
      },
      minCorrectMidi: json['minCorrectMidi'] as int?,
      maxCorrectMidi: json['maxCorrectMidi'] as int?,
    );
  }

  final DateTime timestamp;
  final String exerciseId;
  final String exerciseName;
  final int correct;
  final int errors;
  final int durationSeconds;

  /// midi della nota target → [corrette, sbagliate].
  final Map<int, List<int>> perNote;

  final int? minCorrectMidi;
  final int? maxCorrectMidi;

  int get totalAttempts => correct + errors;

  double get accuracy => totalAttempts == 0 ? 0 : correct / totalAttempts;

  /// True se la sessione riguarda una sequenza creata dall'utente.
  bool get isCustomExercise => exerciseId.startsWith('custom_');

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'correct': correct,
        'errors': errors,
        'durationSeconds': durationSeconds,
        'perNote': {
          for (final entry in perNote.entries) '${entry.key}': entry.value,
        },
        if (minCorrectMidi != null) 'minCorrectMidi': minCorrectMidi,
        if (maxCorrectMidi != null) 'maxCorrectMidi': maxCorrectMidi,
      };
}

/// Giorni di pratica consecutivi (streak) terminanti oggi o ieri.
int computeStreak(Iterable<DateTime> sessionTimestamps, DateTime now) {
  final days = {
    for (final ts in sessionTimestamps) DateTime(ts.year, ts.month, ts.day),
  };
  if (days.isEmpty) {
    return 0;
  }
  var cursor = DateTime(now.year, now.month, now.day);
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) {
      return 0;
    }
  }
  var streak = 0;
  while (days.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
