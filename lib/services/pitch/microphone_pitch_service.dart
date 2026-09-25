import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../core/pitch/pitch_detection_result.dart';
import '../../core/pitch/yin_pitch_detector.dart';

class MicrophonePitchService {
  MicrophonePitchService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  static const sampleRate = 44100;
  static const frameSize = 2048;

  /// Analisi banda bassa (vocal fry): finestra doppia, decimata di 4x.
  static const _lowDecimation = 4;
  static const _lowWindowSize = 4096; // ~93 ms a 44.1 kHz
  static const _lowFrameSize = _lowWindowSize ~/ _lowDecimation;

  final AudioRecorder _recorder;
  final _pitchController = StreamController<PitchDetectionResult>.broadcast();
  final List<double> _buffer = [];
  final List<double> _lowBuffer = [];
  StreamSubscription<Uint8List>? _subscription;
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

  Stream<PitchDetectionResult> get pitchStream => _pitchController.stream;

  Future<bool> get hasPermission => _recorder.hasPermission();

  double get silenceThreshold => _detector.rmsSilenceThreshold;

  void setSilenceThreshold(double threshold) {
    _detector.rmsSilenceThreshold = threshold;
    _lowDetector.rmsSilenceThreshold = threshold * 0.6;
  }

  /// Misura l'RMS del rumore ambientale per [duration] (a stanza silenziosa).
  /// Ritorna il 90° percentile dell'RMS dei frame raccolti.
  Future<double> measureAmbientRms({Duration duration = const Duration(seconds: 3)}) async {
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone-permission-denied');
    }
    await stop();

    final rmsValues = <double>[];
    final buffer = <double>[];
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
    final subscription = stream.listen((bytes) {
      final byteData = ByteData.sublistView(bytes);
      for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
        buffer.add(byteData.getInt16(offset, Endian.little) / 32768.0);
      }
      while (buffer.length >= frameSize) {
        var energy = 0.0;
        for (var i = 0; i < frameSize; i++) {
          energy += buffer[i] * buffer[i];
        }
        buffer.removeRange(0, frameSize);
        rmsValues.add(math.sqrt(energy / frameSize));
      }
    });

    await Future<void>.delayed(duration);
    await subscription.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    if (rmsValues.isEmpty) {
      return 0;
    }
    rmsValues.sort();
    final index = (rmsValues.length * 0.9).floor().clamp(0, rmsValues.length - 1);
    return rmsValues[index];
  }

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      _pitchController.add(PitchDetectionResult.silence);
      return;
    }

    await stop();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        // AEC di sistema: rimuove dal mic il suono riprodotto dall'app
        // (la guida al piano), che altrimenti verrebbe convalidato come voce.
        echoCancel: true,
        noiseSuppress: false,
      ),
    );

    _subscription = stream.listen(_handleBytes);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _buffer.clear();
    _lowBuffer.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _pitchController.close();
    _recorder.dispose();
  }

  void _handleBytes(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
      final sample = byteData.getInt16(offset, Endian.little) / 32768.0;
      _buffer.add(sample);
      _lowBuffer.add(sample);
    }
    if (_lowBuffer.length > _lowWindowSize) {
      _lowBuffer.removeRange(0, _lowBuffer.length - _lowWindowSize);
    }

    while (_buffer.length >= frameSize) {
      final frame = List<double>.from(_buffer.take(frameSize));
      _buffer.removeRange(0, frameSize ~/ 2);

      var result = _detector.detect(frame);
      // Il rilevatore standard non scende sotto ~55 Hz e scarta il fry
      // (quasi-periodico): se non ha agganciato nulla di stabile, riprova
      // sulla banda bassa con finestra lunga decimata.
      if (!result.isStable && _lowBuffer.length >= _lowWindowSize) {
        final low = _lowDetector.detect(_decimatedLowFrame());
        if (low.isStable) {
          result = low;
        }
      }
      _pitchController.add(result);
    }
  }

  /// Decima la finestra bassa di 4x con media (anti-alias grezzo ma
  /// sufficiente per contenuti sotto i 250 Hz).
  List<double> _decimatedLowFrame() {
    final frame = List<double>.filled(_lowFrameSize, 0);
    for (var i = 0; i < _lowFrameSize; i++) {
      final base = i * _lowDecimation;
      frame[i] = (_lowBuffer[base] +
              _lowBuffer[base + 1] +
              _lowBuffer[base + 2] +
              _lowBuffer[base + 3]) /
          4;
    }
    return frame;
  }
}
