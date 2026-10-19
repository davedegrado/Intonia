import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../core/pitch/pitch_detection_result.dart';
import '../../core/pitch/pitch_frame_analyzer.dart';

class MicrophonePitchService {
  MicrophonePitchService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  static const sampleRate = 44100;
  static const frameSize = 2048;

  /// Un risultato (anche di silenzio) ogni mezza finestra: ~23,2 ms. I frame
  /// arrivano a gruppi, quindi le durate si contano in frame, non con
  /// l'orologio.
  static const double hopMs = frameSize / 2 / sampleRate * 1000;

  final AudioRecorder _recorder;
  final _pitchController = StreamController<PitchDetectionResult>.broadcast();
  StreamSubscription<Uint8List>? _subscription;

  /// Rilevatore principale, banda bassa e verifica delle sottoarmoniche.
  final _analyzer = PitchFrameAnalyzer(sampleRate: sampleRate, frameSize: frameSize);

  Stream<PitchDetectionResult> get pitchStream => _pitchController.stream;

  Future<bool> get hasPermission => _recorder.hasPermission();

  double get silenceThreshold => _analyzer.silenceThreshold;

  void setSilenceThreshold(double threshold) => _analyzer.setSilenceThreshold(threshold);

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

    try {
      await Future<void>.delayed(duration);
    } finally {
      await subscription.cancel();
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    }

    if (rmsValues.isEmpty) {
      return 0;
    }
    rmsValues.sort();
    final index = (rmsValues.length * 0.9).floor().clamp(0, rmsValues.length - 1);
    return rmsValues[index];
  }

  /// Avvia l'ascolto del microfono. Ritorna false se il permesso è stato
  /// negato: in quel caso non viene acquisito alcun audio e il chiamante deve
  /// informare l'utente invece di mostrarsi "in ascolto".
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) {
      return false;
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
    return true;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _analyzer.reset();
  }

  Future<void> dispose() async {
    await stop();
    await _pitchController.close();
    _recorder.dispose();
  }

  void _handleBytes(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    final samples = [
      for (var offset = 0; offset + 1 < bytes.length; offset += 2)
        byteData.getInt16(offset, Endian.little) / 32768.0,
    ];
    for (final result in _analyzer.addSamples(samples)) {
      _pitchController.add(result);
    }
  }
}
