// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Intonia';

  @override
  String get navHome => 'Home';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navRange => 'Range';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String spanSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitones',
      one: '1 semitone',
    );
    return '$_temp0';
  }

  @override
  String spanOctaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count octaves',
      one: '1 octave',
    );
    return '$_temp0';
  }

  @override
  String spanOctavesAndSemitones(String octaves, String semitones) {
    return '$octaves + $semitones';
  }

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHint =>
      'The note names (C D E or DO RE MI) are chosen separately, under Note names.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeNeon => 'Neon';

  @override
  String get notationInternational => 'C D E';

  @override
  String get notationItalian => 'DO RE MI';
}
