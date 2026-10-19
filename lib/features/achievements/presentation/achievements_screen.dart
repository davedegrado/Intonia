import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../application/achievements_providers.dart';
import '../domain/achievements.dart';
import 'achievement_badge.dart';

/// Obiettivi, missioni e badge (dal Profilo).
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: SafeArea(
        child: view == null
            ? const Center(child: CircularProgressIndicator())
            : _AchievementsList(view: view),
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  const _AchievementsList({required this.view});

  final AchievementsView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final decor = context.decor;
    final hint = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final sunday =
        view.weekly.isEmpty ? null : view.weekly.first.end.subtract(const Duration(days: 1));

    return ListView(
      key: const PageStorageKey('achievements-list'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.achievementsCoach, mascotSize: 56),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Stat(
                  key: const ValueKey('achievements-streak'),
                  icon: Icons.local_fire_department_rounded,
                  color: decor.streak,
                  label: l10n.achievementsStreakCurrent,
                  value: l10n.achievementsDays(view.currentStreak),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  key: const ValueKey('achievements-best'),
                  icon: Icons.whatshot_rounded,
                  color: decor.accent(2),
                  label: l10n.achievementsStreakBest,
                  value: l10n.achievementsDays(view.bestStreak),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  key: const ValueKey('achievements-count'),
                  icon: Icons.military_tech_rounded,
                  color: decor.accent(0),
                  label: l10n.achievementsBadges,
                  value: l10n.achievementsBadgeCount(
                    view.unlocked.length,
                    AchievementId.values.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Title(l10n.achievementsDaily),
        Text(l10n.achievementsDailyHint, style: hint),
        const SizedBox(height: 8),
        for (final mission in view.daily) _MissionTile(mission: mission),
        const SizedBox(height: 16),
        _Title(l10n.achievementsWeekly),
        if (sunday != null) Text(l10n.achievementsWeeklyHint(sunday), style: hint),
        const SizedBox(height: 8),
        for (final mission in view.weekly) _MissionTile(mission: mission),
        for (final category in AchievementCategory.values) ...[
          const SizedBox(height: 20),
          _Title(l10n.achievementCategory(category)),
          const SizedBox(height: 8),
          _BadgeGrid(
            view: view,
            ids: [
              for (final id in AchievementId.values)
                if (id.category == category) id,
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.achievementsCountingRules, style: hint),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final MissionProgress mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final l10n = context.l10n;
    return Card(
      key: ValueKey('mission-${mission.kind.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(
          children: [
            Icon(
              mission.done ? Icons.check_circle_rounded : missionIcon(mission.kind),
              color: mission.done ? decor.success : colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.missionTitle(mission.kind), style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: mission.fraction,
                      minHeight: 6,
                      color: mission.done ? decor.success : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              mission.done
                  ? l10n.achievementsMissionDone
                  : l10n.achievementsProgress(mission.value, mission.target),
              style: theme.textTheme.labelMedium?.copyWith(
                color: mission.done ? decor.success : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.view, required this.ids});

  final AchievementsView view;
  final List<AchievementId> ids;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tre colonne sui telefoni, quattro se c'è spazio.
        final columns = constraints.maxWidth >= 480 ? 4 : 3;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in ids)
              SizedBox(
                width: width,
                child: _BadgeTile(id: id, view: view),
              ),
          ],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.id, required this.view});

  final AchievementId id;
  final AchievementsView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unlocked = view.isUnlocked(id);
    final progress = view.progress[id]!;
    return Card(
      key: ValueKey('badge-${id.name}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAchievementDetails(context, view, id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
          child: Column(
            children: [
              AchievementBadge(id: id, unlocked: unlocked, fraction: progress.fraction),
              const SizedBox(height: 8),
              Text(
                l10n.achievementName(id),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                unlocked
                    ? l10n.achievementsUnlocked
                    : l10n.achievementsProgress(progress.value, progress.target),
                style:
                    theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dettaglio di un badge: nome, condizione, stato, data o avanzamento.
Future<void> showAchievementDetails(BuildContext context, AchievementsView view, AchievementId id) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = context.l10n;
      final unlockedAt = view.unlocked[id];
      final progress = view.progress[id]!;
      return SafeArea(
        child: Padding(
          key: const ValueKey('badge-details'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AchievementBadge(
                id: id,
                unlocked: unlockedAt != null,
                fraction: progress.fraction,
                size: 84,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.achievementName(id),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.achievementDescription(id),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (id == AchievementId.noteRun10) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.achievementNoteRunHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                unlockedAt != null
                    ? l10n.achievementsUnlockedOn(unlockedAt)
                    : l10n.achievementsLocked,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (unlockedAt == null && progress.target > 1) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: progress.fraction, minHeight: 6),
                ),
                const SizedBox(height: 4),
                Text(l10n.achievementsProgress(progress.value, progress.target)),
              ],
            ],
          ),
        ),
      );
    },
  );
}
