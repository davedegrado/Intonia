import 'dart:async';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/services/pitch/microphone_pitch_service.dart';

/// Sintetizzatore finto: registra le chiamate senza toccare il plugin nativo.
class FakeMidiPro extends MidiPro {
  int loadCount = 0;
  final List<int> unloaded = [];
  final List<int> played = [];
  final List<int> stopped = [];

  /// Note attualmente "premute" (playNote senza stopNote successivo).
  final Set<int> sounding = {};

  @override
  Future<int> loadSoundfontAsset({
    required String assetPath,
    int bank = 0,
    int program = 0,
  }) async {
    loadCount++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return 1;
  }

  @override
  Future<void> selectInstrument({
    required int sfId,
    required int program,
    int channel = 0,
    int bank = 0,
  }) async {}

  @override
  Future<void> playNote({
    int channel = 0,
    required int key,
    int velocity = 127,
    int sfId = 1,
  }) async {
    played.add(key);
    sounding.add(key);
  }

  @override
  Future<void> stopNote({int channel = 0, required int key, int sfId = 1}) async {
    stopped.add(key);
    sounding.remove(key);
  }

  @override
  Future<void> unloadSoundfont(int sfId) async {
    unloaded.add(sfId);
  }
}

/// Microfono finto con permesso e tempi di avvio controllabili.
class FakeMicrophonePitchService implements MicrophonePitchService {
  FakeMicrophonePitchService({this.permissionGranted = true});

  bool permissionGranted;

  /// Se impostato, [start] attende questo completer (simula il dialog del
  /// permesso o l'avvio lento del registratore).
  Completer<void>? startGate;

  /// Gate per singola chiamata (in ordine di chiamata), per controllare
  /// l'ordine in cui avvii concorrenti si completano. Ha precedenza su
  /// [startGate].
  final List<Completer<void>> perCallGates = [];

  bool isRecording = false;
  int startCalls = 0;
  int stopCalls = 0;
  final _controller = StreamController<PitchDetectionResult>.broadcast();

  void emit(PitchDetectionResult result) => _controller.add(result);

  /// Simula un errore del flusso audio (microfono perso, interruzione).
  void emitError(Object error) => _controller.addError(error);

  /// Se impostato, [start] fallisce con questa eccezione (audio non disponibile).
  Object? startError;

  @override
  Stream<PitchDetectionResult> get pitchStream => _controller.stream;

  @override
  Future<bool> get hasPermission async => permissionGranted;

  @override
  double get silenceThreshold => 0.015;

  @override
  void setSilenceThreshold(double threshold) {}

  @override
  Future<double> measureAmbientRms({Duration duration = const Duration(seconds: 3)}) async {
    if (!permissionGranted) {
      throw StateError('microphone-permission-denied');
    }
    return 0.01;
  }

  @override
  Future<bool> start() async {
    final index = startCalls++;
    final gate = index < perCallGates.length ? perCallGates[index] : startGate;
    if (gate != null) {
      await gate.future;
    }
    if (startError != null) {
      throw startError!;
    }
    if (!permissionGranted) {
      return false;
    }
    isRecording = true;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    isRecording = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
