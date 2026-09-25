import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_record.dart';
import '../../../services/storage/session_history_repository.dart';

final sessionHistoryRepositoryProvider =
    Provider<SessionHistoryRepository>((ref) => SessionHistoryRepository());

final sessionHistoryProvider =
    AsyncNotifierProvider<SessionHistoryNotifier, List<SessionRecord>>(
  SessionHistoryNotifier.new,
);

class SessionHistoryNotifier extends AsyncNotifier<List<SessionRecord>> {
  @override
  Future<List<SessionRecord>> build() {
    return ref.read(sessionHistoryRepositoryProvider).load();
  }

  Future<void> add(SessionRecord record) async {
    final current = List<SessionRecord>.from(state.value ?? const [])..add(record);
    state = AsyncData(current);
    await ref.read(sessionHistoryRepositoryProvider).save(current);
  }

  /// Rimuove una singola sessione (consentito solo per esercizi custom).
  Future<void> remove(SessionRecord record) async {
    final current = List<SessionRecord>.from(state.value ?? const [])
      ..removeWhere((item) =>
          item.timestamp == record.timestamp && item.exerciseId == record.exerciseId);
    state = AsyncData(current);
    await ref.read(sessionHistoryRepositoryProvider).save(current);
  }
}
