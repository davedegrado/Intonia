import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/l10n.dart';
import '../domain/achievements.dart';

/// Testi e icona di un obiettivo nella lingua attiva.
extension AchievementText on AppLocalizations {
  String achievementName(AchievementId id) => switch (id) {
        AchievementId.firstExercise => achievementFirstExerciseName,
        AchievementId.days3 => achievementDays3Name,
        AchievementId.days7 => achievementDays7Name,
        AchievementId.streak7 => achievementStreak7Name,
        AchievementId.streak30 => achievementStreak30Name,
        AchievementId.exercises5 => achievementExercises5Name,
        AchievementId.exercises25 => achievementExercises25Name,
        AchievementId.firstWorkout => achievementFirstWorkoutName,
        AchievementId.workouts5 => achievementWorkouts5Name,
        AchievementId.workouts10 => achievementWorkouts10Name,
        AchievementId.perfectExercise => achievementPerfectName,
        AchievementId.accurate5 => achievementAccurate5Name,
        AchievementId.noteRun10 => achievementNoteRun10Name,
        AchievementId.categories3 => achievementCategories3Name,
        AchievementId.firstTessitura => achievementFirstTessituraName,
        AchievementId.secondTessitura => achievementSecondTessituraName,
      };

  String achievementDescription(AchievementId id) => switch (id) {
        AchievementId.firstExercise => achievementFirstExerciseDesc,
        AchievementId.days3 => achievementDays3Desc,
        AchievementId.days7 => achievementDays7Desc,
        AchievementId.streak7 => achievementStreak7Desc,
        AchievementId.streak30 => achievementStreak30Desc,
        AchievementId.exercises5 => achievementExercises5Desc,
        AchievementId.exercises25 => achievementExercises25Desc,
        AchievementId.firstWorkout => achievementFirstWorkoutDesc,
        AchievementId.workouts5 => achievementWorkouts5Desc,
        AchievementId.workouts10 => achievementWorkouts10Desc,
        AchievementId.perfectExercise => achievementPerfectDesc,
        AchievementId.accurate5 => achievementAccurate5Desc,
        AchievementId.noteRun10 => achievementNoteRun10Desc,
        AchievementId.categories3 => achievementCategories3Desc,
        AchievementId.firstTessitura => achievementFirstTessituraDesc,
        AchievementId.secondTessitura => achievementSecondTessituraDesc,
      };

  String achievementCategory(AchievementCategory category) => switch (category) {
        AchievementCategory.consistency => achievementsCategoryConsistency,
        AchievementCategory.training => achievementsCategoryTraining,
        AchievementCategory.accuracy => achievementsCategoryAccuracy,
        AchievementCategory.exploration => achievementsCategoryExploration,
      };

  String missionTitle(MissionKind kind) => switch (kind) {
        MissionKind.dailyExercises2 => missionDailyExercises2,
        MissionKind.dailyExercises3 => missionDailyExercises3,
        MissionKind.dailyWorkout => missionDailyWorkout,
        MissionKind.dailyAccuracy90 => missionDailyAccuracy90,
        MissionKind.weeklyCategories2 => missionWeeklyCategories2,
        MissionKind.weeklyDays3 => missionWeeklyDays3,
        MissionKind.weeklyWorkouts2 => missionWeeklyWorkouts2,
      };
}

IconData achievementIcon(AchievementId id) => switch (id) {
      AchievementId.firstExercise => Icons.flag_rounded,
      AchievementId.days3 => Icons.event_available_rounded,
      AchievementId.days7 => Icons.date_range_rounded,
      AchievementId.streak7 => Icons.local_fire_department_rounded,
      AchievementId.streak30 => Icons.whatshot_rounded,
      AchievementId.exercises5 => Icons.music_note_rounded,
      AchievementId.exercises25 => Icons.queue_music_rounded,
      AchievementId.firstWorkout => Icons.fitness_center_rounded,
      AchievementId.workouts5 => Icons.directions_run_rounded,
      AchievementId.workouts10 => Icons.emoji_events_rounded,
      AchievementId.perfectExercise => Icons.star_rounded,
      AchievementId.accurate5 => Icons.hearing_rounded,
      AchievementId.noteRun10 => Icons.linear_scale_rounded,
      AchievementId.categories3 => Icons.explore_rounded,
      AchievementId.firstTessitura => Icons.tune_rounded,
      AchievementId.secondTessitura => Icons.compare_arrows_rounded,
    };

IconData missionIcon(MissionKind kind) => switch (kind) {
      MissionKind.dailyExercises2 || MissionKind.dailyExercises3 => Icons.music_note_rounded,
      MissionKind.dailyWorkout || MissionKind.weeklyWorkouts2 => Icons.fitness_center_rounded,
      MissionKind.dailyAccuracy90 => Icons.hearing_rounded,
      MissionKind.weeklyCategories2 => Icons.explore_rounded,
      MissionKind.weeklyDays3 => Icons.event_available_rounded,
    };

/// Medaglia rotonda: sbloccata con i colori di Intonia (in Neon con un
/// alone), bloccata in grigio con l'avanzamento attorno.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    required this.id,
    required this.unlocked,
    this.fraction = 0,
    this.size = 56,
    super.key,
  });

  final AchievementId id;
  final bool unlocked;

  /// Avanzamento (0–1) mostrato sull'anello quando è bloccata.
  final double fraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final decor = context.decor;
    final icon = Icon(
      achievementIcon(id),
      size: size * 0.48,
      color: unlocked ? decor.onHero : colors.outline,
    );
    if (unlocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: decor.heroGradient,
          border: Border.all(color: decor.ambient ? decor.heroBorder : colors.primary, width: 2),
          boxShadow: decor.ambient
              ? [BoxShadow(color: decor.glow.withValues(alpha: 0.45), blurRadius: size * 0.3)]
              : null,
        ),
        child: icon,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 3,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary.withValues(alpha: 0.8),
            ),
          ),
          Container(
            width: size - 10,
            height: size - 10,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
            child: icon,
          ),
        ],
      ),
    );
  }
}
