import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/range_record.dart';
import '../../../services/storage/range_history_repository.dart';

final rangeHistoryRepositoryProvider =
    Provider<RangeHistoryRepository>((ref) => RangeHistoryRepository());

final rangeHistoryProvider = AsyncNotifierProvider<RangeHistoryNotifier, List<RangeRecord>>(
  RangeHistoryNotifier.new,
);

class RangeHistoryNotifier extends AsyncNotifier<List<RangeRecord>> {
  @override
  Future<List<RangeRecord>> build() {
    return ref.read(rangeHistoryRepositoryProvider).load();
  }

  Future<void> add(RangeRecord record) async {
    // Attende il caricamento dal disco: aggiungere a uno stato ancora vuoto
    // sovrascriverebbe lo storico salvato con il solo nuovo record.
    final current = List<RangeRecord>.from(await future)..add(record);
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(current);
    await ref.read(rangeHistoryRepositoryProvider).save(current);
  }

  Future<void> remove(RangeRecord record) async {
    final current = List<RangeRecord>.from(state.value ?? const [])
      ..removeWhere((item) => item.timestamp == record.timestamp);
    state = AsyncData(current);
    await ref.read(rangeHistoryRepositoryProvider).save(current);
  }
}
