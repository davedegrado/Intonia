import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lista di record su un file JSON nei documenti dell'app, come gli altri
/// storici (estensione, sessioni). File assente o illeggibile = lista vuota.
class JsonListRepository<T> {
  JsonListRepository({
    required this.fileName,
    required this.fromJson,
    required this.toJson,
    this.maxItems,
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  final String fileName;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;

  /// Elementi conservati (i più recenti); null = tutti.
  final int? maxItems;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file() async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  Future<List<T>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      final items = <T>[];
      for (final item in decoded) {
        try {
          items.add(fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Un record danneggiato non fa perdere gli altri.
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<T> items) async {
    final max = maxItems;
    final kept = max != null && items.length > max ? items.sublist(items.length - max) : items;
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode([for (final item in kept) toJson(item)]), flush: true);
    } catch (_) {
      // Non persistito: i dati restano validi in memoria.
    }
  }
}
