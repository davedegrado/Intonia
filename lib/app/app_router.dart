import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/music/exercise.dart';
import '../features/access/presentation/pro_screen.dart';
import '../features/library/presentation/custom_exercise_editor_screen.dart';
import '../features/library/presentation/exercises_screen.dart';
import '../features/library/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/range/presentation/range_screen.dart';
import '../features/range/presentation/range_test_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/trainer/presentation/screens/trainer_screen.dart';
import 'main_shell.dart';

/// Router dell'app: uno per ProviderScope, così ogni avvio (e ogni test)
/// parte dalla Home.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Quattro sezioni principali con barra di navigazione persistente (ognuna
/// mantiene il proprio stato). Allenamento, test, editor, impostazioni e Pro
/// sono a schermo intero, sopra la barra.
GoRouter createAppRouter() => GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/exercises', builder: (context, state) => const ExercisesScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/range', builder: (context, state) => const RangeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ]),
          ],
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
          path: '/range-test',
          builder: (context, state) => const RangeTestScreen(),
        ),
        GoRoute(
          path: '/pro',
          builder: (context, state) => const ProScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
