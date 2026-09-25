import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/pitch_detection_result.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';

/// Riconoscimento in tempo reale nella Home: parte SOLO su richiesta
/// dell'utente e si ferma su stop, navigazione altrove o app in background.
class TunerState {
  const TunerState({required this.active, this.detection});

  final bool active;
  final PitchDetectionResult? detection;
}

final tunerControllerProvider = NotifierProvider<TunerController, TunerState>(
  TunerController.new,
);

class TunerController extends Notifier<TunerState> {
  StreamSubscription<PitchDetectionResult>? _subscription;

  @override
  TunerState build() {
    ref.onDispose(() => unawaited(stop()));
    return const TunerState(active: false);
  }

  Future<void> start() async {
    if (state.active) {
      return;
    }
    final microphone = ref.read(microphonePitchServiceProvider);
    try {
      await microphone.start();
      _subscription = microphone.pitchStream.listen((detection) {
        state = TunerState(active: true, detection: detection);
      });
      state = const TunerState(active: true);
    } catch (_) {
      state = const TunerState(active: false);
    }
  }

  Future<void> stop() async {
    if (!state.active && _subscription == null) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    await ref.read(microphonePitchServiceProvider).stop();
    state = const TunerState(active: false);
  }
}
