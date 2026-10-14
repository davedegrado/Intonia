import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/access/domain/charge_ledger.dart';

/// Persistenza delle cariche Free su file JSON (come le altre preferenze):
/// offline, nessun backend.
class ChargesRepository {
  ChargesRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  static const _fileName = 'charges.json';

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  /// Stato salvato; prima installazione (nessun file) = cariche piene.
  Future<ChargeLedger> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return ChargeLedger.full;
      }
      return ChargeLedger.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return ChargeLedger.full;
    }
  }

  Future<void> save(ChargeLedger ledger) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(ledger.toJson()), flush: true);
    } catch (_) {
      // Non persistito: resta valido in memoria per la sessione corrente.
    }
  }
}
