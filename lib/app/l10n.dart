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
}
