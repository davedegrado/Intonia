import '../../mascot/domain/mascot_mood.dart';
import 'trainer_state.dart';
import 'training_settings.dart';
import 'training_state_machine.dart';

/// Stato della mascotte ricavato SOLO dallo stato del trainer già calcolato
/// dalla macchina a stati (nessuna soglia musicale aggiuntiva):
/// - esercizio completato → [MascotMood.success];
/// - in ascolto, appena convalidata una nota (in attesa del cambio nota)
///   → [MascotMood.success];
/// - in ascolto, nota segnata come errore (in attesa di un nuovo tentativo)
///   → [MascotMood.retry];
/// - microfono in ascolto o riproduzione in corso → [MascotMood.listening];
/// - altrimenti → [MascotMood.idle].
MascotMood mascotMoodForTrainer(TrainerState state) {
  if (state.sequence.isEmpty) {
    return MascotMood.idle;
  }
  if (state.isFinished) {
    return MascotMood.success;
  }
  if (state.isListening) {
    return switch (state.validationState) {
      TrainingValidationState.waitChange => MascotMood.success,
      TrainingValidationState.waitRetry => MascotMood.retry,
      TrainingValidationState.waitNote => MascotMood.listening,
    };
  }
  if (state.isPlaying) {
    return MascotMood.listening;
  }
  return MascotMood.idle;
}

/// Messaggio del fumetto della mascotte nel trainer.
String mascotMessageForTrainer(TrainerState state) {
  final listenMode = state.settings.mode == TrainerMode.listen;
  if (state.isFinished) {
    return 'Esercizio completato! Grande lavoro.';
  }
  return switch (mascotMoodForTrainer(state)) {
    MascotMood.success => 'Perfetto! Continua così.',
    MascotMood.retry => 'Quasi! Prova ancora.',
    MascotMood.listening => listenMode ? 'Ascolta bene la sequenza…' : 'Canta la nota: ti ascolto.',
    MascotMood.idle ||
    MascotMood.greeting =>
      listenMode ? 'Premi Play e ascolta la sequenza.' : 'Pronto ad allenare il tuo orecchio?',
  };
}
