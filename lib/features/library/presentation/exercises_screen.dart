import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart' show brandCyan, brandIndigo, brandViolet;
import '../../../app/main_shell.dart';
import '../../../app/status_chips.dart';
import '../../../core/music/exercise.dart';
import '../../access/application/access_providers.dart';
import '../../access/domain/entitlement.dart';
import '../application/exercise_providers.dart';

/// Catalogo degli esercizi strutturati: "Crea la tua sequenza", le sequenze
/// salvate e le categorie predefinite.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final library = ref.watch(exerciseLibraryProvider);
    final custom = ref.watch(customExercisesProvider).value ?? const <ExerciseDefinition>[];

    final sections = <ExerciseCategory, List<ExerciseDefinition>>{
      for (final category in ExerciseCategory.values) category: [],
    };
    for (final exercise in library.builtIn) {
      sections[exercise.category]!.add(exercise);
    }
    sections[ExerciseCategory.custom]!.addAll(custom);

    final categories = [
      for (final category in ExerciseCategory.values)
        if (category != ExerciseCategory.custom && sections[category]!.isNotEmpty) category,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esercizi'),
        actions: const [StatusChips()],
      ),
      body: ListView(
        key: const PageStorageKey('exercises-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CustomSection(exercises: sections[ExerciseCategory.custom]!),
          const SizedBox(height: 20),
          Text('Categorie',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final (index, category) in categories.indexed)
            _CategoryAccordion(
              category: category,
              exercises: sections[category]!,
              accent: _accents[index % _accents.length],
            ),
        ],
      ),
    );
  }

  /// Accenti alternati (ciano / viola / indaco) per distinguere le categorie.
  static const _accents = [brandCyan, brandViolet, brandIndigo];
}

/// Icona di ogni categoria predefinita.
IconData categoryIcon(ExerciseCategory category) => switch (category) {
      ExerciseCategory.custom => Icons.edit_note,
      ExerciseCategory.triads => Icons.queue_music,
      ExerciseCategory.arpeggios => Icons.equalizer,
      ExerciseCategory.pentatonics => Icons.pentagon_outlined,
      ExerciseCategory.scales => Icons.stairs_outlined,
      ExerciseCategory.harmonizations => Icons.join_full,
      ExerciseCategory.patterns => Icons.timeline,
    };

void _open(BuildContext context, WidgetRef ref, String route, {Object? extra}) =>
    pushFullScreen(context, ref, route, extra: extra);

/// "Crea la tua sequenza" in evidenza + elenco delle sequenze salvate.
class _CustomSection extends ConsumerWidget {
  const _CustomSection({required this.exercises});

  final List<ExerciseDefinition> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canCreate = ref.watch(entitlementProvider).allows(ProFeature.customSequences);

    final grouped = <String, List<ExerciseDefinition>>{};
    for (final exercise in exercises) {
      final group = exercise.group;
      if (group != null) {
        grouped.putIfAbsent(group, () => []).add(exercise);
      }
    }
    final groupNames = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('create-sequence'),
          color: colors.primaryContainer,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context, ref, '/editor'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [brandIndigo, brandViolet]),
                    ),
                    child: const Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crea la tua sequenza',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Componi qualsiasi giro di note: pattern, vocalizzi, prove di estensione…',
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
                        ),
                        if (!canCreate) ...[
                          const SizedBox(height: 6),
                          const ProBadge(),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onPrimaryContainer),
                ],
              ),
            ),
          ),
        ),
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(ExerciseCategory.custom.label,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
        // Sequenze senza gruppo: elencate direttamente.
        for (final exercise in exercises)
          if (exercise.group == null) _ExerciseTile(exercise: exercise),
        // Sequenze raggruppate: un accordion per gruppo.
        for (final name in groupNames)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: PageStorageKey('group-$name'),
                leading: const Icon(Icons.folder_outlined),
                title: Text(name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  grouped[name]!.length == 1 ? '1 sequenza' : '${grouped[name]!.length} sequenze',
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
      ],
    );
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    required this.category,
    required this.exercises,
    required this.accent,
  });

  final ExerciseCategory category;
  final List<ExerciseDefinition> exercises;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('category-${category.name}'),
        tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categoryIcon(category), color: accent),
        ),
        title: Text(category.label,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${category.description} · ${exercises.length} esercizi',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          for (final exercise in exercises) _ExerciseTile(exercise: exercise, dense: true),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Etichetta delle funzioni Intonia Pro.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
      child: Text('PRO',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w800,
              )),
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
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('${exercise.steps.length} note'),
          if (exercise.focus != null)
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
      ),
      leading: Icon(exercise.isCustom ? Icons.edit_note : Icons.music_note),
      trailing: exercise.isCustom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifica',
                  onPressed: () => _open(context, ref, '/editor', extra: exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Elimina',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _open(context, ref, '/trainer', extra: exercise),
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
