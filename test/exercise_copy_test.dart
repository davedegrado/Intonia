import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/app/l10n.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/access/domain/entitlement.dart';
import 'package:vocal_scale_trainer/features/library/presentation/custom_exercise_editor_screen.dart';
import 'package:vocal_scale_trainer/features/library/presentation/exercises_screen.dart';

import 'support/access_fakes.dart';

void main() {
  final source = const ExerciseLibrary().byId('major')!;

  test('the copy is an independent new sequence with the full original definition', () {
    final copy = copyForEditing(source, 'Scala maggiore');
    expect(copy.id, isEmpty, reason: 'id vuoto: l\'editor la salva come nuova');
    expect(copy.isCustom, isTrue);
    expect(copy.category, ExerciseCategory.custom);
    expect(copy.steps, source.steps, reason: 'definizione originale, non la variante');
    expect(copy.rootMidi, 60);

    copy.steps.add(99);
    expect(source.steps.contains(99), isFalse,
        reason: 'modificare la copia non tocca l\'originale');
    expect(const ExerciseLibrary().byId('major')!.steps.contains(99), isFalse);
  });

  testWidgets('the editor opens the copy as a new sequence with its notes', (tester) async {
    final copy = copyForEditing(source, 'Scala maggiore');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
        entitlementSourceProvider
            .overrideWithValue(const FixedEntitlementSource(Entitlement(plan: Plan.pro))),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: CustomExerciseEditorScreen(initial: copy),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nuova sequenza'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Scala maggiore'), findsOneWidget);
  });
}
