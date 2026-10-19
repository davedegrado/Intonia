import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_record.dart';
import '../../../services/storage/json_list_repository.dart';
import '../../access/application/access_providers.dart';
import '../../library/application/exercise_providers.dart';
import '../../profile/application/history_providers.dart';
import '../../tessitura/application/tessitura_providers.dart';
import '../../workout/application/workout_controller.dart';
import '../domain/achievements.dart';

/// Badge sbloccato, salvato in locale: resta sbloccato anche se la
/// cronologia da cui è stato ricavato cambia (es. sessioni oltre le 500
/// conservate).
class UnlockRecord {
  const UnlockRecord({required this.id, required this.unlockedAt});

  static UnlockRecord? fromJson(Map<String, dynamic> json) {
    final id = AchievementId.values.asNameMap()[json['id']];
    final at = DateTime.tryParse(json['unlockedAt'] as String? ?? '');
    return id == null || at == null ? null : UnlockRecord(id: id, unlockedAt: at);
  }

  final AchievementId id;
  final DateTime unlockedAt;

  Map<String, dynamic> toJson() => {'id': id.name, 'unlockedAt': unlockedAt.toIso8601String()};
}

final achievementsRepositoryProvider = Provider<JsonListRepository<UnlockRecord?>>(
  (ref) => JsonListRepository(
    fileName: 'achievements.json',
    // Id sconosciuti (versioni future) o record danneggiati vengono ignorati.
    fromJson: UnlockRecord.fromJson,
    toJson: (record) => record!.toJson(),
  ),
);

/// Badge sbloccati (id → data di sblocco).
final unlockedAchievementsProvider =
    AsyncNotifierProvider<UnlockedAchievementsNotifier, Map<AchievementId, DateTime>>(
  UnlockedAchievementsNotifier.new,
);

class UnlockedAchievementsNotifier extends AsyncNotifier<Map<AchievementId, DateTime>> {
  /// Le registrazioni sono in fila: due aggiornamenti ravvicinati non
  /// salvano (né annunciano) lo stesso badge due volte.
  Future<void> _queue = Future.value();

  @override
  Future<Map<AchievementId, DateTime>> build() async {
    final records = await ref.read(achievementsRepositoryProvider).load();
    return {
      for (final record in records.whereType<UnlockRecord>()) record.id: record.unlockedAt,
    };
  }

  /// Registra i traguardi raggiunti non ancora salvati; ritorna quelli nuovi.
  Future<List<AchievementId>> record(Map<AchievementId, DateTime> reached) {
    final result = Completer<List<AchievementId>>();
    _queue = _queue.then((_) async {
      final current = Map.of(await future);
      final added = [
        for (final entry in reached.entries)
          if (!current.containsKey(entry.key)) entry.key,
      ];
      if (added.isEmpty || !ref.mounted) {
        result.complete(const []);
        return;
      }
      for (final id in added) {
        current[id] = reached[id]!;
      }
      state = AsyncData(current);
      await ref.read(achievementsRepositoryProvider).save([
        for (final entry in current.entries) UnlockRecord(id: entry.key, unlockedAt: entry.value),
      ]);
      result.complete(added);
    }).catchError((Object _) {
      if (!result.isCompleted) {
        result.complete(const []);
      }
    });
    return result.future;
  }
}

/// Obiettivi, missioni e serie calcolati dalla cronologia attuale.
class AchievementsView {
  const AchievementsView({
    required this.progress,
    required this.unlocked,
    required this.daily,
    required this.weekly,
    required this.currentStreak,
    required this.bestStreak,
  });

  final Map<AchievementId, AchievementProgress> progress;

  /// Badge sbloccati con la data: salvati più quelli appena raggiunti.
  final Map<AchievementId, DateTime> unlocked;
  final List<MissionProgress> daily;
  final List<MissionProgress> weekly;
  final int currentStreak;
  final int bestStreak;

  bool isUnlocked(AchievementId id) => unlocked.containsKey(id);
}

/// Vista calcolata; null finché le cronologie non sono caricate.
final achievementsProvider = Provider<AchievementsView?>((ref) {
  final sessions = ref.watch(sessionHistoryProvider).value;
  final workouts = ref.watch(workoutHistoryProvider).value;
  final tessitura = ref.watch(tessituraHistoryProvider).value;
  final stored = ref.watch(unlockedAchievementsProvider).value;
  if (sessions == null || workouts == null || tessitura == null || stored == null) {
    return null;
  }
  final library = [
    ...ref.watch(exerciseLibraryProvider).builtIn,
    ...?ref.watch(customExercisesProvider).value,
  ];
  final now = ref.read(clockProvider)();
  final facts = ActivityFacts.from(
    sessions: sessions,
    workouts: workouts,
    tessitura: tessitura,
    library: library,
  );
  final progress = const AchievementEngine().evaluate(facts, now);
  final (best, _) = bestStreak(facts.activityTimes, 1);
  return AchievementsView(
    progress: progress,
    unlocked: {
      for (final entry in progress.entries)
        if (entry.value.reachedAt != null) entry.key: entry.value.reachedAt!,
      ...stored,
    },
    daily: const MissionPlanner().daily(facts, now),
    weekly: const MissionPlanner().weekly(facts, now),
    currentStreak: computeStreak(facts.activityTimes, now),
    bestStreak: best,
  );
});

/// Avvio dell'app: solo i badge raggiunti da qui in poi vengono annunciati
/// (quelli ricavati dalla cronologia precedente si sbloccano in silenzio).
final appStartedAtProvider = Provider<DateTime>((ref) => ref.read(clockProvider)());

/// Badge da annunciare, in ordine.
final achievementToastsProvider = NotifierProvider<AchievementToastsNotifier, List<AchievementId>>(
  AchievementToastsNotifier.new,
);

class AchievementToastsNotifier extends Notifier<List<AchievementId>> {
  @override
  List<AchievementId> build() => const [];

  void push(Iterable<AchievementId> ids) => state = [...state, ...ids];

  void pop() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }
}

/// Salva i nuovi traguardi e accoda gli annunci. Da tenere attivo
/// (osservato dall'app).
final achievementSyncProvider = Provider<void>((ref) {
  final startedAt = ref.read(appStartedAtProvider);
  ref.listen<AchievementsView?>(achievementsProvider, (previous, next) {
    if (next == null) {
      return;
    }
    final reached = {
      for (final entry in next.progress.entries)
        if (entry.value.reachedAt != null) entry.key: entry.value.reachedAt!,
    };
    unawaited(ref.read(unlockedAchievementsProvider.notifier).record(reached).then((added) {
      final fresh = [
        for (final id in added)
          if (!reached[id]!.isBefore(startedAt.subtract(const Duration(minutes: 1)))) id,
      ];
      if (fresh.isNotEmpty && ref.mounted) {
        ref.read(achievementToastsProvider.notifier).push(fresh);
      }
    }));
  }, fireImmediately: true);
});
