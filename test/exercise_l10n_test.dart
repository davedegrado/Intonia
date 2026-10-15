import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/l10n/app_localizations.dart';
import 'package:vocal_scale_trainer/l10n/exercise_l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final it = lookupAppLocalizations(const Locale('it'));
  const library = ExerciseLibrary();

  const italianWords = ['triade', 'scala', 'maggiore', 'minore', 'armonizzata', 'salti'];

  void expectEnglish(String label) {
    expect(label.trim(), isNotEmpty);
    for (final word in italianWords) {
      expect(label.toLowerCase().contains(word), isFalse, reason: '"$label" contiene "$word"');
    }
  }

  test('every built-in exercise has an English and an Italian name', () {
    for (final exercise in library.builtIn) {
      // Fallback vuoto: un nome non vuoto prova che l'id è tradotto.
      final english = en.exerciseNameById(exercise.id, '');
      final italian = it.exerciseNameById(exercise.id, '');
      expectEnglish(english);
      expect(italian, isNotEmpty);
      expect(en.exerciseName(exercise), english);
      // L'italiano coincide con i dati interni dell'esercizio.
      expect(italian, exercise.name);
    }
    expect(en.exerciseNameById('triad_major', ''), 'Major triad');
    expect(en.exerciseNameById('harmonic_minor', ''), 'Harmonic minor scale');
  });

  test('custom and unknown exercises keep their own name', () {
    const custom = ExerciseDefinition(
      id: 'major',
      name: 'La mia scala',
      category: ExerciseCategory.custom,
      steps: [0, 2],
      isCustom: true,
    );
    expect(en.exerciseName(custom), 'La mia scala');
    expect(en.exerciseNameById('custom_123', 'Riscaldamento'), 'Riscaldamento');
  });

  test('every category has a translated label and description', () {
    for (final category in ExerciseCategory.values) {
      expectEnglish(en.categoryLabel(category));
      expectEnglish(en.categoryDescription(category));
      expect(it.categoryLabel(category), category.label);
      expect(it.categoryDescription(category), category.description);
      expect(en.categoryLabel(category), isNot(it.categoryLabel(category)));
      expect(en.categoryDescription(category), isNot(it.categoryDescription(category)));
    }
  });

  test('every focus value is translated, from Italian or English', () {
    final focuses = {
      for (final exercise in library.builtIn)
        if (exercise.focus != null) exercise.focus!,
      for (final focus in ExerciseFocus.values) focus.storedValue,
    };
    for (final focus in focuses) {
      expect(ExerciseFocus.parse(focus), isNotNull, reason: focus);
      expectEnglish(en.focusLabel(focus));
      expect(it.focusLabel(focus), focus);
    }
    expect(en.focusLabel('Orecchio'), 'Ear training');
    expect(it.focusLabel('Accuracy'), 'Precisione');
    expect(en.focusLabel('Altro'), 'Altro');
  });
}
