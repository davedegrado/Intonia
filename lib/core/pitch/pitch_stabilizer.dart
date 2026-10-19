import 'dart:math' as math;

import '../music/note.dart';
import 'pitch_detection_result.dart';
import 'pitch_recognition_config.dart';

/// Trasforma i frame grezzi del rilevatore in una nota riconosciuta stabile.
///
/// - Mediana dell'altezza sugli ultimi frame: scarta i frame anomali.
/// - Cambio al semitono vicino solo dopo [PitchRecognitionConfig.noteSwitchMs]
///   oltre il confine: il vibrato non fa cambiare nota, una nota diversa sì.
///   I salti più ampi di [PitchRecognitionConfig.immediateSwitchCents] sono
///   immediati.
/// - Cadute brevi del segnale ([PitchRecognitionConfig.dropoutGraceMs]) non
///   cancellano la nota in corso; i frame incerti del rilevatore (ottava
///   ambigua) contano come cadute brevi.
/// - Un salto di circa un'ottava è accettato solo dopo
///   [PitchRecognitionConfig.octaveConfirmFrames] frame coerenti: è il tipico
///   errore del rilevatore, mentre un cambio d'ottava reale dura.
///
/// Non modifica la frequenza rilevata (salvo la mediana) né valuta
/// l'intonazione: lo scostamento in cent è sempre riferito alla nota
/// riconosciuta.
class PitchStabilizer {
  PitchStabilizer({this.config = PitchRecognitionConfig.standard});

  final PitchRecognitionConfig config;

  final List<double> _recentMidi = [];
  MusicalNote? _heldNote;
  DateTime? _otherSideSince;
  DateTime? _lastVoiced;
  PitchDetectionResult? _current;

  /// Frame consecutivi a circa un'ottava dalla nota riconosciuta.
  int _octaveFrames = 0;

  /// Ultima nota riconosciuta, mantenuta durante le brevi cadute di segnale;
  /// null in silenzio.
  PitchDetectionResult? get current => _current;

  void reset() {
    _octaveFrames = 0;
    _recentMidi.clear();
    _heldNote = null;
    _otherSideSince = null;
    _lastVoiced = null;
    _current = null;
  }

  /// Elabora un frame. Ritorna il risultato stabilizzato (isStable true) per
  /// i frame con voce, il frame grezzo altrimenti.
  PitchDetectionResult process(PitchDetectionResult detected, DateTime now) {
    if (!detected.isStable || detected.frequency <= 0) {
      final last = _lastVoiced;
      if (last == null || now.difference(last).inMilliseconds > config.dropoutGraceMs) {
        // Silenzio vero: il prossimo attacco riparte da zero.
        _recentMidi.clear();
        _heldNote = null;
        _otherSideSince = null;
        _current = null;
      }
      return detected;
    }

    final last = _lastVoiced;
    if (last != null && now.difference(last).inMilliseconds > config.dropoutGraceMs) {
      // Nessun frame da tempo (es. analisi sospesa durante la nota guida):
      // i dati precedenti non descrivono più la voce attuale.
      _recentMidi.clear();
      _heldNote = null;
      _otherSideSince = null;
      _octaveFrames = 0;
    }
    _lastVoiced = now;
    final midi = _midiOf(detected.frequency);
    final held = _heldNote;
    final current = _current;
    if (held != null && current != null && _isOctaveJump(midi - held.midiNumber)) {
      // Possibile errore d'ottava: la nota resta quella di prima finché il
      // salto non è confermato da frame consecutivi.
      if (++_octaveFrames < config.octaveConfirmFrames) {
        return current;
      }
      // Confermato: cambio d'ottava reale, la mediana riparte dalla nuova.
      _recentMidi.clear();
      _heldNote = null;
      _otherSideSince = null;
    }
    _octaveFrames = 0;
    _recentMidi.add(midi);
    while (_recentMidi.length > config.smoothingFrames) {
      _recentMidi.removeAt(0);
    }
    final smoothed = _median(_recentMidi);
    final note = _recognize(smoothed, now);
    final frequency = 440 * math.pow(2, (smoothed - 69) / 12).toDouble();

    return _current = PitchDetectionResult(
      frequency: frequency,
      note: note,
      cents: (smoothed - note.midiNumber) * 100,
      confidence: detected.confidence,
      isStable: true,
    );
  }

  MusicalNote _recognize(double midi, DateTime now) {
    final nearest = MusicalNote.fromMidi(midi.round());
    final held = _heldNote;
    if (held == null) {
      return _heldNote = nearest;
    }
    if (nearest == held) {
      _otherSideSince = null;
      return held;
    }
    // La voce è oltre il confine con un'altra nota.
    final distanceCents = (midi - held.midiNumber).abs() * 100;
    final since = _otherSideSince ??= now;
    if (distanceCents > config.immediateSwitchCents ||
        now.difference(since).inMilliseconds >= config.noteSwitchMs) {
      _otherSideSince = null;
      return _heldNote = nearest;
    }
    return held;
  }

  /// Distanza (semitoni) a meno di 70 cent da una o due ottave esatte.
  static bool _isOctaveJump(double semitones) {
    final distance = semitones.abs();
    return (distance - 12).abs() <= 0.7 || (distance - 24).abs() <= 0.7;
  }

  static double _midiOf(double frequency) => 69 + 12 * math.log(frequency / 440) / math.ln2;

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
