import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/session/session_record.dart';

/// Storico delle sessioni di allenamento su file JSON (ultime 500).
class SessionHistoryRepository {
  SessionHistoryRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  static const _fileName = 'session_history.json';
  static const _maxRecords = 500;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<SessionRecord>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return [
        for (final item in decoded) SessionRecord.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<SessionRecord> records) async {
    try {
      final trimmed = records.length > _maxRecords
          ? records.sublist(records.length - _maxRecords)
          : records;
      final file = await _file();
      await file.writeAsString(
        jsonEncode([for (final record in trimmed) record.toJson()]),
        flush: true,
      );
    } catch (_) {
      // Storico non persistito: i dati restano validi in memoria.
    }
  }
}
