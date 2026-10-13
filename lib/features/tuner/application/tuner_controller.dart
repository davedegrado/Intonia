import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/pitch_detection_result.dart';
import '../../../services/pitch/microphone_pitch_service.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';

/// Riconoscimento in tempo reale nella Home: parte SOLO su richiesta
/// dell'utente e si ferma su stop, navigazione altrove o app in background.
class TunerState {
  const TunerState({required this.active, this.detection, this.permissionDenied = false});

  final bool active;
  final PitchDetectionResult? detection;

  /// True se l'ultimo avvio è fallito per permesso microfono negato.
  final bool permissionDenied;
}

final tunerControllerProvider = NotifierProvider<TunerController, TunerState>(
  TunerController.new,
);

class TunerController extends Notifier<TunerState> {
  StreamSubscription<PitchDetectionResult>? _subscription;
  late MicrophonePitchService _microphone;

  /// Incrementato da [stop]: un avvio ancora in corso (es. dialog del
  /// permesso aperto) non deve accendere il microfono dopo uno stop.
  int _generation = 0;

  @override
  TunerState build() {
    _microphone = ref.read(microphonePitchServiceProvider);
    // In onDispose non si possono usare ref né state: si rilasciano solo
    // le risorse catturate.
    ref.onDispose(() {
      _generation++;
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_microphone.stop());
    });
    return const TunerState(active: false);
  }

  Future<void> start() async {
    if (state.active) {
      return;
    }
    final generation = ++_generation;
    try {
      final started = await _microphone.start();
      if (generation != _generation) {
        if (started) {
          await _microphone.stop();
        }
        return;
      }
      if (!started) {
        state = const TunerState(active: false, permissionDenied: true);
        return;
      }
      _subscription = _microphone.pitchStream.listen((detection) {
        state = TunerState(active: true, detection: detection);
      });
      state = const TunerState(active: true);
    } catch (_) {
      if (generation == _generation) {
        state = const TunerState(active: false);
      }
    }
  }

  Future<void> stop() async {
    _generation++;
    if (!state.active && _subscription == null) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    await _microphone.stop();
    state = const TunerState(active: false);
  }
}
