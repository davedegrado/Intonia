import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/date_format.dart';
import '../../../app/l10n.dart';
import '../../../app/main_shell.dart';
import '../../../app/neon_scene.dart';
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
    final l10n = context.l10n;
    final notation = ref.watch(notationProvider);
    final ranges = ref.watch(rangeHistoryProvider).value ?? const <RangeRecord>[];
    final latest = ranges.isNotEmpty ? ranges.last : null;
    final previous = [
      for (var i = ranges.length - 2; i >= 0 && i >= ranges.length - 1 - previousShown; i--)
        (record: ranges[i], before: i > 0 ? ranges[i - 1] : null),
    ];

    return SectionScaffold(
      title: l10n.rangeSectionTitle,
      actions: const [StatusChips()],
      variant: SceneVariant.range,
      body: ListView(
        key: const PageStorageKey('range-list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Center(
            child: MascotStage(
              size: 150,
              child: IntoniaMascot(mood: MascotMood.idle, size: 150),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.rangeHeadline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.rangeIntro,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          HeroButton(
            key: const ValueKey('range-start'),
            icon: Icons.graphic_eq_rounded,
            label: latest == null ? l10n.rangeStartTest : l10n.rangeRetakeTest,
            onPressed: () => pushFullScreen(context, ref, '/range-test'),
          ),
          const SizedBox(height: 22),
          if (latest == null)
            Text(
              l10n.rangeNoTestsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            )
          else
            _LatestResult(record: latest, notation: notation),
          if (previous.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(l10n.rangePreviousTests,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final (index, item) in previous.indexed) ...[
                    if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    _HistoryTile(record: item.record, before: item.before, notation: notation),
                  ],
                ],
              ),
            ),
          ],
          if (ranges.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('range-history'),
                onPressed: () => goToSection(context, ref, '/profile'),
                icon: const Icon(Icons.history, size: 18),
                label: Text(l10n.rangeHistoryInProfile),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ultimo test salvato: note estreme, ampiezza, posizione sulla tastiera e data.
class _LatestResult extends StatelessWidget {
  const _LatestResult({required this.record, required this.notation});

  final RangeRecord record;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final noteStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);
    final caption = theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant);
    final l10n = context.l10n;

    return Card(
      key: const ValueKey('range-latest'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.rangeLatestResult,
                      style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
                ),
                Text(formatShortDate(record.timestamp), style: caption),
                _NotMineMenu(key: const ValueKey('range-latest-menu'), record: record),
              ],
            ),
            const SizedBox(height: 6),
            NoteRangeText(
              low: spelledMidi(record.minMidi),
              high: spelledMidi(record.maxMidi),
              notation: notation,
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              octaveColor: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.rangeSpanDetail(l10n.span(record.spanSemitones), record.spanSemitones),
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _RangeBar(low: record.minMidi, high: record.maxMidi),
            const SizedBox(height: 8),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.rangeLowest, style: caption),
                    NoteText(spelledMidi(record.minMidi), notation: notation, style: noteStyle),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.rangeHighest, style: caption),
                    NoteText(spelledMidi(record.maxMidi), notation: notation, style: noteStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Estensione sulla tastiera: binario neutro (DO2–DO6, allargato se serve) e
/// tratto colorato fra la nota più grave e la più acuta.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.low, required this.high});

  final int low;
  final int high;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final decor = context.decor;
    final from = math.min(36, low - 2);
    final to = math.max(84, high + 2);
    final start = (low - from) / (to - from);
    final end = (high - from) / (to - from);

    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          Widget marker(double fraction) => Positioned(
                left: width * fraction - 9,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.onSurface, width: 3),
                    boxShadow: decor.ambient
                        ? [
                            BoxShadow(
                              color: decor.heroBorder.withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 6,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: width * start,
                width: width * (end - start),
                top: 4,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: decor.spectrum,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              marker(start),
              marker(end),
            ],
          );
        },
      ),
    );
  }
}

/// Un test precedente con la variazione rispetto al test prima.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.before, required this.notation});

  final RangeRecord record;
  final RangeRecord? before;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final delta = before == null ? null : record.spanSemitones - before!.spanSemitones;

    return ListTile(
      leading: AccentIcon(icon: Icons.height_rounded, color: decor.accent(2), size: 40),
      title: NoteRangeText(
        low: spelledMidi(record.minMidi),
        high: spelledMidi(record.maxMidi),
        notation: notation,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        suffix: '  (${context.l10n.span(record.spanSemitones)})',
      ),
      subtitle: Text(formatShortDate(record.timestamp)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (delta != null && delta != 0)
            Text(
              context.l10n.rangeDeltaShort('${delta > 0 ? '+' : ''}$delta'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: delta > 0 ? decor.success : colors.error,
              ),
            ),
          _NotMineMenu(record: record),
        ],
      ),
    );
  }
}

/// Conferma di "Non ero io": il test verrà tolto da risultati e storico.
Future<bool> confirmNotMine(BuildContext context, RangeRecord record) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.rangeNotMineTitle),
      content: Text(l10n.rangeNotMineBody(formatShortDate(record.timestamp))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
        FilledButton(
          key: const ValueKey('range-not-mine-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.rangeNotMineConfirm),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Menu di un test salvato con la voce "Non ero io".
class _NotMineMenu extends ConsumerWidget {
  const _NotMineMenu({required this.record, super.key});

  final RangeRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<void>(
      tooltip: context.l10n.rangeNotMine,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey('range-not-mine'),
          onTap: () async {
            if (await confirmNotMine(context, record)) {
              await ref.read(rangeHistoryProvider.notifier).remove(record);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.person_off_outlined),
              const SizedBox(width: 12),
              Text(context.l10n.rangeNotMine),
            ],
          ),
        ),
      ],
    );
  }
}
