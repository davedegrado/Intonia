import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../../app/main_shell.dart';
import '../../../app/neon_scene.dart';
import '../application/workout_controller.dart';
import '../domain/daily_workout.dart';

/// Accesso compatto all'allenamento del giorno nella Home: durata, numero di
/// esercizi e stato di oggi; il dettaglio e la scelta della durata sono
/// nella schermata dell'allenamento.
class DailyWorkoutCard extends ConsumerWidget {
  const DailyWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final l10n = context.l10n;
    final state = ref.watch(workoutControllerProvider);
    final plan = state.plan;
    final today = state.today;
    final doneToday = today != null && today.outcome != WorkoutOutcome.interrupted;

    final subtitle = state.status == WorkoutStatus.running
        ? l10n.workoutInProgress(state.doneCount, state.total)
        : doneToday
            ? (today.outcome == WorkoutOutcome.completed
                ? l10n.workoutDoneToday
                : l10n.workoutPartialToday(today.completedIds.length, today.plannedIds.length))
            : plan == null
                ? '…'
                : l10n.workoutSummaryLine(plan.estimatedMinutes, plan.steps.length);

    return Card(
      key: const ValueKey('daily-workout-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => pushFullScreen(context, ref, '/workout'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              AccentIcon(
                icon: doneToday ? Icons.check_rounded : Icons.fitness_center_rounded,
                color: doneToday ? decor.success : decor.accent(1),
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.workoutTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      key: const ValueKey('daily-workout-status'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                state.status == WorkoutStatus.running
                    ? Icons.play_circle_fill
                    : Icons.chevron_right,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
