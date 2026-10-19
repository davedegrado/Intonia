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
    this.keySemitone,
    this.octave,
    this.direction,
    this.repeatTop,
    this.completed,
    this.longestCorrectRun,
  });

  factory SessionRecord.fromStats({
    required SessionStats stats,
    required String exerciseId,
    required String exerciseName,
    int? keySemitone,
    int? octave,
    String? direction,
    bool? repeatTop,
    bool? completed,
  }) {
    final perNote = <int, List<int>>{};
    // Note corrette consecutive, nell'ordine in cui sono state cantate.
    var run = 0;
    var longestRun = 0;
    for (final attempt in stats.attempts) {
      run = attempt.correct ? run + 1 : 0;
      if (run > longestRun) {
        longestRun = run;
      }
    }
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
      keySemitone: keySemitone,
      octave: octave,
      direction: direction,
      repeatTop: repeatTop,
      completed: completed,
      longestCorrectRun: longestRun,
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
      // Assenti nelle sessioni salvate prima di questa versione.
      keySemitone: json['keySemitone'] as int?,
      octave: json['octave'] as int?,
      direction: json['direction'] as String?,
      repeatTop: json['repeatTop'] as bool?,
      completed: json['completed'] as bool?,
      longestCorrectRun: json['longestCorrectRun'] as int?,
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

  /// Tonalità (semitono della tonica, 0 = DO/C), ottava, modalità
  /// ("forward" / "reverse" / "complete") e ripetizione del vertice usate
  /// nella sessione. Null per le sessioni salvate da versioni precedenti.
  final int? keySemitone;
  final int? octave;
  final String? direction;
  final bool? repeatTop;

  /// True se l'esercizio è stato completato (tutte le note convalidate),
  /// false se interrotto. Null per le sessioni salvate prima di questo dato.
  final bool? completed;

  /// Massimo numero di note corrette di fila nella sessione. Null per le
  /// sessioni salvate prima di questo dato.
  final int? longestCorrectRun;

  int get totalAttempts => correct + errors;

  double get accuracy => totalAttempts == 0 ? 0 : correct / totalAttempts;

  /// Precisione in percentuale intera, come mostrata nel profilo e a fine
  /// esercizio.
  int get accuracyPercent => (accuracy * 100).round();

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
        if (keySemitone != null) 'keySemitone': keySemitone,
        if (octave != null) 'octave': octave,
        if (direction != null) 'direction': direction,
        if (repeatTop != null) 'repeatTop': repeatTop,
        if (completed != null) 'completed': completed,
        if (longestCorrectRun != null) 'longestCorrectRun': longestCorrectRun,
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
