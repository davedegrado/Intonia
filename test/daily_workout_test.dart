import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/session/range_record.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/profile/application/history_providers.dart';
import 'package:vocal_scale_trainer/features/range/application/range_providers.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/application/tessitura_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/domain/tessitura.dart';
import 'package:vocal_scale_trainer/features/workout/application/workout_controller.dart';
import 'package:vocal_scale_trainer/features/workout/domain/daily_workout.dart';
import 'package:vocal_scale_trainer/services/storage/app_settings_repository.dart';
import 'package:vocal_scale_trainer/services/storage/json_list_repository.dart';
import 'package:vocal_scale_trainer/services/storage/range_history_repository.dart';
import 'package:vocal_scale_trainer/services/storage/session_history_repository.dart';

final _library = const ExerciseLibrary().builtIn;
final _day = DateTime(2026, 10, 19);

SessionRecord _session(String id, int correct, int errors, {int seconds = 60, int daysAgo = 1}) {
  return SessionRecord(
    timestamp: _day.subtract(Duration(days: daysAgo)),
    exerciseId: id,
    exerciseName: id,
    correct: correct,
    errors: errors,
    durationSeconds: seconds,
    perNote: const {},
  );
}

List<String> _ids(DailyWorkout workout) => [for (final step in workout.steps) step.exercise.id];

DailyWorkout _generate({
  int minutes = 10,
  List<SessionRecord> history = const [],
  DateTime? day,
  List<ExerciseDefinition>? library,
  int? low,
  int? high,
}) {
  return const WorkoutGenerator().generate(
    day: day ?? _day,
    minutes: minutes,
    library: library ?? _library,
    history: history,
    comfortLow: low,
    comfortHigh: high,
  );
}

class _MemorySessions extends SessionHistoryRepository {
  _MemorySessions(this.items);
  List<SessionRecord> items;
  @override
  Future<List<SessionRecord>> load() async => items;
  @override
  Future<void> save(List<SessionRecord> records) async => items = records;
}

class _MemoryRanges extends RangeHistoryRepository {
  @override
  Future<List<RangeRecord>> load() async => const [];
  @override
  Future<void> save(List<RangeRecord> records) async {}
}

class _MemoryList<T> extends JsonListRepository<T> {
  _MemoryList()
      : super(
            fileName: 'unused.json',
            fromJson: (_) => throw UnimplementedError(),
            toJson: (_) => {});
  List<T> items = [];
  @override
  Future<List<T>> load() async => items;
  @override
  Future<void> save(List<T> records) async => items = List.of(records);
}

class _Settings extends AppSettingsRepository {
  int? minutes;
  @override
  Future<int?> loadWorkoutMinutes() async => minutes;
  @override
  Future<void> saveWorkoutMinutes(int value) async => minutes = value;
}

void main() {
  group('WorkoutGenerator', () {
    test('is deterministic: same data and day, same workout', () {
      final history = [_session('major', 20, 2), _session('triad_minor', 5, 9)];
      expect(_ids(_generate(history: history)), _ids(_generate(history: List.of(history))));
    });

    test('without data: balanced routine with warm-up, main exercises and review', () {
      final workout = _generate();
      expect(workout.personalized, isFalse);
      expect(workout.steps.first.exercise.id, WorkoutGenerator.warmUpId);
      expect(workout.steps.first.role, WorkoutRole.warmUp);
      expect(workout.steps.last.role, WorkoutRole.review);
      expect(workout.steps.where((s) => s.role == WorkoutRole.main), isNotEmpty);
      expect(workout.steps.any((s) => s.difficult), isFalse);
      final ids = _ids(workout);
      expect(ids.toSet(), hasLength(ids.length), reason: 'nessuna ripetizione');
      // Principiante: niente esercizi avanzati o intermedi.
      for (final step in workout.steps) {
        expect(step.exercise.category, isNot(ExerciseCategory.harmonizations));
        expect(step.exercise.id, isNot(anyOf('triad_augmented', 'blues', 'third_leaps')));
      }
    });

    test('the estimated time follows the chosen duration', () {
      for (final minutes in WorkoutGenerator.durations) {
        final workout = _generate(minutes: minutes);
        expect(workout.estimatedSeconds, lessThanOrEqualTo(minutes * 60 * 1.15),
            reason: '$minutes');
        expect(workout.estimatedSeconds, greaterThanOrEqualTo(minutes * 60 * 0.6),
            reason: '$minutes');
      }
      expect(_generate(minutes: 15).steps.length, greaterThan(_generate(minutes: 5).steps.length));
    });

    test('changes from one day to the next', () {
      final days = {
        for (var i = 0; i < 6; i++) _ids(_generate(day: _day.add(Duration(days: i)))).join(','),
      };
      expect(days.length, greaterThan(1));
    });

    test('brings back the hardest exercises, never only those', () {
      final history = [
        for (var i = 0; i < 3; i++) ...[
          _session('triad_minor', 4, 8, daysAgo: i + 1),
          _session('natural_minor', 6, 9, daysAgo: i + 1),
          _session('major_pentatonic', 5, 7, daysAgo: i + 1),
          _session('major', 30, 1, daysAgo: i + 1),
        ],
      ];
      final workout = _generate(minutes: 15, history: history);
      expect(workout.personalized, isTrue);
      final main = workout.steps.where((s) => s.role == WorkoutRole.main).toList();
      final hard = main.where((s) => s.difficult).toList();
      expect(hard, isNotEmpty);
      expect(hard.first.exercise.id, 'triad_minor', reason: 'la precisione più bassa per prima');
      expect(hard.length, lessThan(main.length), reason: 'non solo esercizi difficili');
      expect(hard.length * 3, lessThanOrEqualTo(main.length + 2));
      // Ripasso: l'esercizio riuscito meglio.
      expect(workout.steps.last.role, WorkoutRole.review);
      expect(workout.steps.last.exercise.id, 'major');
    });

    test('a few attempts are not enough data to call an exercise difficult', () {
      final workout = _generate(history: [_session('triad_minor', 1, 4)]);
      expect(workout.steps.any((s) => s.difficult), isFalse);
      expect(workout.personalized, isFalse);
    });

    test('more sessions unlock harder exercises', () {
      final history = [for (var i = 0; i < 20; i++) _session('major', 16, 0, daysAgo: i + 1)];
      final ids = {
        for (var i = 0; i < 30; i++)
          ..._ids(_generate(minutes: 15, history: history, day: _day.add(Duration(days: i)))),
      };
      expect(ids.intersection({'harmonized_major', 'harmonized_natural_minor'}), isNotEmpty);
      expect(ids, contains(anyOf('blues', 'harmonic_minor', 'triad_augmented')));
    });

    test('custom sequences are never chosen', () {
      const custom = ExerciseDefinition(
        id: 'custom_1',
        name: 'Mia',
        category: ExerciseCategory.custom,
        steps: [0, 2, 4],
        isCustom: true,
        rootMidi: 60,
      );
      final workout = _generate(library: [custom, ..._library], minutes: 15);
      expect(_ids(workout), isNot(contains('custom_1')));
    });

    test('estimates use the median of completed sessions, else the number of notes', () {
      final major = _library.firstWhere((e) => e.id == 'major');
      expect(
          WorkoutGenerator.estimateSeconds(major, const []),
          major.steps.length * WorkoutGenerator.secondsPerNote +
              WorkoutGenerator.secondsPerExercise);
      final history = [
        _session('major', 16, 0, seconds: 50),
        _session('major', 16, 3, seconds: 70),
        _session('major', 16, 0, seconds: 300),
        _session('major', 3, 5, seconds: 900), // interrotta: non conta
      ];
      expect(WorkoutGenerator.estimateSeconds(major, history),
          70 + WorkoutGenerator.secondsPerExercise);
    });

    test('the starting note keeps the exercise inside the comfort zone', () {
      final triad = _library.firstWhere((e) => e.id == 'triad_major'); // 0..7
      expect(WorkoutGenerator.startMidiFor(triad, null, null), isNull);
      final start = WorkoutGenerator.startMidiFor(triad, 55, 67)!;
      expect(start, greaterThanOrEqualTo(55));
      expect(start + 7, lessThanOrEqualTo(67));
      final workout = _generate(low: 55, high: 67);
      for (final step in workout.steps) {
        expect(step.startMidi, isNotNull);
      }
    });

    test('works with an empty library', () {
      expect(_generate(library: const []).steps, isEmpty);
    });
  });

  group('WorkoutRecord', () {
    test('JSON round trip and missing fields', () {
      final record = WorkoutRecord(
        startedAt: DateTime(2026, 10, 19, 8),
        minutes: 10,
        plannedIds: const ['five_note_pattern', 'major'],
        completedIds: const ['five_note_pattern'],
        outcome: WorkoutOutcome.interrupted,
        correct: 12,
        errors: 3,
        durationSeconds: 95,
      );
      final copy = WorkoutRecord.fromJson(record.toJson());
      expect(copy.plannedIds, record.plannedIds);
      expect(copy.completedIds, record.completedIds);
      expect(copy.outcome, WorkoutOutcome.interrupted);
      expect(copy.correct, 12);
      final sparse = WorkoutRecord.fromJson({'startedAt': '2026-10-19T08:00:00.000'});
      expect(sparse.outcome, WorkoutOutcome.interrupted, reason: 'mai completato per errore');
      expect(sparse.minutes, WorkoutGenerator.defaultMinutes);
    });
  });

  group('WorkoutController', () {
    late _MemoryList<WorkoutRecord> store;
    late _Settings settings;
    late _MemorySessions sessions;

    Future<ProviderContainer> create({List<SessionRecord> history = const []}) async {
      store = _MemoryList();
      settings = _Settings();
      sessions = _MemorySessions([...history]);
      final container = ProviderContainer(overrides: [
        workoutRepositoryProvider.overrideWithValue(store),
        appSettingsRepositoryProvider.overrideWithValue(settings),
        sessionHistoryRepositoryProvider.overrideWithValue(sessions),
        rangeHistoryRepositoryProvider.overrideWithValue(_MemoryRanges()),
        tessituraRepositoryProvider.overrideWithValue(_MemoryList<TessituraRecord>()),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 9)),
      ]);
      addTearDown(container.dispose);
      container.listen(workoutControllerProvider, (previous, next) {});
      // Caricamento iniziale (preferenze e proposta).
      for (var i = 0; i < 10 && container.read(workoutControllerProvider).plan == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return container;
    }

    SessionRecord done(String id) => _session(id, 10, 1, daysAgo: 0);

    test('uses the default duration and remembers the chosen one', () async {
      final container = await create();
      final controller = container.read(workoutControllerProvider.notifier);
      expect(container.read(workoutControllerProvider).minutes, WorkoutGenerator.defaultMinutes);
      final steps10 = container.read(workoutControllerProvider).plan!.steps.length;
      await controller.setMinutes(5);
      expect(settings.minutes, 5);
      expect(container.read(workoutControllerProvider).plan!.steps.length, lessThan(steps10));
      await controller.setMinutes(7);
      expect(container.read(workoutControllerProvider).minutes, 5, reason: 'solo 5, 10 o 15');
    });

    test('completing every exercise saves a completed workout', () async {
      final container = await create();
      final controller = container.read(workoutControllerProvider.notifier);
      controller.start();
      var state = container.read(workoutControllerProvider);
      expect(state.status, WorkoutStatus.running);
      expect(state.currentIndex, 0);

      // Una sessione di un altro esercizio non conta.
      controller.recordCompletion(done('blues'));
      expect(container.read(workoutControllerProvider).doneCount, 0);

      for (final step in state.plan!.steps) {
        controller.recordCompletion(done(step.exercise.id));
      }
      await Future<void>.delayed(Duration.zero);
      state = container.read(workoutControllerProvider);
      expect(state.status, WorkoutStatus.finished);
      expect(store.items, hasLength(1));
      final record = store.items.single;
      expect(record.outcome, WorkoutOutcome.completed);
      expect(record.completedIds, record.plannedIds);
      expect(record.correct, 10 * record.plannedIds.length);
      expect(state.today, isNotNull);
      expect(controller.summaryRecord('Allenamento')!.accuracyPercent, 91);
    });

    test('skipping some exercises ends as partial, not completed', () async {
      final container = await create();
      final controller = container.read(workoutControllerProvider.notifier);
      controller.start();
      final steps = container.read(workoutControllerProvider).plan!.steps;
      controller.recordCompletion(done(steps.first.exercise.id));
      for (var i = 1; i < steps.length; i++) {
        await controller.skip();
      }
      await Future<void>.delayed(Duration.zero);
      expect(store.items.single.outcome, WorkoutOutcome.partial);
      expect(store.items.single.completedIds, [steps.first.exercise.id]);
    });

    test('an interrupted workout is saved as interrupted, never completed', () async {
      final container = await create();
      final controller = container.read(workoutControllerProvider.notifier);
      controller.start();
      final first = container.read(workoutControllerProvider).plan!.steps.first;
      controller.recordCompletion(done(first.exercise.id));
      await controller.interrupt();
      final state = container.read(workoutControllerProvider);
      expect(state.status, WorkoutStatus.ready);
      expect(store.items.single.outcome, WorkoutOutcome.interrupted);
      expect(store.items.single.completedIds, [first.exercise.id]);
      expect(state.plan, isNotNull, reason: 'nuova proposta pronta');
      // Dopo l'interruzione le sessioni non avanzano più nulla.
      controller.recordCompletion(done(first.exercise.id));
      expect(store.items, hasLength(1));
    });

    test('the duration cannot change while running and existing history is untouched', () async {
      final old = _session('major', 16, 0, daysAgo: 3);
      final container = await create(history: [old]);
      final controller = container.read(workoutControllerProvider.notifier);
      controller.start();
      await controller.setMinutes(15);
      expect(container.read(workoutControllerProvider).minutes, WorkoutGenerator.defaultMinutes);
      await controller.interrupt();
      expect(sessions.items, [old], reason: 'lo storico delle sessioni non cambia');
    });

    test('previous workouts of today are shown as today status', () async {
      store = _MemoryList();
      final container = ProviderContainer(overrides: [
        workoutRepositoryProvider.overrideWithValue(store
          ..items = [
            WorkoutRecord(
              startedAt: DateTime(2026, 10, 19, 7),
              minutes: 5,
              plannedIds: const ['a', 'b'],
              completedIds: const ['a', 'b'],
              outcome: WorkoutOutcome.completed,
              correct: 1,
              errors: 0,
              durationSeconds: 10,
            ),
          ]),
        appSettingsRepositoryProvider.overrideWithValue(_Settings()),
        sessionHistoryRepositoryProvider.overrideWithValue(_MemorySessions([])),
        rangeHistoryRepositoryProvider.overrideWithValue(_MemoryRanges()),
        tessituraRepositoryProvider.overrideWithValue(_MemoryList<TessituraRecord>()),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 20)),
      ]);
      addTearDown(container.dispose);
      container.listen(workoutControllerProvider, (previous, next) {});
      for (var i = 0; i < 10 && container.read(workoutControllerProvider).today == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(container.read(workoutControllerProvider).today!.outcome, WorkoutOutcome.completed);
    });
  });
}
