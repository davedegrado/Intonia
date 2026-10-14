import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/music/exercise.dart';
import '../../access/application/access_providers.dart';
import '../../access/domain/entitlement.dart';
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

  /// Crea o modifica una sequenza. Riservato a Intonia Pro: per gli utenti
  /// Free non salva nulla e ritorna false (le sequenze già salvate restano).
  Future<bool> upsert(ExerciseDefinition exercise) async {
    final entitlement = await ref.read(entitlementProvider.notifier).resolve();
    if (!entitlement.allows(ProFeature.customSequences)) {
      return false;
    }
    final current = List<ExerciseDefinition>.from(state.value ?? const []);
    final index = current.indexWhere((item) => item.id == exercise.id);
    if (index >= 0) {
      current[index] = exercise;
    } else {
      current.add(exercise);
    }
    state = AsyncData(current);
    await ref.read(customExerciseRepositoryProvider).save(current);
    return true;
  }

  Future<void> remove(String id) async {
    final current = List<ExerciseDefinition>.from(state.value ?? const [])
      ..removeWhere((item) => item.id == id);
    state = AsyncData(current);
    await ref.read(customExerciseRepositoryProvider).save(current);
  }
}
