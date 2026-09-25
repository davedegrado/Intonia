import '../music/note.dart';

class NoteAttempt {
  const NoteAttempt({
    required this.target,
    required this.detected,
    required this.cents,
    required this.correct,
    required this.timestamp,
  });

  final MusicalNote target;
  final MusicalNote detected;
  final double cents;
  final bool correct;
  final DateTime timestamp;
}

class SessionStats {
  const SessionStats({
    required this.startedAt,
    this.endedAt,
    this.attempts = const [],
  });

  factory SessionStats.started() => SessionStats(startedAt: DateTime.now());

  final DateTime startedAt;
  final DateTime? endedAt;
  final List<NoteAttempt> attempts;

  int get totalAttempts => attempts.length;

  int get correctNotes => attempts.where((attempt) => attempt.correct).length;

  int get errors => attempts.where((attempt) => !attempt.correct).length;

  double get accuracy => totalAttempts == 0 ? 0 : correctNotes / totalAttempts;

  Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);

  SessionStats addAttempt(NoteAttempt attempt) {
    return SessionStats(
      startedAt: startedAt,
      endedAt: endedAt,
      attempts: [...attempts, attempt],
    );
  }

  SessionStats finish() {
    return SessionStats(
      startedAt: startedAt,
      endedAt: DateTime.now(),
      attempts: attempts,
    );
  }
}
