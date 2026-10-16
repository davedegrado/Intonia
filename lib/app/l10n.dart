import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Testi dell'interfaccia nella lingua attiva.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension SpanL10n on AppLocalizations {
  /// Ampiezza in semitoni come "2 ottave + 7 semitoni" / "2 octaves + 7 semitones".
  String span(int semitones) {
    final octaves = semitones ~/ 12;
    final rest = semitones % 12;
    if (octaves == 0) {
      return spanSemitones(rest);
    }
    if (rest == 0) {
      return spanOctaves(octaves);
    }
    return spanOctavesAndSemitones(spanOctaves(octaves), spanSemitones(rest));
  }

  /// Come [span], ma "2 ottave" e "7 semitoni" non si spezzano mai a metà:
  /// se serve si va a capo solo attorno al "+".
  String spanUnbroken(int semitones) {
    final octaves = semitones ~/ 12;
    final rest = semitones % 12;
    if (octaves == 0) {
      return spanSemitones(rest).noBreak;
    }
    if (rest == 0) {
      return spanOctaves(octaves).noBreak;
    }
    return spanOctavesAndSemitones(spanOctaves(octaves).noBreak, spanSemitones(rest).noBreak);
  }
}

extension NoBreakText on String {
  /// Stesso testo con spazi non divisibili: un'etichetta breve come
  /// "4 esercizi" o "3 ottave" va a capo tutta intera, mai a metà.
  String get noBreak => replaceAll(' ', '\u00A0');
}
