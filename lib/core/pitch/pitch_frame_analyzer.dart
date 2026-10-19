import 'dart:math' as math;

import 'pitch_detection_result.dart';
import 'yin_pitch_detector.dart';

/// Analisi dei campioni del microfono, frame per frame: rilevatore principale
/// (55–1100 Hz) e, se non aggancia nulla di stabile, rilevatore della banda
/// bassa (30–250 Hz, vocal fry) su una finestra lunga decimata.
///
/// Il risultato della banda bassa è accettato solo se non è una sottoarmonica
/// della voce: se la funzione di differenza del rilevatore principale (già
/// calcolata) mostra la stessa periodicità a un periodo metà, un terzo o un
/// quarto, la voce è più acuta e la banda bassa sta agganciando un multiplo
/// del suo periodo (es. 220 Hz cantando 440 Hz in un frame rumoroso).
class PitchFrameAnalyzer {
  PitchFrameAnalyzer({this.sampleRate = 44100, this.frameSize = 2048});

  final int sampleRate;
  final int frameSize;

  /// Analisi banda bassa (vocal fry): finestra doppia, decimata di 4x.
  static const _lowDecimation = 4;
  static const _lowWindowSize = 4096; // ~93 ms a 44.1 kHz
  static const _lowFrameSize = _lowWindowSize ~/ _lowDecimation;

  /// Una sottoarmonica è riconosciuta se nel rilevatore principale il periodo
  /// più corto è profondo almeno quanto quello lungo, entro questo margine.
  static const subharmonicMargin = 0.05;

  /// Periodicità netta richiesta a un periodo corto quando quello della
  /// banda bassa è fuori dall'intervallo del rilevatore principale.
  static const strongPeriodicity = 0.25;

  /// Rapporto minimo fra l'energia delle due metà della finestra bassa
  /// perché il suono sia considerato continuo.
  static const steadyEnergyRatio = 0.5;

  final List<double> _buffer = [];

  /// Campioni già superati, per la finestra bassa del frame successivo.
  final List<double> _past = [];

  late final YinPitchDetector _detector = YinPitchDetector(sampleRate: sampleRate);

  /// Rilevatore dedicato alle frequenze molto basse (30–250 Hz).
  /// Il fry è quasi-periodico: gate di confidenza più permissivo e
  /// soglia di silenzio ridotta (il fry è spesso poco intenso).
  late final YinPitchDetector _lowDetector = YinPitchDetector(
    sampleRate: sampleRate ~/ _lowDecimation,
    minFrequency: 30,
    maxFrequency: 250,
    threshold: 0.18,
    stableConfidence: 0.60,
    rmsSilenceThreshold: 0.009,
  );

  double get silenceThreshold => _detector.rmsSilenceThreshold;

  void setSilenceThreshold(double threshold) {
    _detector.rmsSilenceThreshold = threshold;
    _lowDetector.rmsSilenceThreshold = threshold * 0.6;
  }

  void reset() {
    _buffer.clear();
    _past.clear();
  }

  /// Aggiunge campioni (−1…1) e ritorna un risultato per ogni frame
  /// completato (uno ogni mezza finestra), silenzio compreso.
  List<PitchDetectionResult> addSamples(Iterable<double> samples) {
    _buffer.addAll(samples);
    final results = <PitchDetectionResult>[];
    while (_buffer.length >= frameSize) {
      final frame = List<double>.from(_buffer.take(frameSize));
      // Finestra bassa allineata al frame: i campioni che lo precedono più il
      // frame stesso, così finisce esattamente dove finisce il frame.
      final low = _past.length + frameSize >= _lowWindowSize
          ? [..._past.skip(_past.length + frameSize - _lowWindowSize), ...frame]
          : null;
      results.add(analyzeFrame(frame, low));
      final hop = frameSize ~/ 2;
      _past.addAll(_buffer.take(hop));
      if (_past.length > _lowWindowSize) {
        _past.removeRange(0, _past.length - _lowWindowSize);
      }
      _buffer.removeRange(0, hop);
    }
    return results;
  }

  /// Analizza un frame; [lowWindow] sono gli ultimi [_lowWindowSize] campioni
  /// per la banda bassa (null se non ancora disponibili).
  PitchDetectionResult analyzeFrame(List<double> frame, List<double>? lowWindow) {
    final main = _detector.analyze(frame);
    if (main.result.isStable || main.result.uncertain || main.aboveRange || lowWindow == null) {
      return main.result;
    }
    // La finestra bassa (93 ms) contiene anche audio passato: va usata solo
    // su un suono continuo (energia simile nella metà vecchia e in quella
    // nuova, come nel fry). A cavallo di una pausa o di un attacco
    // aggancerebbe una sottoarmonica della nota appena finita.
    final half = lowWindow.length ~/ 2;
    final older = _rms(lowWindow.sublist(0, half));
    final newer = _rms(lowWindow.sublist(half));
    if (newer < _lowDetector.rmsSilenceThreshold ||
        math.min(older, newer) < math.max(older, newer) * steadyEnergyRatio) {
      return main.result;
    }
    // Il rilevatore standard non scende sotto ~55 Hz e scarta il fry
    // (quasi-periodico): se non ha agganciato nulla di stabile, riprova
    // sulla banda bassa con finestra lunga decimata.
    final low = _lowDetector.detect(_decimated(lowWindow));
    if (!low.isStable || _isSubharmonic(main, low.frequency)) {
      return main.result;
    }
    return low;
  }

  /// La frequenza della banda bassa è un sottomultiplo della voce? Lo è se
  /// nel rilevatore principale un periodo più corto (metà, un terzo… fino a
  /// un ottavo) è periodico quanto quello della banda bassa: la voce è più
  /// acuta e la banda bassa ne sta contando più periodi insieme.
  bool _isSubharmonic(YinAnalysis main, double lowFrequency) {
    if (main.cmndf.isEmpty) {
      return false;
    }
    final lowTau = sampleRate / lowFrequency;
    // Profondità del periodo lungo nel rilevatore principale; se è fuori dal
    // suo intervallo (sotto 55 Hz) si richiede un periodo corto netto.
    final lowDepth = lowTau <= main.maxTau ? main.depthNear(lowTau) : null;
    final reference = lowDepth == null ? strongPeriodicity : lowDepth + subharmonicMargin;
    for (var k = 2; k <= 8; k++) {
      final shorter = lowTau / k;
      if (shorter < main.minTau) {
        break;
      }
      final depth = main.depthNear(shorter);
      if (depth != null && depth < 0.5 && depth <= reference) {
        return true;
      }
    }
    return false;
  }

  static double _rms(List<double> samples) {
    var energy = 0.0;
    for (final sample in samples) {
      energy += sample * sample;
    }
    return math.sqrt(energy / samples.length);
  }

  /// Decima la finestra bassa di 4x con media (anti-alias grezzo ma
  /// sufficiente per contenuti sotto i 250 Hz).
  List<double> _decimated(List<double> window) {
    final frame = List<double>.filled(_lowFrameSize, 0);
    for (var i = 0; i < _lowFrameSize; i++) {
      final base = i * _lowDecimation;
      frame[i] = (window[base] + window[base + 1] + window[base + 2] + window[base + 3]) / 4;
    }
    return frame;
  }
}
