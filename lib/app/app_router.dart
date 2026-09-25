import 'package:go_router/go_router.dart';

import '../core/music/exercise.dart';
import '../features/library/presentation/custom_exercise_editor_screen.dart';
import '../features/library/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/range/presentation/range_test_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/trainer/presentation/screens/trainer_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/trainer',
      builder: (context, state) => TrainerScreen(
        exercise: state.extra! as ExerciseDefinition,
      ),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) => CustomExerciseEditorScreen(
        initial: state.extra as ExerciseDefinition?,
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/range-test',
      builder: (context, state) => const RangeTestScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
