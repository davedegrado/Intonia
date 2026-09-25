import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/session/range_record.dart';
import '../../../core/session/session_record.dart';
import '../../range/application/range_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/history_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notation = ref.watch(notationProvider);
    final records = ref.watch(sessionHistoryProvider).value ?? const <SessionRecord>[];
    final ranges = ref.watch(rangeHistoryProvider).value ?? const <RangeRecord>[];

    if (records.isEmpty && ranges.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Nessuna sessione ancora', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Completa un allenamento: qui troverai streak, accuratezza, estensione vocale e storico.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final streak = computeStreak(records.map((r) => r.timestamp), DateTime.now());
    final totalAttempts = records.fold<int>(0, (sum, r) => sum + r.totalAttempts);
    final totalCorrect = records.fold<int>(0, (sum, r) => sum + r.correct);
    final avgAccuracy = totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;
    final totalMinutes = records.fold<int>(0, (sum, r) => sum + r.durationSeconds) ~/ 60;

    int? minMidi;
    int? maxMidi;
    for (final record in records) {
      if (record.minCorrectMidi != null &&
          (minMidi == null || record.minCorrectMidi! < minMidi)) {
        minMidi = record.minCorrectMidi;
      }
      if (record.maxCorrectMidi != null &&
          (maxMidi == null || record.maxCorrectMidi! > maxMidi)) {
        maxMidi = record.maxCorrectMidi;
      }
    }
    String noteLabel(int midi) =>
        NoteSpeller.spellRoot(MusicalNote.fromMidi(midi)).fullLabel(notation);
    // Estensione: il test dedicato ha priorità sulle note delle sessioni.
    final latestRange = ranges.isNotEmpty ? ranges.last : null;
    final extension = latestRange != null
        ? '${noteLabel(latestRange.minMidi)} – ${noteLabel(latestRange.maxMidi)}'
        : minMidi != null && maxMidi != null
            ? '${noteLabel(minMidi)} – ${noteLabel(maxMidi)}'
            : '—';

    // Accuratezza per pitch class (min 5 tentativi).
    final byPitch = <int, List<int>>{};
    for (final record in records) {
      for (final entry in record.perNote.entries) {
        final counts = byPitch.putIfAbsent(entry.key % 12, () => [0, 0]);
        counts[0] += entry.value[0];
        counts[1] += entry.value[1];
      }
    }
    final rated = [
      for (final entry in byPitch.entries)
        if (entry.value[0] + entry.value[1] >= 5)
          (
            pitch: PitchClass.fromSemitone(entry.key),
            accuracy: entry.value[0] / (entry.value[0] + entry.value[1]),
            attempts: entry.value[0] + entry.value[1],
          ),
    ]..sort((a, b) => b.accuracy.compareTo(a.accuracy));

    final recent = records.reversed.take(8).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Streak in evidenza.
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 44, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          streak == 1 ? '1 giorno di fila' : '$streak giorni di fila',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          streak == 0
                              ? 'Allenati oggi per far partire la streak!'
                              : 'Continua così, non spezzarla!',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatCard(label: 'Sessioni', value: '${records.length}'),
                _StatCard(label: 'Minuti totali', value: '$totalMinutes'),
                _StatCard(
                    label: 'Accuratezza media',
                    value: '${(avgAccuracy * 100).toStringAsFixed(0)}%'),
                _StatCard(label: 'Estensione', value: extension),
              ],
            ),
            if (rated.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Note migliori e peggiori',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final item in rated.length <= 6
                  ? rated
                  : [...rated.take(3), ...rated.skip(rated.length - 3)])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          NoteSpeller.keyLabel(item.pitch, notation),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: item.accuracy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(item.accuracy * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
            if (ranges.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Test estensione vocale',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (var i = ranges.length - 1; i >= 0 && i >= ranges.length - 5; i--)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.height),
                  title: Text(
                    '${noteLabel(ranges[i].minMidi)} – ${noteLabel(ranges[i].maxMidi)}'
                    '  (${formatSpan(ranges[i].spanSemitones)})',
                  ),
                  subtitle: Text(_formatDate(ranges[i].timestamp) +
                      (i > 0
                          ? '  ·  ${_deltaLabel(ranges[i].spanSemitones - ranges[i - 1].spanSemitones)}'
                          : '')),
                  trailing: IconButton(
                    tooltip: 'Elimina test',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _confirmDeleteRange(context, ref, ranges[i]),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text('Ultime sessioni',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final record in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(record.isCustomExercise ? Icons.edit_note : Icons.history),
                title: Text(record.exerciseName),
                subtitle: Text(_formatDate(record.timestamp)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(record.accuracy * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: record.accuracy >= 0.8
                            ? const Color(0xFF1F8A5B)
                            : record.accuracy >= 0.5
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                      ),
                    ),
                    // Solo le sessioni su esercizi custom sono eliminabili:
                    // servono a non sporcare le statistiche con sequenze
                    // sbagliate o impossibili create per prova.
                    if (record.isCustomExercise)
                      IconButton(
                        tooltip: 'Elimina sessione',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDeleteSession(context, ref, record),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _deltaLabel(int delta) {
    if (delta > 0) {
      return '+$delta st rispetto al precedente';
    }
    if (delta == 0) {
      return 'invariato';
    }
    return '$delta st rispetto al precedente';
  }

  Future<void> _confirmDeleteRange(
    BuildContext context,
    WidgetRef ref,
    RangeRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il test?'),
        content: Text('Il test del ${_formatDate(record.timestamp)} verrà rimosso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(rangeHistoryProvider.notifier).remove(record);
    }
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WidgetRef ref,
    SessionRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la sessione?'),
        content: Text(
          '"${record.exerciseName}" del ${_formatDate(record.timestamp)} '
          'verrà rimossa da statistiche, streak ed estensione vocale.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionHistoryProvider.notifier).remove(record);
    }
  }

  String _formatDate(DateTime timestamp) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(timestamp.day)}/${pad(timestamp.month)} ${pad(timestamp.hour)}:${pad(timestamp.minute)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
