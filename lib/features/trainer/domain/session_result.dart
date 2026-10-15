import '../../../l10n/app_localizations.dart';
import '../../../core/session/session_record.dart';
import '../../mascot/domain/mascot_mood.dart';

/// Fascia del risultato di fine esercizio, dalla precisione in percentuale
/// (la stessa mostrata nel profilo: [SessionRecord.accuracyPercent]).
enum ResultTier {
  perfect(MascotMood.success),
  great(MascotMood.success),
  good(MascotMood.greeting),
  retry(MascotMood.retry);

  const ResultTier(this.mood);

  final MascotMood mood;

  /// Titolo nella lingua di [l10n].
  String title(AppLocalizations l10n) => switch (this) {
        perfect => l10n.sessionPerfectTitle,
        great => l10n.sessionGreatTitle,
        good => l10n.sessionGoodTitle,
        retry => l10n.sessionRetryTitle,
      };

  /// Commento della mascotte nella lingua di [l10n].
  String message(AppLocalizations l10n) => switch (this) {
        perfect => l10n.sessionPerfectMessage,
        great => l10n.sessionGreatMessage,
        good => l10n.sessionGoodMessage,
        retry => l10n.sessionRetryMessage,
      };

  /// Festeggia con i coriandoli.
  bool get celebrates => this == perfect || this == great;

  static ResultTier of(int percent) {
    if (percent >= 100) {
      return perfect;
    }
    if (percent >= 80) {
      return great;
    }
    if (percent >= 50) {
      return good;
    }
    return retry;
  }
}
