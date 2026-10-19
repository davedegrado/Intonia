import 'dart:math' as math;

import '../../../core/music/exercise.dart';
import '../../../core/session/session_record.dart';
import '../../tessitura/domain/tessitura.dart';
import '../../workout/domain/daily_workout.dart';

/// Categorie degli obiettivi permanenti.
enum AchievementCategory { consistency, training, accuracy, exploration }

/// Obiettivi permanenti. L'ordine è quello mostrato.
enum AchievementId {
  firstExercise(AchievementCategory.consistency, 1),
  days3(AchievementCategory.consistency, 3),
  days7(AchievementCategory.consistency, 7),
  streak7(AchievementCategory.consistency, 7),
  streak30(AchievementCategory.consistency, 30),
  exercises5(AchievementCategory.training, 5),
  exercises25(AchievementCategory.training, 25),
  firstWorkout(AchievementCategory.training, 1),
  workouts5(AchievementCategory.training, 5),
  workouts10(AchievementCategory.training, 10),
  perfectExercise(AchievementCategory.accuracy, 1),
  accurate5(AchievementCategory.accuracy, 5),
  noteRun10(AchievementCategory.accuracy, 10),
  categories3(AchievementCategory.exploration, 3),
  firstTessitura(AchievementCategory.exploration, 1),
  secondTessitura(AchievementCategory.exploration, 2);

  const AchievementId(this.category, this.target);

  final AchievementCategory category;

  /// Valore da raggiungere (esercizi, giorni, note…).
  final int target;
}

/// Un esercizio completato, con i dati attendibili usati dagli obiettivi.
class CompletedExercise {
  const CompletedExercise({
    required this.timestamp,
    required this.exerciseId,
    required this.category,
    required this.accuracyPercent,
    required this.reliableAccuracy,
    required this.longestCorrectRun,
  });

  final DateTime timestamp;
  final String exerciseId;
  final ExerciseCategory? category;
  final int accuracyPercent;

  /// Precisione calcolata su abbastanza note da essere significativa.
  final bool reliableAccuracy;

  /// Note corrette di fila; null se il dato non era registrato.
  final int? longestCorrectRun;
}

/// Fatti ricavati dagli storici esistenti (sessioni, allenamenti del giorno,
/// test di tessitura): l'unica fonte di obiettivi e missioni. Calcolare dai
/// dati salvati rende il conteggio idempotente: riaprire schermate, eventi
/// ripetuti o riavvii non contano nulla due volte.
class ActivityFacts {
  const ActivityFacts({
    required this.activityTimes,
    required this.completedExercises,
    required this.completedWorkouts,
    required this.tessituraTests,
  });

  /// Note minime perché la precisione di un esercizio sia attendibile.
  static const minReliableAttempts = 5;

  factory ActivityFacts.from({
    required List<SessionRecord> sessions,
    required List<WorkoutRecord> workouts,
    required List<TessituraRecord> tessitura,
    required List<ExerciseDefinition> library,
  }) {
    final byId = {for (final exercise in library) exercise.id: exercise};
    final completed = <CompletedExercise>[];
    // Una sessione salvata due volte (stessa ora, stesso esercizio) conta una volta.
    final seen = <(DateTime, String)>{};
    for (final record in sessions) {
      if (!seen.add((record.timestamp, record.exerciseId))) {
        continue;
      }
      final exercise = byId[record.exerciseId];
      if (!isCompleted(record, exercise)) {
        continue;
      }
      completed.add(CompletedExercise(
        timestamp: record.timestamp,
        exerciseId: record.exerciseId,
        category: exercise?.category ?? (record.isCustomExercise ? ExerciseCategory.custom : null),
        accuracyPercent: record.accuracyPercent,
        reliableAccuracy: record.totalAttempts >= minReliableAttempts,
        longestCorrectRun: record.longestCorrectRun,
      ));
    }
    completed.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ActivityFacts(
      // Come la serie del profilo: una sessione con almeno una nota cantata.
      activityTimes: [
        for (final record in sessions)
          if (record.totalAttempts > 0) record.timestamp,
      ]..sort(),
      completedExercises: completed,
      completedWorkouts: {
        for (final workout in workouts)
          if (workout.outcome == WorkoutOutcome.completed) workout.startedAt,
      }.toList()
        ..sort(),
      tessituraTests: {for (final record in tessitura) record.timestamp}.toList()..sort(),
    );
  }

  /// Esercizio completato secondo il trainer. Per le sessioni salvate prima
  /// del dato "completed": completato solo se è un esercizio della libreria
  /// e le note corrette coprono tutta la sequenza (le personalizzate non si
  /// possono ricostruire con certezza e non contano).
  static bool isCompleted(SessionRecord record, ExerciseDefinition? exercise) {
    final completed = record.completed;
    if (completed != null) {
      return completed;
    }
    if (exercise == null || exercise.isCustom) {
      return false;
    }
    final direction =
        PlaybackDirection.values.asNameMap()[record.direction] ?? exercise.defaultDirection;
    final notes = exercise.stepsFor(direction, repeatTop: record.repeatTop ?? false).length;
    return record.correct >= notes;
  }

  /// Sessioni con attività (per serie e giorni di allenamento).
  final List<DateTime> activityTimes;
  final List<CompletedExercise> completedExercises;

  /// Inizio degli allenamenti del giorno completati (mai quelli interrotti).
  final List<DateTime> completedWorkouts;
  final List<DateTime> tessituraTests;
}

/// Giorno di calendario locale.
DateTime localDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Lunedì della settimana (locale) di [time].
DateTime weekStart(DateTime time) {
  final day = localDay(time);
  return DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
}

/// Serie più lunga di sempre (stessa regola di [computeStreak], usata per
/// la serie attuale) e l'attività che l'ha portata a [target] giorni (null
/// se mai raggiunta).
(int, DateTime?) bestStreak(List<DateTime> activity, int target) {
  final firstOfDay = <DateTime, DateTime>{};
  for (final time in activity) {
    final day = localDay(time);
    final known = firstOfDay[day];
    if (known == null || time.isBefore(known)) {
      firstOfDay[day] = time;
    }
  }
  final days = firstOfDay.keys.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? reached;
  for (var i = 0; i < days.length; i++) {
    final previous = i == 0 ? null : days[i - 1];
    final consecutive =
        previous != null && DateTime(previous.year, previous.month, previous.day + 1) == days[i];
    run = consecutive ? run + 1 : 1;
    best = math.max(best, run);
    if (run == target && reached == null) {
      reached = firstOfDay[days[i]];
    }
  }
  return (best, reached);
}

/// Avanzamento di un obiettivo.
class AchievementProgress {
  const AchievementProgress({required this.id, required this.value, this.reachedAt});

  final AchievementId id;

  /// Valore attuale (limitato al traguardo).
  final int value;

  /// Quando i dati hanno raggiunto il traguardo; null se non ancora.
  final DateTime? reachedAt;

  int get target => id.target;
  bool get reached => reachedAt != null;
  double get fraction => (value / target).clamp(0.0, 1.0);
}

/// Calcola tutti gli obiettivi dai fatti.
class AchievementEngine {
  const AchievementEngine();

  Map<AchievementId, AchievementProgress> evaluate(ActivityFacts facts, DateTime now) {
    final exercises = facts.completedExercises;

    /// L'n-esimo elemento (da 1) di una lista ordinata, se esiste.
    DateTime? nth(List<DateTime> times, int n) => times.length >= n ? times[n - 1] : null;

    AchievementProgress count(AchievementId id, List<DateTime> times) => AchievementProgress(
          id: id,
          value: math.min(times.length, id.target),
          reachedAt: nth(times, id.target),
        );

    final completedTimes = [for (final e in exercises) e.timestamp];
    final perfect = [
      for (final e in exercises)
        if (e.reliableAccuracy && e.accuracyPercent == 100) e.timestamp,
    ];
    final accurate = [
      for (final e in exercises)
        if (e.reliableAccuracy && e.accuracyPercent >= 90) e.timestamp,
    ];

    // Giorni distinti con almeno un esercizio completato.
    final firstPerDay = <DateTime, DateTime>{};
    for (final time in completedTimes) {
      firstPerDay.putIfAbsent(localDay(time), () => time);
    }
    final dayTimes = firstPerDay.values.toList()..sort();

    // Categorie distinte (nell'ordine in cui sono state completate).
    final categoryTimes = <ExerciseCategory, DateTime>{};
    for (final e in exercises) {
      final category = e.category;
      if (category != null) {
        categoryTimes.putIfAbsent(category, () => e.timestamp);
      }
    }
    final categoryList = categoryTimes.values.toList()..sort();

    // Note corrette di fila: solo dove il dato è stato registrato.
    var longestRun = 0;
    DateTime? runReached;
    for (final e in exercises) {
      final run = e.longestCorrectRun ?? 0;
      longestRun = math.max(longestRun, run);
      if (run >= AchievementId.noteRun10.target && runReached == null) {
        runReached = e.timestamp;
      }
    }

    // Secondo test di tessitura in un giorno diverso dal primo.
    final tests = facts.tessituraTests;
    DateTime? secondTest;
    if (tests.isNotEmpty) {
      final firstDay = localDay(tests.first);
      secondTest = tests.where((time) => localDay(time) != firstDay).firstOrNull;
    }

    AchievementProgress streak(AchievementId id) {
      final (best, reached) = bestStreak(facts.activityTimes, id.target);
      return AchievementProgress(id: id, value: math.min(best, id.target), reachedAt: reached);
    }

    return {
      for (final progress in [
        count(AchievementId.firstExercise, completedTimes),
        count(AchievementId.days3, dayTimes),
        count(AchievementId.days7, dayTimes),
        streak(AchievementId.streak7),
        streak(AchievementId.streak30),
        count(AchievementId.exercises5, completedTimes),
        count(AchievementId.exercises25, completedTimes),
        count(AchievementId.firstWorkout, facts.completedWorkouts),
        count(AchievementId.workouts5, facts.completedWorkouts),
        count(AchievementId.workouts10, facts.completedWorkouts),
        count(AchievementId.perfectExercise, perfect),
        count(AchievementId.accurate5, accurate),
        AchievementProgress(
          id: AchievementId.noteRun10,
          value: math.min(longestRun, AchievementId.noteRun10.target),
          reachedAt: runReached,
        ),
        count(AchievementId.categories3, categoryList),
        count(AchievementId.firstTessitura, tests),
        AchievementProgress(
          id: AchievementId.secondTessitura,
          value: secondTest != null ? 2 : math.min(tests.length, 1),
          reachedAt: secondTest,
        ),
      ])
        progress.id: progress,
    };
  }
}

/// Missioni temporanee.
enum MissionKind {
  dailyExercises2(MissionPeriod.day, 2),
  dailyExercises3(MissionPeriod.day, 3),
  dailyWorkout(MissionPeriod.day, 1),
  dailyAccuracy90(MissionPeriod.day, 1),
  weeklyCategories2(MissionPeriod.week, 2),
  weeklyDays3(MissionPeriod.week, 3),
  weeklyWorkouts2(MissionPeriod.week, 2);

  const MissionKind(this.period, this.target);

  final MissionPeriod period;
  final int target;
}

enum MissionPeriod { day, week }

class MissionProgress {
  const MissionProgress({
    required this.kind,
    required this.value,
    required this.start,
    required this.end,
  });

  final MissionKind kind;
  final int value;

  /// Periodo della missione nel calendario locale: [start, end).
  final DateTime start;
  final DateTime end;

  int get target => kind.target;
  bool get done => value >= target;
  double get fraction => (value / target).clamp(0.0, 1.0);
}

/// Missioni del giorno e della settimana: sempre le stesse per lo stesso
/// periodo (scelta dalla data, non casuale), con l'avanzamento calcolato
/// dalle attività dentro il periodo.
class MissionPlanner {
  const MissionPlanner();

  /// Coppie di missioni giornaliere a rotazione (mai due quasi uguali).
  static const dailySets = [
    [MissionKind.dailyExercises2, MissionKind.dailyWorkout],
    [MissionKind.dailyAccuracy90, MissionKind.dailyExercises2],
    [MissionKind.dailyWorkout, MissionKind.dailyAccuracy90],
    [MissionKind.dailyExercises3, MissionKind.dailyWorkout],
  ];

  static const weeklySets = [
    [MissionKind.weeklyCategories2, MissionKind.weeklyDays3],
    [MissionKind.weeklyWorkouts2, MissionKind.weeklyCategories2],
    [MissionKind.weeklyDays3, MissionKind.weeklyWorkouts2],
  ];

  /// Indice del giorno di calendario (indipendente dall'ora e dall'ora legale).
  static int dayIndex(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays;

  List<MissionProgress> daily(ActivityFacts facts, DateTime now) {
    final start = localDay(now);
    final end = DateTime(start.year, start.month, start.day + 1);
    final kinds = dailySets[dayIndex(start) % dailySets.length];
    return [for (final kind in kinds) _progress(kind, facts, start, end)];
  }

  List<MissionProgress> weekly(ActivityFacts facts, DateTime now) {
    final start = weekStart(now);
    final end = DateTime(start.year, start.month, start.day + 7);
    final kinds = weeklySets[(dayIndex(start) ~/ 7) % weeklySets.length];
    return [for (final kind in kinds) _progress(kind, facts, start, end)];
  }

  MissionProgress _progress(MissionKind kind, ActivityFacts facts, DateTime start, DateTime end) {
    bool inside(DateTime time) {
      final local = time.toLocal();
      return !local.isBefore(start) && local.isBefore(end);
    }

    final exercises = facts.completedExercises.where((e) => inside(e.timestamp)).toList();
    final value = switch (kind) {
      MissionKind.dailyExercises2 || MissionKind.dailyExercises3 => exercises.length,
      MissionKind.dailyWorkout ||
      MissionKind.weeklyWorkouts2 =>
        facts.completedWorkouts.where(inside).length,
      MissionKind.dailyAccuracy90 =>
        exercises.where((e) => e.reliableAccuracy && e.accuracyPercent >= 90).length,
      MissionKind.weeklyCategories2 =>
        exercises.map((e) => e.category).whereType<ExerciseCategory>().toSet().length,
      MissionKind.weeklyDays3 => exercises.map((e) => localDay(e.timestamp)).toSet().length,
    };
    return MissionProgress(
      kind: kind,
      value: math.min(value, kind.target),
      start: start,
      end: end,
    );
  }
}
