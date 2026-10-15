import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show brandCyan, brandIndigo, brandViolet;
import '../../../app/date_format.dart';
import '../../../app/main_shell.dart';
import '../../../app/note_text.dart';
import '../../../app/status_chips.dart';
import '../../../core/music/note.dart';
import '../../../core/session/range_record.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/intonia_mascot.dart';
import '../../settings/application/settings_providers.dart';
import '../application/range_providers.dart';

/// Sezione Estensione vocale: invito al test, ultimo risultato e test
/// precedenti. Il test vero e proprio è a schermo intero (/range-test).
class RangeScreen extends ConsumerWidget {
  const RangeScreen({super.key});

  /// Test precedenti mostrati qui; lo storico completo è nel Profilo.
  static const previousShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notation = ref.watch(notationProvider);
    final ranges = ref.watch(rangeHistoryProvider).value ?? const <RangeRecord>[];
    final latest = ranges.isNotEmpty ? ranges.last : null;
    final previous = [
      for (var i = ranges.length - 2; i >= 0 && i >= ranges.length - 1 - previousShown; i--)
        (record: ranges[i], before: i > 0 ? ranges[i - 1] : null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estensione vocale'),
        actions: const [StatusChips()],
      ),
      body: ListView(
        key: const PageStorageKey('range-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(
            child: IntoniaMascot(mood: MascotMood.idle, size: 150),
          ),
          const SizedBox(height: 12),
          Text(
            'Scopri la tua estensione vocale',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Parti da una nota comoda: scendiamo fino alla più grave e saliamo fino '
            'alla più acuta che riesci a cantare. Il risultato resta nel profilo per '
            'seguire i progressi.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('range-start'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => pushFullScreen(context, ref, '/range-test'),
            icon: const Icon(Icons.graphic_eq),
            label: Text(latest == null ? 'Avvia test' : 'Rifai il test'),
          ),
          const SizedBox(height: 20),
          if (latest == null)
            Text(
              'Nessun test ancora: il tuo risultato comparirà qui.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            )
          else
            _LatestResult(record: latest, notation: notation),
          if (previous.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Test precedenti',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final item in previous)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.height),
                title: NoteRangeText(
                  low: spelledMidi(item.record.minMidi),
                  high: spelledMidi(item.record.maxMidi),
                  notation: notation,
                  suffix: '  (${formatSpan(item.record.spanSemitones)})',
                ),
                subtitle: Text(formatShortDate(item.record.timestamp)),
              ),
          ],
          if (ranges.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('range-history'),
                onPressed: () => goToSection(context, ref, '/profile'),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Storico dei test nel profilo'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ultimo test salvato: estensione, ampiezza e data.
class _LatestResult extends StatelessWidget {
  const _LatestResult({required this.record, required this.notation});

  final RangeRecord record;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final noteStyle = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);

    return Card(
      key: const ValueKey('range-latest'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ultimo risultato', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            NoteRangeText(
              low: spelledMidi(record.minMidi),
              high: spelledMidi(record.maxMidi),
              notation: notation,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              octaveColor: colors.onSurfaceVariant,
            ),
            Text(
              '${formatSpan(record.spanSemitones)} (${record.spanSemitones} semitoni)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [brandCyan, brandIndigo, brandViolet]),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                NoteText(spelledMidi(record.minMidi), notation: notation, style: noteStyle),
                const Spacer(),
                NoteText(spelledMidi(record.maxMidi), notation: notation, style: noteStyle),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatShortDate(record.timestamp), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
