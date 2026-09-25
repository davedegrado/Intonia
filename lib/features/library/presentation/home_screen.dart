import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/music/exercise.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/session/range_record.dart';
import '../../../core/session/session_record.dart';
import '../../profile/application/history_providers.dart';
import '../../range/application/range_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../tuner/application/tuner_controller.dart';
import '../application/exercise_providers.dart';

/// Naviga fermando prima il riconoscimento in tempo reale, se attivo.
void _go(BuildContext context, WidgetRef ref, String route, {Object? extra}) {
  ref.read(tunerControllerProvider.notifier).stop();
  context.push(route, extra: extra);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(exerciseLibraryProvider);
    final customAsync = ref.watch(customExercisesProvider);
    final custom = customAsync.value ?? const <ExerciseDefinition>[];
    final sessions = ref.watch(sessionHistoryProvider).value ?? const <SessionRecord>[];
    final streak = computeStreak(sessions.map((r) => r.timestamp), DateTime.now());

    final sections = <ExerciseCategory, List<ExerciseDefinition>>{
      for (final category in ExerciseCategory.values) category: [],
    };
    for (final exercise in library.builtIn) {
      sections[exercise.category]!.add(exercise);
    }
    sections[ExerciseCategory.custom]!.addAll(custom);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intonia'),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                avatar: const Icon(Icons.local_fire_department,
                    size: 18, color: Color(0xFFF97316)),
                label: Text('$streak',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () => _go(context, ref, '/profile'),
              ),
            ),
          IconButton(
            tooltip: 'Profilo e statistiche',
            icon: const Icon(Icons.person_outline),
            onPressed: () => _go(context, ref, '/profile'),
          ),
          IconButton(
            tooltip: 'Impostazioni',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _go(context, ref, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _TunerCard(),
            const SizedBox(height: 8),
            const _RangeCard(),
            const SizedBox(height: 8),
            _CustomSection(exercises: sections[ExerciseCategory.custom]!),
            const SizedBox(height: 8),
            for (final category in ExerciseCategory.values)
              if (category != ExerciseCategory.custom)
                _CategoryAccordion(
                  category: category,
                  exercises: sections[category]!,
                  initiallyExpanded: category == ExerciseCategory.triads,
                ),
          ],
        ),
      ),
    );
  }
}

/// Riconoscimento in tempo reale: parte solo col bottone, si ferma su stop,
/// cambio schermata o app in background.
class _TunerCard extends ConsumerStatefulWidget {
  const _TunerCard();

  @override
  ConsumerState<_TunerCard> createState() => _TunerCardState();
}

class _TunerCardState extends ConsumerState<_TunerCard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(tunerControllerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tuner = ref.watch(tunerControllerProvider);
    final notation = ref.watch(notationProvider);
    final detection = tuner.detection;
    final hasPitch = detection != null && detection.isStable;

    // Dimensione FISSA: l'area variabile (sottotitolo/nota rilevata) ha
    // un'altezza riservata e il pulsante una larghezza riservata, così la
    // card non "salta" all'avvio o quando aggancia una nota.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riconoscimento in tempo reale',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: !tuner.active
                          ? Text('Canta o suona una nota: ti dico qual è.',
                              style: theme.textTheme.bodySmall)
                          : hasPitch
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NoteSpeller.spellRoot(detection.note).fullLabel(notation),
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        '${detection.cents >= 0 ? '+' : ''}${detection.cents.toStringAsFixed(0)} cent',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: detection.cents.abs() <= 20
                                              ? const Color(0xFF1F8A5B)
                                              : theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text('In ascolto…', style: theme.textTheme.bodySmall),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 112,
              height: 48,
              child: Center(
                child: tuner.active
                    ? IconButton.filledTonal(
                        tooltip: 'Ferma',
                        onPressed: () => ref.read(tunerControllerProvider.notifier).stop(),
                        icon: const Icon(Icons.stop),
                      )
                    : FilledButton.icon(
                        onPressed: () => ref.read(tunerControllerProvider.notifier).start(),
                        icon: const Icon(Icons.mic, size: 18),
                        label: const Text('Avvia'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estensione vocale in evidenza: ultimo test + invito a (ri)farlo.
class _RangeCard extends ConsumerWidget {
  const _RangeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final notation = ref.watch(notationProvider);
    final ranges = ref.watch(rangeHistoryProvider).value ?? const <RangeRecord>[];
    final latest = ranges.isNotEmpty ? ranges.last : null;

    String noteLabel(int midi) =>
        NoteSpeller.spellRoot(MusicalNote.fromMidi(midi)).fullLabel(notation);

    return Card(
      elevation: 0,
      color: colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _go(context, ref, '/range-test'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: latest == null
              ? Row(
                  children: [
                    Icon(Icons.height, size: 40, color: colors.onPrimaryContainer),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Test estensione vocale',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700)),
                          Text('Scopri la tua nota più grave e più acuta e traccia i progressi.',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.onPrimaryContainer)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.onPrimaryContainer),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.height, size: 22, color: colors.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Estensione vocale',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text('Rifai il test',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: colors.onPrimaryContainer)),
                        Icon(Icons.chevron_right, size: 18, color: colors.onPrimaryContainer),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatSpan(latest.spanSemitones),
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: colors.onPrimaryContainer),
                    ),
                    Text('(${latest.spanSemitones} semitoni)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onPrimaryContainer)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(noteLabel(latest.minMidi),
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFFA855F7)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(noteLabel(latest.maxMidi),
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Sezione Custom: card in evidenza con invito a creare la propria sequenza
/// + elenco delle sequenze salvate.
class _CustomSection extends ConsumerWidget {
  const _CustomSection({required this.exercises});

  final List<ExerciseDefinition> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: colors.primaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _go(context, ref, '/editor'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.add_circle, size: 40, color: colors.onPrimaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crea la tua sequenza',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Componi qualsiasi giro di note: pattern, vocalizzi, prove di estensione…',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
        // Sequenze senza gruppo: elencate direttamente.
        for (final exercise in exercises)
          if (exercise.group == null) _ExerciseTile(exercise: exercise),
        // Sequenze raggruppate: un accordion per gruppo.
        ...(() {
          final grouped = <String, List<ExerciseDefinition>>{};
          for (final exercise in exercises) {
            final group = exercise.group;
            if (group != null) {
              grouped.putIfAbsent(group, () => []).add(exercise);
            }
          }
          final names = grouped.keys.toList()..sort();
          return [
            for (final name in names)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      grouped[name]!.length == 1
                          ? '1 sequenza'
                          : '${grouped[name]!.length} sequenze',
                      style: theme.textTheme.bodySmall,
                    ),
                    children: [
                      for (final exercise in grouped[name]!)
                        _ExerciseTile(exercise: exercise, dense: true),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
          ];
        })(),
      ],
    );
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    required this.category,
    required this.exercises,
    this.initiallyExpanded = false,
  });

  final ExerciseCategory category;
  final List<ExerciseDefinition> exercises;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(category.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(category.description, style: theme.textTheme.bodySmall),
        children: [
          for (final exercise in exercises) _ExerciseTile(exercise: exercise, dense: true),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  const _ExerciseTile({required this.exercise, this.dense = false});

  final ExerciseDefinition exercise;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tile = ListTile(
      dense: dense,
      title: Text(exercise.name),
      subtitle: Row(
        children: [
          Text('${exercise.steps.length} note'),
          if (exercise.focus != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.focus!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      leading: Icon(exercise.isCustom ? Icons.edit_note : Icons.music_note),
      trailing: exercise.isCustom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifica',
                  onPressed: () => _go(context, ref, '/editor', extra: exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Elimina',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _go(context, ref, '/trainer', extra: exercise),
    );

    if (!exercise.isCustom || dense) {
      return tile;
    }
    return Card(margin: const EdgeInsets.only(top: 8), child: tile);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la sequenza?'),
        content: Text('"${exercise.name}" verrà rimossa definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customExercisesProvider.notifier).remove(exercise.id);
    }
  }
}
