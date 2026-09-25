import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/music/exercise.dart';

/// Persistenza degli esercizi custom su file JSON nella cartella documenti
/// dell'app (nessuna dipendenza aggiuntiva, funziona offline).
class CustomExerciseRepository {
  CustomExerciseRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  static const _fileName = 'custom_exercises.json';

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<ExerciseDefinition>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const [];
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => ExerciseDefinition.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<ExerciseDefinition> exercises) async {
    final file = await _file();
    final payload = jsonEncode([for (final exercise in exercises) exercise.toJson()]);
    await file.writeAsString(payload, flush: true);
  }
}
