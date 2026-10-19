import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../../tuner/application/tuner_controller.dart';
import '../../../app/note_text.dart';
import '../../../core/session/session_record.dart';
import '../../../l10n/exercise_l10n.dart';
import '../../access/application/access_providers.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/screens/session_result_screen.dart';
import '../application/workout_controller.dart';
import '../domain/daily_workout.dart';

/// Allenamento del giorno a schermo intero: proposta con la durata, poi un
/// esercizio alla volta nel trainer esistente, infine il riepilogo.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // La proposta tiene conto delle sessioni fatte da quando è stata creata.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutControllerProvider.notifier).refresh();
    });
  }

  /// Apre l'esercizio nel trainer; al ritorno, se era l'ultimo, mostra il
  /// riepilogo (solo ora: sopra il trainer coprirebbe il risultato
  /// dell'esercizio).
  Future<void> _openStep(WorkoutStep step) async {
    ref.read(tunerControllerProvider.notifier).stop();
    await context.push('/workout-exercise', extra: step);
    if (mounted && ref.read(workoutControllerProvider).status == WorkoutStatus.finished) {
      await _showSummary();
    }
  }

  /// Uscita durante l'allenamento: si chiede conferma e lo si salva come
  /// interrotto.
  Future<bool> _confirmInterrupt() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutInterruptTitle),
        content: Text(l10n.workoutInterruptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.workoutKeepGoing),
          ),
          FilledButton(
            key: const ValueKey('workout-interrupt-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.workoutInterrupt),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutControllerProvider.notifier).interrupt();
      return true;
    }
    return false;
  }

  /// "Salta": se era l'ultimo esercizio mostra il riepilogo.
  Future<void> _skip() async {
    await ref.read(workoutControllerProvider.notifier).skip();
    if (mounted && ref.read(workoutControllerProvider).status == WorkoutStatus.finished) {
      await _showSummary();
    }
  }

  /// "Interrompi l'allenamento": dopo conferma si torna alla Home.
  Future<void> _interruptAndLeave() async {
    // pop (non maybePop): il PopScope non si è ancora aggiornato e
    // chiederebbe di nuovo conferma.
    if (await _confirmInterrupt() && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showSummary() async {
    final controller = ref.read(workoutControllerProvider.notifier);
    final record = controller.summaryRecord(context.l10n.workoutTitle);
    final state = ref.read(workoutControllerProvider);
    if (record != null && state.completedCount > 0) {
      await Navigator.of(context).push(SessionResultScreen.route(record, showRepeat: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutControllerProvider);
    final l10n = context.l10n;
    final running = state.status == WorkoutStatus.running;

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmInterrupt() && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.workoutTitle)),
        body: SafeArea(
          child: switch (state.status) {
            WorkoutStatus.ready => _ProposalView(state: state),
            WorkoutStatus.running => _RunningView(
                state: state,
                onOpen: _openStep,
                onSkip: _skip,
                onInterrupt: _interruptAndLeave,
              ),
            WorkoutStatus.finished => _SummaryView(state: state),
          },
        ),
      ),
    );
  }
}

String roleLabel(AppLocalizations l10n, WorkoutRole role) => switch (role) {
      WorkoutRole.warmUp => l10n.workoutRoleWarmUp,
      WorkoutRole.main => l10n.workoutRoleMain,
      WorkoutRole.review => l10n.workoutRoleReview,
    };

/// "~3 min" / "~45 s".
String approxDuration(AppLocalizations l10n, int seconds) => seconds >= 90
    ? l10n.workoutApproxMinutes((seconds / 60).round())
    : l10n.workoutApproxSeconds(seconds);

class _ProposalView extends ConsumerWidget {
  const _ProposalView({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = state.plan;
    final controller = ref.read(workoutControllerProvider.notifier);
    final access = ref.watch(exerciseAccessProvider);
    if (plan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final hard = plan.steps.where((step) => step.difficult).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              MascotCoach(mood: MascotMood.greeting, message: l10n.workoutCoachReady),
              const SizedBox(height: 16),
              Text(l10n.workoutGoal, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(l10n.workoutDurationLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  key: const ValueKey('workout-duration'),
                  showSelectedIcon: false,
                  segments: [
                    for (final minutes in WorkoutGenerator.durations)
                      ButtonSegment(value: minutes, label: Text(l10n.workoutMinutes(minutes))),
                  ],
                  selected: {state.minutes},
                  onSelectionChanged: (selection) => controller.setMinutes(selection.first),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.workoutSummaryLine(plan.estimatedMinutes, plan.steps.length),
                key: const ValueKey('workout-summary-line'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                !plan.personalized
                    ? l10n.workoutBalanced
                    : hard > 0
                        ? l10n.workoutPersonalizedHard(hard)
                        : l10n.workoutPersonalized,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final (index, step) in plan.steps.indexed) ...[
                      if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _StepTile(step: step, status: null),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.workoutDurationNote,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (!access.unlimited) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.workoutChargesNote(plan.steps.length, access.charges.charges),
                  key: const ValueKey('workout-charges-note'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            key: const ValueKey('workout-start'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: plan.steps.isEmpty ? null : controller.start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.workoutStart),
          ),
        ),
      ],
    );
  }
}

class _RunningView extends ConsumerWidget {
  const _RunningView({
    required this.state,
    required this.onOpen,
    required this.onSkip,
    required this.onInterrupt,
  });

  final WorkoutState state;
  final Future<void> Function(WorkoutStep step) onOpen;
  final VoidCallback onSkip;
  final VoidCallback onInterrupt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = state.plan!;
    final current = state.currentStep;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Text(
                l10n.workoutProgress(state.doneCount, state.total),
                key: const ValueKey('workout-progress'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: state.progress, minHeight: 8),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.workoutRemaining(state.total - state.doneCount),
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (current != null)
                Card(
                  key: const ValueKey('workout-current'),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${roleLabel(l10n, current.role)} · ${l10n.workoutStepOf(state.currentIndex + 1, state.total)}',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.exerciseName(current.exercise),
                          style:
                              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (current.difficult) ...[
                          const SizedBox(height: 4),
                          Text(l10n.workoutDifficultReason, style: theme.textTheme.bodySmall),
                        ],
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          key: const ValueKey('workout-open-step'),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          onPressed: () => onOpen(current),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.workoutOpenStep),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const ValueKey('workout-skip'),
                            onPressed: onSkip,
                            child: Text(l10n.workoutSkip),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final (index, step) in plan.steps.indexed) ...[
                      if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _StepTile(
                          step: step, status: state.statuses[index], result: state.results[index]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: TextButton.icon(
            key: const ValueKey('workout-interrupt'),
            onPressed: onInterrupt,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.workoutInterrupt),
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = state.plan!;
    final record = state.lastRecord!;
    final complete = record.outcome == WorkoutOutcome.completed;
    final attempts = record.correct + record.errors;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(
          mood: complete ? MascotMood.success : MascotMood.greeting,
          message: complete ? l10n.workoutCoachDone : l10n.workoutCoachPartial,
        ),
        const SizedBox(height: 16),
        Text(
          complete ? l10n.workoutCompleted : l10n.workoutPartial,
          key: const ValueKey('workout-outcome'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.workoutDoneLine(record.completedIds.length, plan.steps.length),
          style: theme.textTheme.bodyMedium,
        ),
        if (attempts > 0)
          Text(
            l10n.workoutAccuracyLine(((record.correct / attempts) * 100).round()),
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              for (final (index, step) in plan.steps.indexed) ...[
                if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                _StepTile(step: step, status: state.statuses[index], result: state.results[index]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('workout-close'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () async {
            await ref.read(workoutControllerProvider.notifier).dismissSummary();
            if (context.mounted) {
              Navigator.of(context).maybePop();
            }
          },
          child: Text(l10n.sessionContinue),
        ),
      ],
    );
  }
}

/// Riga di un esercizio: ruolo, nome, nota di partenza, durata o esito.
class _StepTile extends ConsumerWidget {
  const _StepTile({required this.step, required this.status, this.result});

  final WorkoutStep step;
  final WorkoutStepStatus? status;
  final SessionRecord? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final decor = context.decor;
    final l10n = context.l10n;
    final notation = ref.watch(notationProvider);
    final (icon, color) = switch (status) {
      WorkoutStepStatus.completed => (Icons.check_circle, decor.success),
      WorkoutStepStatus.skipped => (Icons.remove_circle_outline, colors.outline),
      WorkoutStepStatus.current => (Icons.play_circle, colors.primary),
      _ => (
          switch (step.role) {
            WorkoutRole.warmUp => Icons.wb_sunny_outlined,
            WorkoutRole.main => Icons.music_note_outlined,
            WorkoutRole.review => Icons.replay,
          },
          colors.onSurfaceVariant
        ),
    };
    final accuracy = result?.accuracyPercent;
    final start = step.startMidi;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(l10n.exerciseName(step.exercise), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(children: [
          TextSpan(text: roleLabel(l10n, step.role)),
          if (step.difficult) TextSpan(text: ' · ${l10n.workoutDifficultTag}'),
          if (start != null) ...[
            const TextSpan(text: ' · '),
            noteSpan(spelledMidi(start), notation,
                style: theme.textTheme.bodySmall ?? const TextStyle()),
          ],
        ]),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        status == WorkoutStepStatus.completed && accuracy != null
            ? '$accuracy%'
            : status == WorkoutStepStatus.skipped
                ? l10n.workoutSkipped
                : approxDuration(l10n, step.estimatedSeconds),
        style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
