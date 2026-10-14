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
///   cancellano la nota in corso.
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

  /// Ultima nota riconosciuta, mantenuta durante le brevi cadute di segnale;
  /// null in silenzio.
  PitchDetectionResult? get current => _current;

  void reset() {
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

    _lastVoiced = now;
    _recentMidi.add(_midiOf(detected.frequency));
    while (_recentMidi.length > config.smoothingFrames) {
      _recentMidi.removeAt(0);
    }
    final midi = _median(_recentMidi);
    final note = _recognize(midi, now);
    final frequency = 440 * math.pow(2, (midi - 69) / 12).toDouble();

    return _current = PitchDetectionResult(
      frequency: frequency,
      note: note,
      cents: (midi - note.midiNumber) * 100,
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

  static double _midiOf(double frequency) => 69 + 12 * math.log(frequency / 440) / math.ln2;

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
