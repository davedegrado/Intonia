import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/session/range_record.dart';

/// Storico dei test di estensione vocale su file JSON.
class RangeHistoryRepository {
  RangeHistoryRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  static const _fileName = 'range_history.json';

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<RangeRecord>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return [
        for (final item in decoded) RangeRecord.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<RangeRecord> records) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode([for (final record in records) record.toJson()]),
        flush: true,
      );
    } catch (_) {
      // Storico non persistito: i dati restano validi in memoria.
    }
  }
}
