import 'dart:math' as math;

import '../../../core/music/exercise.dart';
import '../../../core/session/session_record.dart';

/// Ruolo di un esercizio nell'allenamento.
enum WorkoutRole { warmUp, main, review }

/// Un esercizio dell'allenamento del giorno.
class WorkoutStep {
  const WorkoutStep({
    required this.exercise,
    required this.role,
    required this.estimatedSeconds,
    this.difficult = false,
    this.startMidi,
  });

  final ExerciseDefinition exercise;
  final WorkoutRole role;

  /// Durata stimata (indicativa): dallo storico dell'utente o dal numero di note.
  final int estimatedSeconds;

  /// Scelto perché nelle sessioni precedenti è risultato difficile.
  final bool difficult;

  /// Prima nota consigliata, per stare nella zona comoda (null = tonalità e
  /// ottava già impostate nel trainer).
  final int? startMidi;
}

/// Allenamento del giorno: riscaldamento, esercizi principali, ripasso.
class DailyWorkout {
  const DailyWorkout({
    required this.day,
    required this.minutes,
    required this.steps,
    required this.personalized,
  });

  final DateTime day;

  /// Durata scelta (5, 10 o 15 minuti).
  final int minutes;
  final List<WorkoutStep> steps;

  /// True se la scelta usa i risultati delle sessioni precedenti.
  final bool personalized;

  int get estimatedSeconds => steps.fold(0, (sum, step) => sum + step.estimatedSeconds);

  /// Minuti stimati, arrotondati (almeno 1).
  int get estimatedMinutes => math.max(1, (estimatedSeconds / 60).round());
}

/// Precisione aggregata di un esercizio nello storico.
class ExercisePerformance {
  const ExercisePerformance({required this.correct, required this.errors, required this.sessions});

  final int correct;
  final int errors;
  final int sessions;

  int get attempts => correct + errors;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// Genera l'allenamento del giorno in modo deterministico: stessi dati e
/// stesso giorno danno sempre lo stesso allenamento. Nessun servizio remoto.
///
/// Regole (spiegabili e verificabili):
/// - riscaldamento: il pattern a 5 note (categoria "Pattern", descritta
///   nell'app come sequenze di riscaldamento);
/// - livello dal numero di sessioni: gli esercizi più impegnativi entrano
///   dopo 5 sessioni (triadi aumentate/diminuite, minori armonica e melodica,
///   blues, salti di terza) e 15 (armonizzazioni);
/// - esercizi principali a rotazione giornaliera fra le categorie, con al
///   massimo un terzo di esercizi "difficili" (precisione sotto il 75% su
///   almeno 8 note in 2 sessioni) messi per primi;
/// - ripasso finale: un esercizio riuscito bene di recente, altrimenti una
///   triade semplice; mai un esercizio già presente;
/// - le sequenze personalizzate non entrano (note e tonalità fisse).
class WorkoutGenerator {
  const WorkoutGenerator();

  static const durations = [5, 10, 15];
  static const defaultMinutes = 10;

  static const warmUpId = 'five_note_pattern';
  static const _reviewFallbackIds = ['triad_major', 'triad_minor', 'major'];

  /// Sessioni oltre cui entrano gli esercizi intermedi e avanzati.
  static const intermediateSessions = 5;
  static const advancedSessions = 15;

  static const _intermediateIds = {
    'triad_augmented',
    'triad_diminished',
    'harmonic_minor',
    'melodic_minor',
    'blues',
    'third_leaps',
  };

  /// Soglie per considerare difficile un esercizio.
  static const difficultAccuracy = 0.75;
  static const minAttemptsForData = 8;
  static const minSessionsForData = 2;

  /// Tempo per nota (nota guida, ascolto e convalida) e per esercizio
  /// (avvio e schermata di fine) quando lo storico non basta.
  static const secondsPerNote = 4;
  static const secondsPerExercise = 25;

  /// Ordine di rotazione delle categorie degli esercizi principali.
  static const _rotation = [
    ExerciseCategory.triads,
    ExerciseCategory.scales,
    ExerciseCategory.arpeggios,
    ExerciseCategory.pentatonics,
    ExerciseCategory.patterns,
    ExerciseCategory.harmonizations,
  ];

  DailyWorkout generate({
    required DateTime day,
    required int minutes,
    required List<ExerciseDefinition> library,
    required List<SessionRecord> history,
    int? comfortLow,
    int? comfortHigh,
  }) {
    final date = DateTime(day.year, day.month, day.day);
    final dayIndex = date.difference(DateTime(2024)).inDays;
    final target = minutes * 60;
    final level = history.length;
    final available = [
      for (final exercise in library)
        if (!exercise.isCustom && _suitable(exercise, level)) exercise,
    ];
    final performance = performanceByExercise(history);
    final difficult = [
      for (final exercise in available)
        if (_isDifficult(performance[exercise.id])) exercise,
    ]..sort((a, b) {
        final byAccuracy = performance[a.id]!.accuracy.compareTo(performance[b.id]!.accuracy);
        return byAccuracy != 0 ? byAccuracy : a.id.compareTo(b.id);
      });

    WorkoutStep step(ExerciseDefinition exercise, WorkoutRole role, {bool hard = false}) {
      return WorkoutStep(
        exercise: exercise,
        role: role,
        estimatedSeconds: estimateSeconds(exercise, history),
        difficult: hard,
        startMidi: startMidiFor(exercise, comfortLow, comfortHigh),
      );
    }

    final used = <String>{};
    final steps = <WorkoutStep>[];
    final warmUp = available.where((exercise) => exercise.id == warmUpId).firstOrNull;
    if (warmUp != null) {
      steps.add(step(warmUp, WorkoutRole.warmUp));
      used.add(warmUp.id);
    }

    final review = _review(available, performance, used, dayIndex);
    final reviewSeconds = review == null ? 0 : estimateSeconds(review, history);
    final mainBudget = target - steps.fold(0, (sum, s) => sum + s.estimatedSeconds) - reviewSeconds;

    // Candidati principali: la rotazione del giorno con un esercizio
    // difficile ogni tre posizioni (seconda, quinta, ...): i difficili sono
    // al massimo un terzo e mai tutto l'allenamento.
    final rotation = _rotationFor(available, dayIndex, exclude: {
      ...used,
      if (review != null) review.id,
    });
    final hard = [
      for (final exercise in difficult)
        if (!used.contains(exercise.id) && exercise.id != review?.id) exercise,
    ];
    final hardIds = {for (final exercise in hard) exercise.id};
    final candidates = <ExerciseDefinition>[];
    var r = 0;
    var h = 0;
    while (r < rotation.length || h < hard.length) {
      final wantsHard = candidates.length % 3 == 1;
      if ((wantsHard && h < hard.length) || r >= rotation.length) {
        candidates.add(hard[h++]);
      } else {
        candidates.add(rotation[r++]);
      }
    }

    final main = <WorkoutStep>[];
    var mainSeconds = 0;
    for (final exercise in candidates) {
      if (used.contains(exercise.id)) {
        continue;
      }
      final seconds = estimateSeconds(exercise, history);
      // Almeno un esercizio principale; poi solo se resta tempo (10% di margine).
      if (main.isNotEmpty && mainSeconds + seconds > mainBudget * 1.1) {
        break;
      }
      main.add(step(exercise, WorkoutRole.main, hard: hardIds.contains(exercise.id)));
      used.add(exercise.id);
      mainSeconds += seconds;
      if (mainSeconds >= mainBudget) {
        break;
      }
    }
    steps.addAll(main);
    if (review != null &&
        steps.fold(0, (sum, s) => sum + s.estimatedSeconds) + reviewSeconds <= target * 1.15) {
      steps.add(step(review, WorkoutRole.review));
    }

    return DailyWorkout(
      day: date,
      minutes: minutes,
      steps: steps,
      personalized: performance.values.any(_hasData),
    );
  }

  /// Esercizi adatti al livello (numero di sessioni fatte).
  static bool _suitable(ExerciseDefinition exercise, int sessions) {
    if (exercise.category == ExerciseCategory.harmonizations) {
      return sessions >= advancedSessions;
    }
    if (_intermediateIds.contains(exercise.id)) {
      return sessions >= intermediateSessions;
    }
    return true;
  }

  static bool _hasData(ExercisePerformance performance) =>
      performance.attempts >= minAttemptsForData && performance.sessions >= minSessionsForData;

  static bool _isDifficult(ExercisePerformance? performance) =>
      performance != null && _hasData(performance) && performance.accuracy < difficultAccuracy;

  /// Precisione per esercizio sulle ultime 60 sessioni.
  static Map<String, ExercisePerformance> performanceByExercise(List<SessionRecord> history) {
    final recent = history.length > 60 ? history.sublist(history.length - 60) : history;
    final totals = <String, (int, int, int)>{};
    for (final record in recent) {
      final (correct, errors, sessions) = totals[record.exerciseId] ?? (0, 0, 0);
      totals[record.exerciseId] = (correct + record.correct, errors + record.errors, sessions + 1);
    }
    return {
      for (final entry in totals.entries)
        entry.key: ExercisePerformance(
          correct: entry.value.$1,
          errors: entry.value.$2,
          sessions: entry.value.$3,
        ),
    };
  }

  /// Ripasso: l'esercizio riuscito meglio (almeno 85%) fra quelli con dati,
  /// altrimenti una triade o la scala maggiore (a rotazione).
  ExerciseDefinition? _review(
    List<ExerciseDefinition> available,
    Map<String, ExercisePerformance> performance,
    Set<String> used,
    int dayIndex,
  ) {
    final good = [
      for (final exercise in available)
        if (!used.contains(exercise.id) &&
            performance[exercise.id] != null &&
            _hasData(performance[exercise.id]!) &&
            performance[exercise.id]!.accuracy >= 0.85)
          exercise,
    ]..sort((a, b) {
        final byAccuracy = performance[b.id]!.accuracy.compareTo(performance[a.id]!.accuracy);
        return byAccuracy != 0 ? byAccuracy : a.id.compareTo(b.id);
      });
    if (good.isNotEmpty) {
      return good[dayIndex % math.min(3, good.length)];
    }
    final fallback = [
      for (final id in _reviewFallbackIds)
        ...available.where((exercise) => exercise.id == id && !used.contains(id)),
    ];
    return fallback.isEmpty ? null : fallback[dayIndex % fallback.length];
  }

  /// Esercizi principali nell'ordine del giorno: una categoria alla volta,
  /// partendo da una categoria e da un esercizio che cambiano ogni giorno.
  static List<ExerciseDefinition> _rotationFor(
    List<ExerciseDefinition> available,
    int dayIndex, {
    required Set<String> exclude,
  }) {
    final byCategory = <ExerciseCategory, List<ExerciseDefinition>>{
      for (final category in _rotation)
        category: [
          for (final exercise in available)
            if (exercise.category == category && !exclude.contains(exercise.id)) exercise,
        ],
    }..removeWhere((category, exercises) => exercises.isEmpty);
    final categories = [
      for (final category in _rotation)
        if (byCategory.containsKey(category)) category,
    ];
    if (categories.isEmpty) {
      return const [];
    }
    final ordered = <ExerciseDefinition>[];
    final rounds = byCategory.values.map((list) => list.length).reduce(math.max);
    for (var round = 0; round < rounds; round++) {
      for (var i = 0; i < categories.length; i++) {
        final category = categories[(dayIndex + i) % categories.length];
        final list = byCategory[category]!;
        if (round < list.length) {
          ordered.add(list[(dayIndex ~/ categories.length + round) % list.length]);
        }
      }
    }
    return ordered;
  }

  /// Durata stimata: mediana delle sessioni completate dell'esercizio (con
  /// avvio e schermata finale), altrimenti in base al numero di note.
  static int estimateSeconds(ExerciseDefinition exercise, List<SessionRecord> history) {
    final notes = exercise.steps.length;
    final completed = [
      for (final record in history)
        if (record.exerciseId == exercise.id &&
            record.correct >= notes &&
            record.durationSeconds > 0)
          record.durationSeconds,
    ]..sort();
    final seconds = completed.length >= 2
        ? completed[completed.length ~/ 2] + secondsPerExercise
        : notes * secondsPerNote + secondsPerExercise;
    return seconds.clamp(40, 300);
  }

  /// Prima nota perché l'esercizio stia nella zona comoda (o vi sia
  /// centrato se è più ampio). Null senza zona nota.
  static int? startMidiFor(ExerciseDefinition exercise, int? low, int? high) {
    if (low == null || high == null || high < low) {
      return null;
    }
    final steps = exercise.steps;
    final lowest = steps.reduce(math.min);
    final span = steps.reduce(math.max) - lowest;
    // Spazio libero ai lati (negativo se l'esercizio è più ampio della zona).
    final free = (high - low) - span;
    final first = low + free ~/ 2 - lowest;
    // Ottave disponibili nel trainer: 2–6.
    return first.clamp(36, 95);
  }
}

/// Esito di un allenamento del giorno.
enum WorkoutOutcome {
  /// Tutti gli esercizi completati.
  completed,

  /// Arrivato in fondo saltando qualche esercizio.
  partial,

  /// Interrotto prima della fine: non vale come completato.
  interrupted,
}

/// Allenamento del giorno salvato nello storico.
class WorkoutRecord {
  const WorkoutRecord({
    required this.startedAt,
    required this.minutes,
    required this.plannedIds,
    required this.completedIds,
    required this.outcome,
    required this.correct,
    required this.errors,
    required this.durationSeconds,
  });

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutRecord(
      startedAt: DateTime.parse(json['startedAt'] as String),
      minutes: json['minutes'] as int? ?? WorkoutGenerator.defaultMinutes,
      plannedIds: [for (final id in json['plannedIds'] as List<dynamic>? ?? const []) id as String],
      completedIds: [
        for (final id in json['completedIds'] as List<dynamic>? ?? const []) id as String,
      ],
      outcome: WorkoutOutcome.values.asNameMap()[json['outcome']] ?? WorkoutOutcome.interrupted,
      correct: json['correct'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }

  final DateTime startedAt;
  final int minutes;
  final List<String> plannedIds;

  /// Esercizi effettivamente completati (in ordine).
  final List<String> completedIds;
  final WorkoutOutcome outcome;

  /// Totali delle sessioni completate nell'allenamento.
  final int correct;
  final int errors;
  final int durationSeconds;

  bool isOn(DateTime day) =>
      startedAt.year == day.year && startedAt.month == day.month && startedAt.day == day.day;

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'minutes': minutes,
        'plannedIds': plannedIds,
        'completedIds': completedIds,
        'outcome': outcome.name,
        'correct': correct,
        'errors': errors,
        'durationSeconds': durationSeconds,
      };
}
