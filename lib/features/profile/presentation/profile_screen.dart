import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart' show brandCyan, brandIndigo;
import '../../../app/date_format.dart';
import '../../../app/status_chips.dart' show streakColor;
import '../../access/application/access_providers.dart';
import '../../access/domain/entitlement.dart';
import '../../../app/note_text.dart';
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
        appBar: _appBar(context),
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
      if (record.minCorrectMidi != null && (minMidi == null || record.minCorrectMidi! < minMidi)) {
        minMidi = record.minCorrectMidi;
      }
      if (record.maxCorrectMidi != null && (maxMidi == null || record.maxCorrectMidi! > maxMidi)) {
        maxMidi = record.maxCorrectMidi;
      }
    }
    // Estensione: il test dedicato ha priorità sulle note delle sessioni.
    final latestRange = ranges.isNotEmpty ? ranges.last : null;
    final (lowMidi, highMidi) =
        latestRange != null ? (latestRange.minMidi, latestRange.maxMidi) : (minMidi, maxMidi);

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

    // Free: ultime sessioni; Pro: storico completo.
    final fullHistory = ref.watch(entitlementProvider).allows(ProFeature.fullHistory);
    final recent = fullHistory
        ? records.reversed.toList()
        : records.reversed.take(freeRecentSessions).toList();

    return Scaffold(
      appBar: _appBar(context),
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
                        size: 44,
                        color: streak > 0 ? streakColor : theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StatRow(children: [
              _StatCard(label: 'Sessioni', value: '${records.length}'),
              _StatCard(label: 'Minuti totali', value: '$totalMinutes'),
            ]),
            const SizedBox(height: 10),
            _StatRow(children: [
              _StatCard(
                  label: 'Accuratezza media', value: '${(avgAccuracy * 100).toStringAsFixed(0)}%'),
              _StatCard(
                label: 'Estensione',
                value: '—',
                valueWidget: lowMidi != null && highMidi != null
                    ? NoteRangeText(
                        low: spelledMidi(lowMidi),
                        high: spelledMidi(highMidi),
                        notation: notation,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
            ]),
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
                        child: _AccuracyBar(value: item.accuracy),
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
                  title: NoteRangeText(
                    low: spelledMidi(ranges[i].minMidi),
                    high: spelledMidi(ranges[i].maxMidi),
                    notation: notation,
                    suffix: '  (${formatSpan(ranges[i].spanSemitones)})',
                  ),
                  subtitle: Text(formatShortDate(ranges[i].timestamp) +
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
            Text(fullHistory ? 'Tutte le sessioni' : 'Ultime sessioni',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final record in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(record.isCustomExercise ? Icons.edit_note : Icons.history),
                title: Text(record.exerciseName),
                subtitle: Text(formatShortDate(record.timestamp)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${record.accuracyPercent}%',
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
            if (!fullHistory && records.length > freeRecentSessions)
              TextButton.icon(
                key: const ValueKey('full-history-pro'),
                onPressed: () => context.push('/pro'),
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text('Storico completo (${records.length} sessioni) con Intonia Pro'),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            key: const ValueKey('profile-settings'),
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      );

  /// Sessioni mostrate agli utenti Free.
  static const freeRecentSessions = 8;

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
        content: Text('Il test del ${formatShortDate(record.timestamp)} verrà rimosso.'),
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
          '"${record.exerciseName}" del ${formatShortDate(record.timestamp)} '
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.valueWidget});

  final String label;
  final String value;

  /// Sostituisce [value] quando serve un testo composto (es. note con ottava).
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              valueWidget ??
                  Text(value,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Due statistiche affiancate, della stessa altezza.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 10),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}

/// Barra di accuratezza con sfumatura ciano → viola.
class _AccuracyBar extends StatelessWidget {
  const _AccuracyBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(colors: [brandCyan, brandIndigo]),
          ),
        ),
      ),
    );
  }
}
