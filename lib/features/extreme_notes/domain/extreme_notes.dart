import 'dart:math' as math;

import '../../../core/pitch/pitch_detection_result.dart';
import '../../../services/pitch/microphone_pitch_service.dart';

/// Parametri del riconoscimento delle note estreme, motivati dal rilevatore
/// (un frame ogni ~23 ms con frequenza, confidenza e flag "stabile"). Le
/// durate si contano in frame ([MicrophonePitchService.hopMs]): il servizio
/// emette un risultato per ogni frame, silenzio compreso.
class ExtremeNotesConfig {
  const ExtremeNotesConfig({
    this.medianFrames = 5,
    this.minPersistMs = 200,
    this.maxGapMs = 100,
    this.certainMs = 500,
    this.certainSegments = 2,
    this.spikeSemitones = 6,
  });

  static const standard = ExtremeNotesConfig();

  /// Mediana sugli ultimi frame con voce: con 5 frame vengono scartati fino a
  /// due frame anomali consecutivi (~46 ms), come gli errori d'ottava di YIN.
  final int medianFrames;

  /// Una nota conta solo se la mediana resta su di essa per questo tempo
  /// (≈ 9 frame): esclude picchi, scivolate e note di passaggio, ma non le
  /// note brevi cantate davvero in un brano (una croma a 120 bpm dura 250 ms).
  final int minPersistMs;

  /// Silenzio oltre il quale inizia una nuova emissione (respiro, pausa).
  final int maxGapMs;

  /// Una nota estrema è certa se è stata tenuta in tutto almeno [certainMs]
  /// o ritrovata in almeno [certainSegments] emissioni distinte; altrimenti
  /// è mostrata come incerta (non scartata).
  final int certainMs;
  final int certainSegments;

  /// Un frame a oltre [spikeSemitones] dalla mediana è un picco anomalo
  /// (contato per la qualità del rilevamento).
  final int spikeSemitones;
}

/// Qualità del rilevamento in una sessione.
enum DetectionQuality { good, fair, poor }

/// Note più alta e più bassa rilevate in una sessione di canto libero.
class ExtremeNotesResult {
  const ExtremeNotesResult({
    required this.lowest,
    required this.highest,
    required this.lowestCertain,
    required this.highestCertain,
    required this.voicedMs,
    required this.confirmedNotes,
    required this.spikes,
    required this.quality,
  });

  static const empty = ExtremeNotesResult(
    lowest: null,
    highest: null,
    lowestCertain: false,
    highestCertain: false,
    voicedMs: 0,
    confirmedNotes: 0,
    spikes: 0,
    quality: DetectionQuality.poor,
  );

  /// MIDI della nota più bassa e più alta riconosciute; null se nessuna.
  final int? lowest;
  final int? highest;
  final bool lowestCertain;
  final bool highestCertain;

  /// Tempo con voce rilevata.
  final int voicedMs;

  /// Note diverse riconosciute.
  final int confirmedNotes;

  /// Frame anomali scartati.
  final int spikes;
  final DetectionQuality quality;

  bool get isEmpty => lowest == null;

  /// Una sola nota riconosciuta: non c'è un intervallo.
  bool get single => lowest != null && lowest == highest;

  /// Intervallo in semitoni fra le due note (null se non ci sono due note).
  int? get spanSemitones =>
      lowest != null && highest != null && highest! > lowest! ? highest! - lowest! : null;
}

/// Raccoglie i frame del rilevatore durante il canto libero e tiene le note
/// estreme riconosciute in modo persistente. Non filtra in base alla
/// vicinanza con le note precedenti: un salto melodico ampio ma tenuto è
/// accettato come qualsiasi altra nota.
class ExtremeNotesTracker {
  ExtremeNotesTracker({this.config = ExtremeNotesConfig.standard});

  final ExtremeNotesConfig config;

  final _window = <double>[];

  /// Frame senza voce dall'ultimo con voce (null = nessuna voce ancora).
  int? _silentFrames;
  int? _candidate;
  double _candidateMs = 0;
  bool _candidateCounted = false;
  final _confirmedInSegment = <int>{};
  final _noteMs = <int, double>{};
  final _segments = <int, int>{};
  double _voicedMs = 0;
  int _spikes = 0;

  static const _frameMs = MicrophonePitchService.hopMs;

  /// Nota più bassa e più alta riconosciute finora.
  int? get lowest => _noteMs.isEmpty ? null : _noteMs.keys.reduce(math.min);
  int? get highest => _noteMs.isEmpty ? null : _noteMs.keys.reduce(math.max);

  /// Elabora un frame del rilevatore (con voce o no, nell'ordine di arrivo).
  void add(PitchDetectionResult detection) {
    if (!detection.isStable || detection.frequency <= 0) {
      if (_silentFrames != null) {
        _silentFrames = _silentFrames! + 1;
      }
      return;
    }
    final silent = _silentFrames;
    if (silent == null || silent * _frameMs > config.maxGapMs) {
      // Nuova emissione: la mediana e la nota candidata ripartono da zero.
      _window.clear();
      _candidate = null;
      _candidateMs = 0;
      _candidateCounted = false;
      _confirmedInSegment.clear();
    }
    _silentFrames = 0;
    _voicedMs += _frameMs;

    final midi = 69 + 12 * math.log(detection.frequency / 440) / math.ln2;
    _window.add(midi);
    while (_window.length > config.medianFrames) {
      _window.removeAt(0);
    }
    if (_window.length < 3) {
      return;
    }
    final sorted = [..._window]..sort();
    final median = sorted[sorted.length ~/ 2];
    if ((midi - median).abs() >= config.spikeSemitones) {
      _spikes++;
    }
    final note = median.round();
    if (note == _candidate) {
      _candidateMs += _frameMs;
    } else {
      _candidate = note;
      _candidateMs = _frameMs;
      _candidateCounted = false;
    }
    if (_candidateMs < config.minPersistMs) {
      return;
    }
    // Nota confermata: alla conferma conta tutto il tempo già tenuto.
    _noteMs[note] = (_noteMs[note] ?? 0) + (_candidateCounted ? _frameMs : _candidateMs);
    _candidateCounted = true;
    if (_confirmedInSegment.add(note)) {
      _segments[note] = (_segments[note] ?? 0) + 1;
    }
  }

  ExtremeNotesResult result() {
    if (_noteMs.isEmpty) {
      return ExtremeNotesResult(
        lowest: null,
        highest: null,
        lowestCertain: false,
        highestCertain: false,
        voicedMs: _voicedMs.round(),
        confirmedNotes: 0,
        spikes: _spikes,
        quality: DetectionQuality.poor,
      );
    }
    bool certain(int note) =>
        (_noteMs[note] ?? 0) >= config.certainMs ||
        (_segments[note] ?? 0) >= config.certainSegments;
    final low = lowest!;
    final high = highest!;
    final voicedFrames = math.max(1, (_voicedMs / _frameMs).round());
    final spikeRatio = _spikes / voicedFrames;
    final quality = _voicedMs >= 10000 && spikeRatio < 0.05
        ? DetectionQuality.good
        : _voicedMs >= 3000 && spikeRatio < 0.15
            ? DetectionQuality.fair
            : DetectionQuality.poor;
    return ExtremeNotesResult(
      lowest: low,
      highest: high,
      lowestCertain: certain(low),
      highestCertain: certain(high),
      voicedMs: _voicedMs.round(),
      confirmedNotes: _noteMs.length,
      spikes: _spikes,
      quality: quality,
    );
  }
}
