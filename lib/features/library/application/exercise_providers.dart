import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/exercise.dart';
import '../../../services/storage/custom_exercise_repository.dart';

final exerciseLibraryProvider = Provider<ExerciseLibrary>((ref) => const ExerciseLibrary());

final customExerciseRepositoryProvider =
    Provider<CustomExerciseRepository>((ref) => CustomExerciseRepository());

final customExercisesProvider =
    AsyncNotifierProvider<CustomExercisesNotifier, List<ExerciseDefinition>>(
  CustomExercisesNotifier.new,
);

class CustomExercisesNotifier extends AsyncNotifier<List<ExerciseDefinition>> {
  @override
  Future<List<ExerciseDefinition>> build() {
    return ref.read(customExerciseRepositoryProvider).load();
  }

  Future<void> upsert(ExerciseDefinition exercise) async {
    final current = List<ExerciseDefinition>.from(state.value ?? const []);
    final index = current.indexWhere((item) => item.id == exercise.id);
    if (index >= 0) {
      current[index] = exercise;
    } else {
      current.add(exercise);
    }
    state = AsyncData(current);
    await ref.read(customExerciseRepositoryProvider).save(current);
  }

  Future<void> remove(String id) async {
    final current = List<ExerciseDefinition>.from(state.value ?? const [])
      ..removeWhere((item) => item.id == id);
    state = AsyncData(current);
    await ref.read(customExerciseRepositoryProvider).save(current);
  }
}
