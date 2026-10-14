import '../../../core/session/session_record.dart';
import '../../mascot/domain/mascot_mood.dart';

/// Fascia del risultato di fine esercizio, dalla precisione in percentuale
/// (la stessa mostrata nel profilo: [SessionRecord.accuracyPercent]).
enum ResultTier {
  perfect('Perfetto!', 'Nessun errore: sei intonatissimo!', MascotMood.success),
  great('Ottimo lavoro!', "Quasi perfetto: l'orecchio sta migliorando.", MascotMood.success),
  good('Bene!', 'Ci sei quasi: ripeti per fissare le note.', MascotMood.greeting),
  retry('Non mollare!', 'Riascolta le note e riprova: migliori a ogni giro.', MascotMood.retry);

  const ResultTier(this.title, this.message, this.mood);

  final String title;
  final String message;
  final MascotMood mood;

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
