import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/core/session/session_stats.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/achievements/application/achievements_providers.dart';
import 'package:vocal_scale_trainer/features/achievements/domain/achievements.dart';
import 'package:vocal_scale_trainer/features/library/application/exercise_providers.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/application/tessitura_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/domain/tessitura.dart';
import 'package:vocal_scale_trainer/features/workout/application/workout_controller.dart';
import 'package:vocal_scale_trainer/features/workout/domain/daily_workout.dart';
import 'package:vocal_scale_trainer/services/storage/custom_exercise_repository.dart';
import 'package:vocal_scale_trainer/services/storage/json_list_repository.dart';
import 'package:vocal_scale_trainer/services/storage/session_history_repository.dart';

final _library = const ExerciseLibrary().builtIn;

/// Sessione completata (o interrotta) di un esercizio della libreria.
SessionRecord _session(
  DateTime when, {
  String id = 'triad_major',
  int correct = 5,
  int errors = 0,
  bool? completed = true,
  int? run,
}) {
  return SessionRecord(
    timestamp: when,
    exerciseId: id,
    exerciseName: id,
    correct: correct,
    errors: errors,
    durationSeconds: 30,
    perNote: const {},
    completed: completed,
    longestCorrectRun: run,
  );
}

WorkoutRecord _workout(DateTime when, WorkoutOutcome outcome) => WorkoutRecord(
      startedAt: when,
      minutes: 10,
      plannedIds: const ['a'],
      completedIds: outcome == WorkoutOutcome.completed ? const ['a'] : const [],
      outcome: outcome,
      correct: 5,
      errors: 0,
      durationSeconds: 60,
    );

TessituraRecord _tessitura(DateTime when) => TessituraRecord(
      timestamp: when,
      comfortLow: 55,
      comfortHigh: 62,
      rangeLow: null,
      rangeHigh: null,
      toVerify: const [],
      reliability: TessituraReliability.medium,
      provisional: false,
      trials: 6,
    );

ActivityFacts _facts({
  List<SessionRecord> sessions = const [],
  List<WorkoutRecord> workouts = const [],
  List<TessituraRecord> tessitura = const [],
}) =>
    ActivityFacts.from(
      sessions: sessions,
      workouts: workouts,
      tessitura: tessitura,
      library: _library,
    );

Map<AchievementId, AchievementProgress> _evaluate(ActivityFacts facts) =>
    const AchievementEngine().evaluate(facts, DateTime(2026, 10, 20, 12));

class _MemoryList<T> extends JsonListRepository<T> {
  _MemoryList([List<T>? items])
      : items = items ?? [],
        super(
            fileName: 'unused.json',
            fromJson: (_) => throw UnimplementedError(),
            toJson: (_) => {});
  List<T> items;
  int saves = 0;
  @override
  Future<List<T>> load() async => List.of(items);
  @override
  Future<void> save(List<T> records) async {
    saves++;
    items = List.of(records);
  }
}

class _MemorySessions extends SessionHistoryRepository {
  _MemorySessions(this.items);
  List<SessionRecord> items;
  @override
  Future<List<SessionRecord>> load() async => items;
  @override
  Future<void> save(List<SessionRecord> records) async => items = records;
}

class _NoCustom extends CustomExerciseRepository {
  @override
  Future<List<ExerciseDefinition>> load() async => const [];
  @override
  Future<void> save(List<ExerciseDefinition> exercises) async {}
}

void main() {
  group('completed exercises', () {
    test('only sessions recorded as completed count; interrupted ones do not', () {
      final facts = _facts(sessions: [
        _session(DateTime(2026, 10, 1, 9)),
        _session(DateTime(2026, 10, 1, 10), completed: false, correct: 3),
      ]);
      expect(facts.completedExercises, hasLength(1));
      expect(facts.activityTimes, hasLength(2), reason: 'per la serie conta anche la pratica');
    });

    test('old sessions without the flag: completed only when certain', () {
      final triad = _library.firstWhere((e) => e.id == 'triad_major'); // 5 note in Completo
      expect(ActivityFacts.isCompleted(_session(DateTime(2026), completed: null), triad), isTrue);
      expect(
          ActivityFacts.isCompleted(_session(DateTime(2026), completed: null, correct: 4), triad),
          isFalse);
      // Salvata in Ascendente: 3 note bastano.
      final forward = SessionRecord(
        timestamp: DateTime(2026),
        exerciseId: 'triad_major',
        exerciseName: 'x',
        correct: 3,
        errors: 1,
        durationSeconds: 10,
        perNote: const {},
        direction: 'forward',
      );
      expect(ActivityFacts.isCompleted(forward, triad), isTrue);
      // Personalizzate o sconosciute: non ricostruibili, non contano.
      expect(
          ActivityFacts.isCompleted(
              _session(DateTime(2026), id: 'custom_1', completed: null, correct: 99), null),
          isFalse);
    });

    test('a session saved twice counts once', () {
      final when = DateTime(2026, 10, 1, 9);
      final facts = _facts(sessions: [_session(when), _session(when)]);
      expect(facts.completedExercises, hasLength(1));
      expect(_evaluate(facts)[AchievementId.firstExercise]!.reached, isTrue);
    });
  });

  group('permanent goals', () {
    test('first exercise and counts unlock on the record that reaches them', () {
      final sessions = [for (var i = 0; i < 6; i++) _session(DateTime(2026, 10, 1, 9 + i))];
      final progress = _evaluate(_facts(sessions: sessions));
      expect(progress[AchievementId.firstExercise]!.reachedAt, DateTime(2026, 10, 1, 9));
      expect(progress[AchievementId.exercises5]!.reachedAt, DateTime(2026, 10, 1, 13));
      expect(progress[AchievementId.exercises25]!.value, 6);
      expect(progress[AchievementId.exercises25]!.reached, isFalse);
      expect(progress[AchievementId.exercises25]!.fraction, closeTo(6 / 25, 1e-9));
    });

    test('distinct days, not sessions; local day boundaries respected', () {
      final progress = _evaluate(_facts(sessions: [
        _session(DateTime(2026, 10, 1, 23, 59)),
        _session(DateTime(2026, 10, 2, 0, 1)),
        _session(DateTime(2026, 10, 2, 18)),
      ]));
      expect(progress[AchievementId.days3]!.value, 2);
      final more = _evaluate(_facts(sessions: [
        _session(DateTime(2026, 10, 1, 9)),
        _session(DateTime(2026, 10, 5, 9)),
        _session(DateTime(2026, 10, 9, 9)),
      ]));
      expect(more[AchievementId.days3]!.reachedAt, DateTime(2026, 10, 9, 9));
    });

    test('streaks need consecutive days; a gap restarts the count', () {
      final days = [
        for (var d = 1; d <= 6; d++) DateTime(2026, 10, d, 20),
        for (var d = 8; d <= 14; d++) DateTime(2026, 10, d, 20),
      ];
      final progress = _evaluate(_facts(sessions: [for (final d in days) _session(d)]));
      expect(progress[AchievementId.streak7]!.reachedAt, DateTime(2026, 10, 14, 20));
      expect(progress[AchievementId.streak30]!.value, 7);
      final (best, _) = bestStreak(days, 1);
      expect(best, 7);
    });

    test('streak across a month and a year end', () {
      final days = [for (var d = 0; d < 7; d++) DateTime(2026, 12, 28 + d, 9)];
      final (best, reached) = bestStreak(days, 7);
      expect(best, 7);
      expect(reached, DateTime(2027, 1, 3, 9));
    });

    test('accuracy goals use reliable results only', () {
      final progress = _evaluate(_facts(sessions: [
        // 100% su 3 note: troppo poche per contare.
        _session(DateTime(2026, 10, 1, 9), correct: 3),
        _session(DateTime(2026, 10, 1, 10), correct: 9, errors: 1), // 90%
        _session(DateTime(2026, 10, 1, 11), correct: 8),
        _session(DateTime(2026, 10, 1, 12), correct: 8, errors: 2, completed: false),
      ]));
      expect(progress[AchievementId.perfectExercise]!.reachedAt, DateTime(2026, 10, 1, 11));
      expect(progress[AchievementId.accurate5]!.value, 2);
    });

    test('notes in a row only where the data exists', () {
      final none = _evaluate(_facts(sessions: [_session(DateTime(2026, 10, 1), correct: 20)]));
      expect(none[AchievementId.noteRun10]!.value, 0);
      expect(none[AchievementId.noteRun10]!.reached, isFalse);
      final some = _evaluate(_facts(sessions: [
        _session(DateTime(2026, 10, 1), correct: 20, run: 7),
        _session(DateTime(2026, 10, 2), correct: 20, run: 12),
      ]));
      expect(some[AchievementId.noteRun10]!.reachedAt, DateTime(2026, 10, 2));
    });

    test('distinct categories, custom sequences included', () {
      final progress = _evaluate(_facts(sessions: [
        _session(DateTime(2026, 10, 1, 9), id: 'triad_major'),
        _session(DateTime(2026, 10, 1, 10), id: 'triad_minor'),
        _session(DateTime(2026, 10, 1, 11), id: 'major', correct: 16),
        _session(DateTime(2026, 10, 1, 12), id: 'custom_1'),
      ]));
      expect(progress[AchievementId.categories3]!.reachedAt, DateTime(2026, 10, 1, 12));
    });

    test('interrupted or partial workouts never count', () {
      final progress = _evaluate(_facts(workouts: [
        _workout(DateTime(2026, 10, 1), WorkoutOutcome.interrupted),
        _workout(DateTime(2026, 10, 2), WorkoutOutcome.partial),
        _workout(DateTime(2026, 10, 3), WorkoutOutcome.completed),
      ]));
      expect(progress[AchievementId.firstWorkout]!.reachedAt, DateTime(2026, 10, 3));
      expect(progress[AchievementId.workouts5]!.value, 1);
    });

    test('the second comfort zone test must be on another day', () {
      final sameDay = _evaluate(_facts(tessitura: [
        _tessitura(DateTime(2026, 10, 1, 9)),
        _tessitura(DateTime(2026, 10, 1, 18)),
      ]));
      expect(sameDay[AchievementId.firstTessitura]!.reached, isTrue);
      expect(sameDay[AchievementId.secondTessitura]!.reached, isFalse);
      expect(sameDay[AchievementId.secondTessitura]!.value, 1);
      final later = _evaluate(_facts(tessitura: [
        _tessitura(DateTime(2026, 10, 1, 9)),
        _tessitura(DateTime(2026, 10, 1, 18)),
        _tessitura(DateTime(2026, 10, 4, 9)),
      ]));
      expect(later[AchievementId.secondTessitura]!.reachedAt, DateTime(2026, 10, 4, 9));
    });

    test('empty history: nothing unlocked, nothing invented', () {
      final progress = _evaluate(_facts());
      expect(progress.values.where((p) => p.reached), isEmpty);
      expect(progress, hasLength(AchievementId.values.length));
    });
  });

  group('missions', () {
    const planner = MissionPlanner();

    test('same missions all day long, other missions the next day', () {
      final facts = _facts();
      final morning = planner.daily(facts, DateTime(2026, 10, 20, 7));
      final evening = planner.daily(facts, DateTime(2026, 10, 20, 23, 59));
      expect(morning.map((m) => m.kind), evening.map((m) => m.kind));
      final kinds = {
        for (var d = 0; d < 8; d++)
          planner.daily(facts, DateTime(2026, 10, 20 + d)).map((m) => m.kind).join(),
      };
      expect(kinds.length, greaterThan(1));
    });

    test('never two near-identical daily missions together', () {
      for (final set in MissionPlanner.dailySets) {
        expect(set.toSet(), hasLength(2));
        expect(
            set.contains(MissionKind.dailyExercises2) && set.contains(MissionKind.dailyExercises3),
            isFalse);
      }
    });

    test('daily progress counts only today and resets at midnight', () {
      final facts = _facts(sessions: [
        _session(DateTime(2026, 10, 20, 9)),
        _session(DateTime(2026, 10, 20, 10)),
        _session(DateTime(2026, 10, 19, 22)),
      ]);
      // Il 20/10 propone "2 esercizi" (insieme 0 della rotazione).
      final today = planner.daily(facts, DateTime(2026, 10, 20, 12));
      final exercises = today.where((m) => m.kind == MissionKind.dailyExercises2).firstOrNull ??
          planner
              .daily(facts, DateTime(2026, 10, 20, 12))
              .firstWhere((m) => m.kind.period == MissionPeriod.day);
      expect(exercises.start, DateTime(2026, 10, 20));
      expect(exercises.end, DateTime(2026, 10, 21));
      final tomorrow = planner.daily(facts, DateTime(2026, 10, 21, 8));
      expect(tomorrow.every((m) => m.value == 0), isTrue, reason: 'nuovo giorno, si riparte');
      // Gli obiettivi permanenti non cambiano.
      expect(_evaluate(facts)[AchievementId.firstExercise]!.reached, isTrue);
    });

    test('weekly missions run Monday to Sunday', () {
      final facts = _facts(sessions: [
        _session(DateTime(2026, 10, 19, 9)), // lunedì
        _session(DateTime(2026, 10, 21, 9), id: 'major', correct: 16), // mercoledì
        _session(DateTime(2026, 10, 18, 9), id: 'blues', correct: 13), // domenica prima
      ]);
      final week = planner.weekly(facts, DateTime(2026, 10, 25, 22)); // domenica
      expect(week.first.start, DateTime(2026, 10, 19));
      expect(week.first.end, DateTime(2026, 10, 26));
      for (final mission in week) {
        final expected = switch (mission.kind) {
          MissionKind.weeklyCategories2 => 2,
          MissionKind.weeklyDays3 => 2,
          _ => 0,
        };
        expect(mission.value, expected, reason: mission.kind.name);
      }
      final next = planner.weekly(facts, DateTime(2026, 10, 26, 0, 1));
      expect(next.every((m) => m.value == 0), isTrue);
    });

    test('the daily workout mission ignores interrupted workouts', () {
      final facts = _facts(workouts: [
        _workout(DateTime(2026, 10, 20, 8), WorkoutOutcome.interrupted),
      ]);
      // Un giorno con la missione dell'allenamento.
      final day = [
        for (var d = 0; d < 4; d++) DateTime(2026, 10, 20 + d, 12),
      ].firstWhere((d) => planner.daily(facts, d).any((m) => m.kind == MissionKind.dailyWorkout));
      final mission =
          planner.daily(facts, day).firstWhere((m) => m.kind == MissionKind.dailyWorkout);
      expect(mission.value, 0);
      expect(mission.done, isFalse);
    });
  });

  group('SessionRecord data', () {
    test('records the longest run of correct notes and keeps old JSON readable', () {
      const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
      NoteAttempt attempt(bool correct) => NoteAttempt(
            target: c4,
            detected: c4,
            cents: 0,
            correct: correct,
            timestamp: DateTime(2026),
          );
      final stats = SessionStats(
        startedAt: DateTime(2026),
        attempts: [
          attempt(true),
          attempt(true),
          attempt(false),
          attempt(true),
          attempt(true),
          attempt(true)
        ],
      );
      final record = SessionRecord.fromStats(
        stats: stats,
        exerciseId: 'major',
        exerciseName: 'Scala maggiore',
        completed: true,
      );
      expect(record.longestCorrectRun, 3);
      final copy = SessionRecord.fromJson(record.toJson());
      expect(copy.completed, isTrue);
      expect(copy.longestCorrectRun, 3);

      final legacy = SessionRecord.fromJson({
        'timestamp': '2026-10-01T10:00:00.000',
        'exerciseId': 'major',
        'exerciseName': 'Scala maggiore',
        'correct': 16,
        'errors': 0,
        'durationSeconds': 60,
        'perNote': <String, dynamic>{},
      });
      expect(legacy.completed, isNull);
      expect(legacy.longestCorrectRun, isNull);
      expect(legacy.toJson().containsKey('completed'), isFalse);
    });
  });

  group('providers', () {
    late _MemorySessions sessions;
    late _MemoryList<UnlockRecord?> store;
    late _MemoryList<WorkoutRecord> workouts;
    late DateTime now;

    ProviderContainer create() {
      final container = ProviderContainer(overrides: [
        sessionHistoryRepositoryProvider.overrideWithValue(sessions),
        workoutRepositoryProvider.overrideWithValue(workouts),
        tessituraRepositoryProvider.overrideWithValue(_MemoryList<TessituraRecord>()),
        achievementsRepositoryProvider.overrideWithValue(store),
        customExerciseRepositoryProvider.overrideWithValue(_NoCustom()),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(container.dispose);
      container.listen(achievementSyncProvider, (previous, next) {});
      return container;
    }

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setUp(() {
      now = DateTime(2026, 10, 20, 12);
      sessions = _MemorySessions([]);
      store = _MemoryList<UnlockRecord?>();
      workouts = _MemoryList<WorkoutRecord>();
    });

    test('history from before the app starts unlocks silently and is saved', () async {
      sessions.items = [_session(DateTime(2026, 10, 19, 9))];
      final container = create();
      await settle();
      expect(store.items.whereType<UnlockRecord>().map((r) => r.id),
          contains(AchievementId.firstExercise));
      expect(container.read(achievementToastsProvider), isEmpty);
    });

    test('a new completed exercise unlocks once and is announced once', () async {
      final container = create();
      await settle();
      expect(container.read(achievementsProvider)!.unlocked, isEmpty);

      now = DateTime(2026, 10, 20, 12, 5);
      final record = _session(DateTime(2026, 10, 20, 12, 4));
      await container.read(sessionHistoryProvider.notifier).add(record);
      await settle();
      // 5 note su 5: anche "Perfetto!".
      const both = [AchievementId.firstExercise, AchievementId.perfectExercise];
      expect(container.read(achievementToastsProvider), both);
      expect(container.read(achievementsProvider)!.isUnlocked(AchievementId.firstExercise), isTrue);

      // Ricalcoli, eventi ripetuti e la stessa sessione salvata due volte: nulla di nuovo.
      container.invalidate(achievementsProvider);
      await container.read(sessionHistoryProvider.notifier).add(record);
      await settle();
      expect(container.read(achievementToastsProvider), both);
      expect(store.items.whereType<UnlockRecord>(), hasLength(2));
    });

    test('an interrupted exercise unlocks nothing', () async {
      final container = create();
      await settle();
      await container
          .read(sessionHistoryProvider.notifier)
          .add(_session(DateTime(2026, 10, 20, 12, 1), completed: false, correct: 2));
      await settle();
      expect(container.read(achievementsProvider)!.unlocked, isEmpty);
      expect(container.read(achievementToastsProvider), isEmpty);
    });

    test('unlocked badges survive a restart, even if the history no longer shows them', () async {
      sessions.items = [_session(DateTime(2026, 10, 19, 9))];
      final first = create();
      await settle();
      final date = first.read(achievementsProvider)!.unlocked[AchievementId.firstExercise];
      expect(date, DateTime(2026, 10, 19, 9));

      // Riavvio senza più quella sessione (es. storico oltre le 500 sessioni).
      sessions.items = [];
      final second = create();
      await settle();
      final view = second.read(achievementsProvider)!;
      expect(view.unlocked[AchievementId.firstExercise], date);
      expect(second.read(achievementToastsProvider), isEmpty, reason: 'già annunciato');
    });

    test('concurrent registrations save each badge once', () async {
      final container = create();
      await settle();
      final notifier = container.read(unlockedAchievementsProvider.notifier);
      final reached = {AchievementId.firstExercise: DateTime(2026, 10, 20)};
      final results = await Future.wait([notifier.record(reached), notifier.record(reached)]);
      expect(results.expand((ids) => ids), [AchievementId.firstExercise]);
      expect(store.items.whereType<UnlockRecord>(), hasLength(1));
    });

    test('a damaged or unknown stored badge is ignored', () async {
      expect(UnlockRecord.fromJson({'id': 'future_badge', 'unlockedAt': '2026-10-01T00:00:00'}),
          isNull);
      expect(UnlockRecord.fromJson({'id': 'days3'}), isNull);
      store.items = [
        null,
        UnlockRecord(id: AchievementId.days3, unlockedAt: DateTime(2026, 10, 1))
      ];
      final container = create();
      await settle();
      expect(container.read(achievementsProvider)!.unlocked.keys, [AchievementId.days3]);
    });

    test('a completed daily workout counts, an interrupted one does not', () async {
      final container = create();
      await settle();
      final history = container.read(workoutHistoryProvider.notifier);
      await history.add(_workout(DateTime(2026, 10, 20, 12, 1), WorkoutOutcome.interrupted));
      await settle();
      expect(container.read(achievementsProvider)!.isUnlocked(AchievementId.firstWorkout), isFalse);
      await history.add(_workout(DateTime(2026, 10, 20, 12, 2), WorkoutOutcome.completed));
      await settle();
      expect(container.read(achievementsProvider)!.isUnlocked(AchievementId.firstWorkout), isTrue);
      expect(container.read(achievementToastsProvider), contains(AchievementId.firstWorkout));
    });
  });
}
