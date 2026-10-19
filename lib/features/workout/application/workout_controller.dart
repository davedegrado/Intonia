import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/range_record.dart';
import '../../../core/session/session_record.dart';
import '../../../services/storage/json_list_repository.dart';
import '../../access/application/access_providers.dart';
import '../../library/application/exercise_providers.dart';
import '../../profile/application/history_providers.dart';
import '../../range/application/range_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../tessitura/application/tessitura_providers.dart';
import '../../tessitura/domain/tessitura.dart';
import '../domain/daily_workout.dart';

final workoutRepositoryProvider = Provider<JsonListRepository<WorkoutRecord>>(
  (ref) => JsonListRepository(
    fileName: 'daily_workout_history.json',
    fromJson: WorkoutRecord.fromJson,
    toJson: (record) => record.toJson(),
    maxItems: 200,
  ),
);

/// Allenamenti del giorno salvati, dal più vecchio al più recente.
final workoutHistoryProvider = AsyncNotifierProvider<WorkoutHistoryNotifier, List<WorkoutRecord>>(
  WorkoutHistoryNotifier.new,
);

class WorkoutHistoryNotifier extends AsyncNotifier<List<WorkoutRecord>> {
  @override
  Future<List<WorkoutRecord>> build() => ref.read(workoutRepositoryProvider).load();

  Future<void> add(WorkoutRecord record) async {
    // Attende il caricamento: aggiungere a uno stato vuoto sovrascriverebbe lo storico.
    final current = [...await future, record];
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(current);
    await ref.read(workoutRepositoryProvider).save(current);
  }
}

enum WorkoutStatus { ready, running, finished }

enum WorkoutStepStatus { pending, current, completed, skipped }

class WorkoutState {
  const WorkoutState({
    required this.minutes,
    required this.plan,
    required this.status,
    this.statuses = const [],
    this.results = const {},
    this.startedAt,
    this.lastRecord,
    this.today,
  });

  /// Durata scelta (predefinita: [WorkoutGenerator.defaultMinutes]).
  final int minutes;

  /// Allenamento proposto (null durante il caricamento iniziale).
  final DailyWorkout? plan;
  final WorkoutStatus status;
  final List<WorkoutStepStatus> statuses;

  /// Sessioni completate, per indice dell'esercizio.
  final Map<int, SessionRecord> results;
  final DateTime? startedAt;

  /// Allenamento appena chiuso (riepilogo).
  final WorkoutRecord? lastRecord;

  /// Ultimo allenamento salvato oggi, per lo stato nella Home.
  final WorkoutRecord? today;

  int get currentIndex => statuses.indexOf(WorkoutStepStatus.current);

  WorkoutStep? get currentStep {
    final index = currentIndex;
    return index < 0 ? null : plan?.steps[index];
  }

  int get completedCount => statuses.where((s) => s == WorkoutStepStatus.completed).length;
  int get doneCount => statuses
      .where((s) => s != WorkoutStepStatus.pending && s != WorkoutStepStatus.current)
      .length;
  int get total => plan?.steps.length ?? 0;
  double get progress => total == 0 ? 0 : doneCount / total;

  WorkoutState copyWith({
    int? minutes,
    DailyWorkout? plan,
    WorkoutStatus? status,
    List<WorkoutStepStatus>? statuses,
    Map<int, SessionRecord>? results,
    DateTime? startedAt,
    WorkoutRecord? lastRecord,
    WorkoutRecord? today,
  }) {
    return WorkoutState(
      minutes: minutes ?? this.minutes,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      statuses: statuses ?? this.statuses,
      results: results ?? this.results,
      startedAt: startedAt ?? this.startedAt,
      lastRecord: lastRecord ?? this.lastRecord,
      today: today ?? this.today,
    );
  }
}

final workoutControllerProvider = NotifierProvider<WorkoutController, WorkoutState>(
  WorkoutController.new,
);

/// Allenamento del giorno: proposta, avanzamento esercizio per esercizio e
/// storico. Gli esercizi si svolgono nel trainer esistente (stesse cariche,
/// stesso salvataggio delle sessioni); qui si tiene solo il filo.
class WorkoutController extends Notifier<WorkoutState> {
  DateTime get _now => ref.read(clockProvider)();

  @override
  WorkoutState build() {
    unawaited(_load());
    return const WorkoutState(
      minutes: WorkoutGenerator.defaultMinutes,
      plan: null,
      status: WorkoutStatus.ready,
    );
  }

  Future<void> _load() async {
    // Proposta subito con la durata predefinita; poi preferenza e stato di oggi.
    final savedFuture = ref.read(appSettingsRepositoryProvider).loadWorkoutMinutes();
    final historyFuture = ref.read(workoutHistoryProvider.future);
    // Dopo build: lo stato iniziale deve esistere prima di leggerlo.
    await Future<void>.microtask(() {});
    await refresh();
    if (!ref.mounted) {
      return;
    }
    final saved = await savedFuture.catchError((Object _) => null);
    final history = await historyFuture;
    if (!ref.mounted) {
      return;
    }
    final now = _now;
    final today = history.where((record) => record.isOn(now)).lastOrNull;
    final minutes = WorkoutGenerator.durations.contains(saved) ? saved! : state.minutes;
    state = WorkoutState(
      minutes: minutes,
      plan: state.plan,
      status: state.status,
      statuses: state.statuses,
      results: state.results,
      startedAt: state.startedAt,
      lastRecord: state.lastRecord,
      today: today,
    );
    await refresh();
  }

  /// Rigenera la proposta con i dati attuali (non durante un allenamento).
  Future<void> refresh() async {
    if (state.status == WorkoutStatus.running) {
      return;
    }
    final plan = await _generate(state.minutes);
    if (!ref.mounted || state.status == WorkoutStatus.running) {
      return;
    }
    state = state.copyWith(plan: plan);
  }

  Future<DailyWorkout> _generate(int minutes) async {
    // Tutte le letture prima delle attese: il provider può essere eliminato
    // nel frattempo.
    final sessionsFuture = ref.read(sessionHistoryProvider.future);
    final tessituraFuture = ref.read(tessituraHistoryProvider.future);
    final rangesFuture = ref.read(rangeHistoryProvider.future);
    final library = ref.read(exerciseLibraryProvider).builtIn;
    final now = _now;
    final (low, high) = comfortZone(await tessituraFuture, await rangesFuture);
    return const WorkoutGenerator().generate(
      day: now,
      minutes: minutes,
      library: library,
      history: await sessionsFuture,
      comfortLow: low,
      comfortHigh: high,
    );
  }

  /// Zona in cui far cadere gli esercizi: tessitura se nota, altrimenti
  /// l'estensione senza le 3 note estreme per lato; nessuna senza dati.
  static (int?, int?) comfortZone(List<TessituraRecord> tessitura, List<RangeRecord> ranges) {
    final withZone = tessitura.where((record) => record.hasZone).lastOrNull;
    if (withZone != null) {
      return (withZone.comfortLow, withZone.comfortHigh);
    }
    final range = ranges.lastOrNull;
    if (range != null && range.spanSemitones >= 12) {
      return (range.minMidi + 3, range.maxMidi - 3);
    }
    return (null, null);
  }

  /// Durata scelta: ricorda la preferenza e rigenera la proposta.
  Future<void> setMinutes(int minutes) async {
    if (state.status == WorkoutStatus.running || !WorkoutGenerator.durations.contains(minutes)) {
      return;
    }
    state = state.copyWith(minutes: minutes);
    unawaited(ref.read(appSettingsRepositoryProvider).saveWorkoutMinutes(minutes));
    await refresh();
  }

  void start() {
    final plan = state.plan;
    if (plan == null || plan.steps.isEmpty || state.status == WorkoutStatus.running) {
      return;
    }
    state = WorkoutState(
      minutes: state.minutes,
      plan: plan,
      status: WorkoutStatus.running,
      statuses: [
        for (var i = 0; i < plan.steps.length; i++)
          i == 0 ? WorkoutStepStatus.current : WorkoutStepStatus.pending,
      ],
      results: const {},
      startedAt: _now,
      today: state.today,
    );
  }

  /// Sessione completata nel trainer: vale per l'esercizio corrente se è lo
  /// stesso (una sessione di un altro esercizio non conta).
  void recordCompletion(SessionRecord record) {
    final index = state.currentIndex;
    if (state.status != WorkoutStatus.running ||
        index < 0 ||
        state.plan!.steps[index].exercise.id != record.exerciseId) {
      return;
    }
    _advance(index, WorkoutStepStatus.completed, record);
  }

  /// Salta l'esercizio corrente (non conta come completato).
  Future<void> skip() async {
    final index = state.currentIndex;
    if (state.status == WorkoutStatus.running && index >= 0) {
      _advance(index, WorkoutStepStatus.skipped, null);
    }
  }

  void _advance(int index, WorkoutStepStatus status, SessionRecord? record) {
    final statuses = List.of(state.statuses)..[index] = status;
    final next = statuses.indexOf(WorkoutStepStatus.pending);
    if (next >= 0) {
      statuses[next] = WorkoutStepStatus.current;
    }
    state = state.copyWith(
      statuses: statuses,
      results: record == null ? null : {...state.results, index: record},
    );
    if (next < 0) {
      unawaited(_close(
        statuses.every((s) => s == WorkoutStepStatus.completed)
            ? WorkoutOutcome.completed
            : WorkoutOutcome.partial,
      ));
    }
  }

  /// Interrompe l'allenamento: salvato come interrotto, mai come completato.
  Future<void> interrupt() async {
    if (state.status != WorkoutStatus.running) {
      return;
    }
    await _close(WorkoutOutcome.interrupted);
  }

  Future<void> _close(WorkoutOutcome outcome) async {
    final plan = state.plan!;
    final results = state.results;
    final record = WorkoutRecord(
      startedAt: state.startedAt ?? _now,
      minutes: plan.minutes,
      plannedIds: [for (final step in plan.steps) step.exercise.id],
      completedIds: [
        for (var i = 0; i < plan.steps.length; i++)
          if (state.statuses[i] == WorkoutStepStatus.completed) plan.steps[i].exercise.id,
      ],
      outcome: outcome,
      correct: results.values.fold(0, (sum, r) => sum + r.correct),
      errors: results.values.fold(0, (sum, r) => sum + r.errors),
      durationSeconds: results.values.fold(0, (sum, r) => sum + r.durationSeconds),
    );
    state = state.copyWith(
      status: outcome == WorkoutOutcome.interrupted ? WorkoutStatus.ready : WorkoutStatus.finished,
      lastRecord: record,
      today: record,
    );
    await ref.read(workoutHistoryProvider.notifier).add(record);
    if (!ref.mounted) {
      return;
    }
    if (outcome == WorkoutOutcome.interrupted) {
      state = state.copyWith(statuses: const [], results: const {});
      await refresh();
    }
  }

  /// Chiude il riepilogo e torna alla proposta.
  Future<void> dismissSummary() async {
    if (state.status != WorkoutStatus.finished) {
      return;
    }
    state = state.copyWith(status: WorkoutStatus.ready, statuses: const [], results: const {});
    await refresh();
  }

  /// Riepilogo come una sessione unica, per la schermata di fine esercizio
  /// già esistente (precisione, note corrette, errori, durata).
  SessionRecord? summaryRecord(String title) {
    final record = state.lastRecord;
    if (record == null) {
      return null;
    }
    return SessionRecord(
      timestamp: record.startedAt,
      exerciseId: 'daily_workout',
      exerciseName: title,
      correct: record.correct,
      errors: record.errors,
      durationSeconds: record.durationSeconds,
      perNote: const {},
    );
  }
}
