import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../achievements/presentation/achievements_card.dart';
import '../../../app/date_format.dart';
import '../../../app/l10n.dart';
import '../../../app/neon_scene.dart';
import '../../access/application/access_providers.dart';
import '../../access/domain/entitlement.dart';
import '../../../app/note_text.dart';
import '../../../core/music/exercise.dart';
import '../../../core/music/note.dart';
import '../../library/presentation/exercises_screen.dart' show categoryIcon;
import '../../../core/music/note_spelling.dart';
import '../../../core/session/range_record.dart';
import '../../../core/session/session_record.dart';
import '../../../l10n/exercise_l10n.dart';
import '../../range/application/range_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/history_providers.dart';
import '../../guide/guide.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final notation = ref.watch(notationProvider);
    final records = ref.watch(sessionHistoryProvider).value ?? const <SessionRecord>[];
    final ranges = ref.watch(rangeHistoryProvider).value ?? const <RangeRecord>[];

    if (records.isEmpty && ranges.isEmpty) {
      return SectionScaffold(
        title: l10n.profileTitle,
        actions: _actions(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.profileEmptyTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.profileEmptyBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                const GuideAnchor(
                    target: GuideTarget.profileAchievements, child: AchievementsCard()),
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

    final decor = context.decor;
    return SectionScaffold(
      title: l10n.profileTitle,
      actions: _actions(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(streak: streak),
            const SizedBox(height: 12),
            const GuideAnchor(target: GuideTarget.profileAchievements, child: AchievementsCard()),
            const SizedBox(height: 12),
            GuideAnchor(
              target: GuideTarget.profileStats,
              child: Column(children: [
                _StatRow(children: [
                  _StatCard(
                      icon: Icons.event_repeat_rounded,
                      accent: decor.accent(0),
                      label: l10n.profileStatSessions,
                      value: '${records.length}'),
                  _StatCard(
                      icon: Icons.timer_outlined,
                      accent: decor.accent(1),
                      label: l10n.profileStatMinutes,
                      value: '$totalMinutes'),
                ]),
                const SizedBox(height: 10),
                _StatRow(children: [
                  _StatCard(
                      icon: Icons.track_changes_rounded,
                      accent: decor.accent(3),
                      label: l10n.profileStatAccuracy,
                      value: '${(avgAccuracy * 100).toStringAsFixed(0)}%'),
                  _StatCard(
                    icon: Icons.height_rounded,
                    accent: decor.accent(2),
                    label: l10n.profileStatRange,
                    value: '—',
                    valueWidget: lowMidi != null && highMidi != null
                        ? NoteRangeText(
                            low: spelledMidi(lowMidi),
                            high: spelledMidi(highMidi),
                            notation: notation,
                            style:
                                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                ]),
              ]),
            ),
            if (rated.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(l10n.profileBestWorstNotes),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(children: [
                    for (final item in rated.length <= 6
                        ? rated
                        : [...rated.take(3), ...rated.skip(rated.length - 3)])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                NoteSpeller.keyLabel(item.pitch, notation),
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              child: _AccuracyBar(value: item.accuracy),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 44,
                              child: Text('${(item.accuracy * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ),
              ),
            ],
            if (ranges.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(l10n.profileRangeTests),
              Card(
                child: Column(children: [
                  for (var i = ranges.length - 1; i >= 0 && i >= ranges.length - 5; i--) ...[
                    if (i != ranges.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading:
                          AccentIcon(icon: Icons.height_rounded, color: decor.accent(2), size: 40),
                      title: NoteRangeText(
                        low: spelledMidi(ranges[i].minMidi),
                        high: spelledMidi(ranges[i].maxMidi),
                        notation: notation,
                        suffix: '  (${l10n.spanUnbroken(ranges[i].spanSemitones)})',
                      ),
                      subtitle: Text(formatShortDate(ranges[i].timestamp) +
                          (i > 0
                              ? '  ·  ${_deltaLabel(l10n, ranges[i].spanSemitones - ranges[i - 1].spanSemitones)}'
                              : '')),
                      trailing: IconButton(
                        tooltip: l10n.profileDeleteRangeTooltip,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDeleteRange(context, ref, ranges[i]),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
            const SizedBox(height: 20),
            GuideAnchor(
              target: GuideTarget.profileHistory,
              child:
                  _SectionTitle(fullHistory ? l10n.profileAllSessions : l10n.profileRecentSessions),
            ),
            if (recent.isNotEmpty)
              Card(
                child: Column(children: [
                  for (final (index, record) in recent.indexed) ...[
                    if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: AccentIcon(
                        icon: _sessionIcon(record),
                        color: decor.accent(index),
                        size: 40,
                      ),
                      title: Text(l10n.exerciseNameById(record.exerciseId, record.exerciseName)),
                      subtitle: Text([
                        if (_sessionDetails(l10n, notation, record) case final details?) details,
                        formatShortDate(record.timestamp),
                      ].join('\n')),
                      isThreeLine: _sessionDetails(l10n, notation, record) != null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${record.accuracyPercent}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: record.accuracy >= 0.8
                                  ? decor.success
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
                              tooltip: l10n.profileDeleteSessionTooltip,
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _confirmDeleteSession(context, ref, record),
                            ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            if (!fullHistory && records.length > freeRecentSessions)
              TextButton.icon(
                key: const ValueKey('full-history-pro'),
                onPressed: () => context.push('/pro'),
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text(l10n.profileFullHistoryPro(records.length)),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) => [
        GuideAnchor(
          target: GuideTarget.profileSettings,
          child: IconButton(
            key: const ValueKey('profile-settings'),
            tooltip: context.l10n.profileSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ),
        const SizedBox(width: 4),
      ];

  /// Icona della categoria reale dell'esercizio (sequenze personali a parte).
  static IconData _sessionIcon(SessionRecord record) {
    if (record.isCustomExercise) {
      return Icons.edit_note_rounded;
    }
    final exercise = const ExerciseLibrary().byId(record.exerciseId);
    return exercise == null ? Icons.music_note_rounded : categoryIcon(exercise.category);
  }

  /// "C · Ottava 3 · Completo" dai dati salvati nella sessione; null per le
  /// sessioni di versioni precedenti che non li contengono.
  static String? _sessionDetails(
    AppLocalizations l10n,
    NoteNotation notation,
    SessionRecord record,
  ) {
    final key = record.keySemitone;
    final octave = record.octave;
    if (key == null || octave == null) {
      return null;
    }
    final direction = switch (record.direction) {
      'forward' => l10n.trainerDirectionForward,
      'reverse' => l10n.trainerDirectionReverse,
      'complete' => l10n.trainerDirectionComplete,
      _ => null,
    };
    return [
      l10n.profileSessionKeyOctave(
        NoteSpeller.keyLabel(PitchClass.fromSemitone(key), notation),
        octave,
      ),
      if (direction != null) direction,
      if (record.direction == 'complete' && record.repeatTop == true)
        l10n.profileSessionTopRepeated,
    ].join(' · ');
  }

  /// Sessioni mostrate agli utenti Free.
  static const freeRecentSessions = 8;

  String _deltaLabel(AppLocalizations l10n, int delta) {
    if (delta > 0) {
      return l10n.profileRangeDeltaUp(delta);
    }
    if (delta == 0) {
      return l10n.profileRangeUnchanged;
    }
    return l10n.profileRangeDeltaDown(-delta);
  }

  Future<void> _confirmDeleteRange(
    BuildContext context,
    WidgetRef ref,
    RangeRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.profileDeleteRangeTitle),
        content: Text(context.l10n.profileDeleteRangeBody(formatShortDate(record.timestamp))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.commonDelete)),
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
        title: Text(context.l10n.profileDeleteSessionTitle),
        content: Text(context.l10n.profileDeleteSessionBody(
          context.l10n.exerciseNameById(record.exerciseId, record.exerciseName),
          formatShortDate(record.timestamp),
        )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionHistoryProvider.notifier).remove(record);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final IconData icon;
  final Color accent;
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
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    // Su una riga, rimpicciolita se serve: mai troncata.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label,
                          maxLines: 1,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              valueWidget ??
                  Text(value,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titolo di sezione del profilo.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

/// Serie giornaliera in evidenza.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decor = context.decor;
    return Container(
      key: const ValueKey('streak-card'),
      decoration: BoxDecoration(
        gradient: decor.featureGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: decor.ambient ? decor.featureBorder.withValues(alpha: 0.6) : decor.featureBorder,
        ),
        boxShadow: decor.ambient
            ? [
                BoxShadow(
                  color: decor.glow.withValues(alpha: 0.3),
                  blurRadius: 22,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: decor.streak.withValues(alpha: 0.16),
              boxShadow: decor.ambient && streak > 0
                  ? [BoxShadow(color: decor.streak.withValues(alpha: 0.45), blurRadius: 18)]
                  : null,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 38,
              color: streak > 0 ? decor.streak : decor.onFeature.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.profileStreakDays(streak),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: decor.onFeature,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 0 ? context.l10n.profileStreakStart : context.l10n.profileStreakKeep,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: decor.onFeature.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
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
            gradient: context.decor.spectrum,
          ),
        ),
      ),
    );
  }
}
