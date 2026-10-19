import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../../app/main_shell.dart';
import '../../../app/neon_scene.dart';
import '../application/achievements_providers.dart';
import '../domain/achievements.dart';

/// Accesso compatto a obiettivi e badge dal Profilo: badge sbloccati e
/// missioni di oggi completate.
class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final view = ref.watch(achievementsProvider);
    final daily = view?.daily ?? const <MissionProgress>[];
    return Card(
      key: const ValueKey('achievements-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => pushFullScreen(context, ref, '/achievements'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              AccentIcon(
                  icon: Icons.military_tech_rounded, color: context.decor.accent(0), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.achievementsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      view == null
                          ? '…'
                          : l10n.achievementsProfileSummary(
                              view.unlocked.length,
                              AchievementId.values.length,
                              daily.where((mission) => mission.done).length,
                              daily.length,
                            ),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
