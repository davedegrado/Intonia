import '../../../core/music/note.dart';
import '../../../core/pitch/pitch_detection_result.dart';
import '../../../core/session/session_stats.dart';
import 'note_progress.dart';
import 'training_settings.dart';
import 'training_state_machine.dart';

class TrainerState {
  const TrainerState({
    required this.settings,
    required this.sequence,
    required this.progress,
    required this.currentIndex,
    required this.isPlaying,
    required this.isListening,
    required this.validationState,
    required this.sessionStats,
    this.detectedPitch,
    this.message,
  });

  factory TrainerState.initial({
    required TrainingSettings settings,
    required List<MusicalNote> sequence,
  }) {
    return TrainerState(
      settings: settings,
      sequence: sequence,
      progress: [
        for (var i = 0; i < sequence.length; i++)
          i == 0 ? NoteProgressStatus.current : NoteProgressStatus.pending,
      ],
      currentIndex: 0,
      isPlaying: false,
      isListening: false,
      validationState: TrainingValidationState.waitNote,
      sessionStats: SessionStats.started(),
    );
  }

  final TrainingSettings settings;
  final List<MusicalNote> sequence;
  final List<NoteProgressStatus> progress;
  final int currentIndex;
  final bool isPlaying;
  final bool isListening;
  final TrainingValidationState validationState;
  final PitchDetectionResult? detectedPitch;
  final SessionStats sessionStats;
  final String? message;

  MusicalNote get currentNote => sequence[currentIndex];

  bool get isFinished => currentIndex >= sequence.length - 1 &&
      progress.where((status) => status == NoteProgressStatus.correct).length == sequence.length;

  TrainerState copyWith({
    TrainingSettings? settings,
    List<MusicalNote>? sequence,
    List<NoteProgressStatus>? progress,
    int? currentIndex,
    bool? isPlaying,
    bool? isListening,
    TrainingValidationState? validationState,
    PitchDetectionResult? detectedPitch,
    SessionStats? sessionStats,
    String? message,
    bool clearMessage = false,
  }) {
    return TrainerState(
      settings: settings ?? this.settings,
      sequence: sequence ?? this.sequence,
      progress: progress ?? this.progress,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isListening: isListening ?? this.isListening,
      validationState: validationState ?? this.validationState,
      detectedPitch: detectedPitch ?? this.detectedPitch,
      sessionStats: sessionStats ?? this.sessionStats,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
