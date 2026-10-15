import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../../app/main_shell.dart';
import '../../../app/neon_scene.dart';
import '../../../app/status_chips.dart';
import '../../../core/music/exercise.dart';
import '../../../l10n/exercise_l10n.dart';
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

    final decor = context.decor;
    final l10n = context.l10n;
    return SectionScaffold(
      title: l10n.navExercises,
      actions: const [StatusChips()],
      body: ListView(
        key: const PageStorageKey('exercises-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CustomSection(exercises: sections[ExerciseCategory.custom]!),
          const SizedBox(height: 22),
          Text(l10n.exercisesCategories,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final (index, category) in categories.indexed)
            _CategoryAccordion(
              category: category,
              exercises: sections[category]!,
              accent: decor.accent(index),
            ),
        ],
      ),
    );
  }
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
    final l10n = context.l10n;
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
        _CreateSequenceCard(
          showPro: !canCreate,
          onTap: () => _open(context, ref, '/editor'),
        ),
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.categoryLabel(ExerciseCategory.custom),
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
                  l10n.exercisesSequenceCount(grouped[name]!.length),
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
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('category-${category.name}'),
        tilePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        iconColor: accent,
        leading: AccentIcon(icon: categoryIcon(category), color: accent, size: 50),
        title: Text(l10n.categoryLabel(category),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: l10n.categoryDescription(category)),
              TextSpan(
                text: '  ·  ${l10n.exercisesCount(exercises.length)}',
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ]),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
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
      child: Text(context.l10n.exercisesProBadge,
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
    final l10n = context.l10n;
    final tile = ListTile(
      dense: dense,
      title: Text(l10n.exerciseName(exercise)),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.exercisesNoteCount(exercise.steps.length)),
          if (exercise.focus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.focusLabel(exercise.focus!),
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
                  tooltip: l10n.exercisesEdit,
                  onPressed: () => _open(context, ref, '/editor', extra: exercise),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.commonDelete,
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
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exercisesDeleteTitle),
        content: Text(l10n.exercisesDeleteMessage(l10n.exerciseName(exercise))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customExercisesProvider.notifier).remove(exercise.id);
    }
  }
}

/// "Crea la tua sequenza": l'elemento più in evidenza del catalogo.
class _CreateSequenceCard extends StatelessWidget {
  const _CreateSequenceCard({required this.showPro, required this.onTap});

  final bool showPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decor = context.decor;
    final radius = BorderRadius.circular(22);
    return Container(
      key: const ValueKey('create-sequence'),
      decoration: BoxDecoration(
        gradient: decor.featureGradient,
        borderRadius: radius,
        border: Border.all(
          color: decor.ambient ? decor.featureBorder.withValues(alpha: 0.7) : decor.featureBorder,
        ),
        boxShadow: decor.ambient
            ? [
                BoxShadow(
                  color: decor.glow.withValues(alpha: 0.3),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 14, 20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: decor.heroGradient,
                    border: Border.all(
                      color:
                          decor.ambient ? Colors.white.withValues(alpha: 0.35) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.add_rounded, size: 36, color: decor.onHero),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.exercisesCreateTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: decor.onFeature,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.exercisesCreateSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: decor.onFeature.withValues(alpha: 0.85),
                        ),
                      ),
                      if (showPro) ...[
                        const SizedBox(height: 8),
                        const ProBadge(),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 28, color: decor.onFeature),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
