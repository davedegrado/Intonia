import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/storage/json_list_repository.dart';
import '../domain/tessitura.dart';

final tessituraRepositoryProvider = Provider<JsonListRepository<TessituraRecord>>(
  (ref) => JsonListRepository(
    fileName: 'tessitura_history.json',
    fromJson: TessituraRecord.fromJson,
    toJson: (record) => record.toJson(),
    maxItems: 100,
  ),
);

/// Test di tessitura salvati, dal più vecchio al più recente.
final tessituraHistoryProvider =
    AsyncNotifierProvider<TessituraHistoryNotifier, List<TessituraRecord>>(
  TessituraHistoryNotifier.new,
);

class TessituraHistoryNotifier extends AsyncNotifier<List<TessituraRecord>> {
  @override
  Future<List<TessituraRecord>> build() => ref.read(tessituraRepositoryProvider).load();

  Future<void> add(TessituraRecord record) async {
    // Attende il caricamento: aggiungere a uno stato vuoto sovrascriverebbe lo storico.
    final current = List<TessituraRecord>.from(await future)..add(record);
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(current);
    await ref.read(tessituraRepositoryProvider).save(current);
  }

  Future<void> remove(TessituraRecord record) async {
    final current = List<TessituraRecord>.from(await future)
      ..removeWhere((item) => item.timestamp == record.timestamp);
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(current);
    await ref.read(tessituraRepositoryProvider).save(current);
  }
}
