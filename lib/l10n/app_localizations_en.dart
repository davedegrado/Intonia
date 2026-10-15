// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Intonia';

  @override
  String get navHome => 'Home';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navRange => 'Range';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonBack => 'Back';

  @override
  String get commonRetry => 'Try again';

  @override
  String spanSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitones',
      one: '1 semitone',
    );
    return '$_temp0';
  }

  @override
  String spanOctaves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count octaves',
      one: '1 octave',
    );
    return '$_temp0';
  }

  @override
  String spanOctavesAndSemitones(String octaves, String semitones) {
    return '$octaves + $semitones';
  }

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHint =>
      'The note names (C D E or DO RE MI) are chosen separately, under Note names.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeNeon => 'Neon';

  @override
  String get notationInternational => 'C D E';

  @override
  String get notationItalian => 'DO RE MI';

  @override
  String get trainerAdvancedSettings => 'Advanced settings';

  @override
  String get trainerCurrentNote => 'Current note';

  @override
  String get trainerPlayCurrentNote => 'Play the current note';

  @override
  String get trainerSessionStats => 'Session stats';

  @override
  String get trainerStartingNote => 'Starting note:';

  @override
  String get trainerKey => 'Key';

  @override
  String get trainerOctave => 'Octave';

  @override
  String get trainerModeListen => 'Listen';

  @override
  String get trainerModeTrain => 'Training';

  @override
  String get trainerPlay => 'Play';

  @override
  String get trainerStop => 'Stop';

  @override
  String get trainerBpm => 'BPM';

  @override
  String trainerSettingValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get trainerTolerance => 'Tolerance';

  @override
  String trainerToleranceValue(int cents) {
    return '± $cents cents';
  }

  @override
  String get trainerStabilityTime => 'Stability time';

  @override
  String trainerMilliseconds(int ms) {
    return '$ms ms';
  }

  @override
  String get trainerGuideEveryNote => 'Play the guide note on every note';

  @override
  String get trainerGuideEveryNoteHint =>
      'When off, you only hear the first note: tap a note to hear it again';

  @override
  String get trainerLoop => 'Loop (Listen mode only)';

  @override
  String get trainerCalibrate => 'Calibrate background noise';

  @override
  String get trainerCalibrating => 'Stay silent… (3 s)';

  @override
  String get trainerCalibrationFailed => 'Calibration failed: check the microphone permission.';

  @override
  String get trainerCalibrationDone => 'Calibration complete: background noise filtered out.';

  @override
  String get trainerStatusMicOn => 'Microphone on';

  @override
  String get trainerStatusPlaying => 'Playing';

  @override
  String get trainerStatusReady => 'Ready';

  @override
  String get trainerMicrophoneDenied =>
      'Microphone permission denied: enable it in your system settings to train.';

  @override
  String get trainerAudioUnavailable =>
      'Audio could not start: check the microphone and the piano.sf2 SoundFont.';

  @override
  String get trainerDetection => 'Detection';

  @override
  String get trainerDetectedNote => 'Detected note';

  @override
  String get trainerDeviation => 'Deviation';

  @override
  String trainerCentsValue(String value) {
    return '$value cents';
  }

  @override
  String get trainerListening => 'Listening';

  @override
  String get trainerInTune => 'in tune';

  @override
  String get trainerTooLow => 'too low';

  @override
  String get trainerTooHigh => 'too high';

  @override
  String get trainerStatTime => 'Time';

  @override
  String get trainerStatErrors => 'Errors';

  @override
  String get trainerStatAccuracy => 'Accuracy';

  @override
  String get trainerStatCorrect => 'Correct';

  @override
  String get trainerViewNotes => 'Notes';

  @override
  String get trainerViewStaff => 'Staff';

  @override
  String trainerNoteCorrect(String note) {
    return '$note, correct';
  }

  @override
  String trainerNoteWrong(String note) {
    return '$note, to retry';
  }

  @override
  String trainerNoteCurrent(String note) {
    return '$note, current note';
  }

  @override
  String trainerNotePending(String note) {
    return '$note, to sing';
  }

  @override
  String get trainerTapToHear => 'tap to hear it';

  @override
  String trainerStaffSemantics(String notes) {
    return 'Staff: $notes';
  }

  @override
  String get mascotSemanticLabel => 'Intonia mascot';

  @override
  String get mascotCompleted => 'Exercise complete! Great job.';

  @override
  String get mascotSuccess => 'Perfect! Keep it up.';

  @override
  String get mascotRetry => 'Almost! Try again.';

  @override
  String get mascotListenSequence => 'Listen closely to the sequence…';

  @override
  String get mascotSingNote => 'Sing the note: I\'m listening.';

  @override
  String get mascotIdleListen => 'Press Play and listen to the sequence.';

  @override
  String get mascotIdleTrain => 'Ready to train your ear?';

  @override
  String get sessionPerfectTitle => 'Perfect!';

  @override
  String get sessionPerfectMessage => 'No mistakes: you were perfectly in tune!';

  @override
  String get sessionGreatTitle => 'Great job!';

  @override
  String get sessionGreatMessage => 'Almost perfect: your ear is getting better.';

  @override
  String get sessionGoodTitle => 'Well done!';

  @override
  String get sessionGoodMessage => 'You\'re nearly there: repeat it to lock in the notes.';

  @override
  String get sessionRetryTitle => 'Don\'t give up!';

  @override
  String get sessionRetryMessage => 'Listen to the notes again and retry: you improve every round.';

  @override
  String get sessionCorrect => 'Correct';

  @override
  String get sessionErrors => 'Errors';

  @override
  String get sessionDuration => 'Duration';

  @override
  String sessionSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get sessionAccuracy => 'accuracy';

  @override
  String sessionAccuracySemantics(int percent) {
    return 'Accuracy $percent percent';
  }

  @override
  String get sessionContinue => 'Continue';

  @override
  String get sessionRepeat => 'Repeat exercise';

  @override
  String get rangeSectionTitle => 'Vocal range';

  @override
  String get rangeHeadline => 'Discover your vocal range';

  @override
  String get rangeIntro =>
      'Start from a comfortable note: we go down to the lowest and up to the highest note you can sing. The result stays in your profile so you can track your progress.';

  @override
  String get rangeStartTest => 'Start test';

  @override
  String get rangeRetakeTest => 'Retake the test';

  @override
  String get rangeNoTestsYet => 'No tests yet: your result will appear here.';

  @override
  String get rangePreviousTests => 'Previous tests';

  @override
  String get rangeHistoryInProfile => 'Test history in your profile';

  @override
  String get rangeLatestResult => 'Latest result';

  @override
  String rangeSpanDetail(String span, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitones',
      one: '1 semitone',
    );
    return '$span ($_temp0)';
  }

  @override
  String get rangeLowest => 'Lowest';

  @override
  String get rangeHighest => 'Highest';

  @override
  String rangeDeltaShort(String delta) {
    return '$delta st';
  }

  @override
  String get rangeTestTitle => 'Vocal range test';

  @override
  String get rangeHowItWorks => 'How it works';

  @override
  String get rangeHowItWorksBody =>
      'Tap \"Start the test\" and sing a comfortable note, holding it for a moment: I\'ll recognize it and from there we go down one semitone at a time. You only move on when you hit the note; when you really can\'t reach it, tap \"Low limit reached\" (or skip that single note). Then we go up toward the high notes the same way. At the end your range is saved in your profile.';

  @override
  String get rangeSensitivity => 'Sensitivity';

  @override
  String get rangeTolerance => 'Tolerance';

  @override
  String get rangeStabilityTime => 'Stability time';

  @override
  String rangeCents(int cents) {
    return '± $cents cents';
  }

  @override
  String get rangeLastTestPrefix => 'Last test: ';

  @override
  String get rangeStartButton => 'Start the test';

  @override
  String get rangeTowardLow => 'Going down';

  @override
  String get rangeTowardHigh => 'Going up';

  @override
  String get rangeSingThisNote => 'Sing this note (tap to hear it again)';

  @override
  String get rangeValidatedSoFar => 'Range validated so far: ';

  @override
  String get rangeSkipNote => 'Skip this note';

  @override
  String get rangeLowLimitReached => 'Low limit reached';

  @override
  String get rangeHighLimitReached => 'High limit reached';

  @override
  String get rangeCancelTest => 'Cancel the test';

  @override
  String get rangeSingComfortable => 'Sing a comfortable note and hold it';

  @override
  String get rangeListening => 'Listening…';

  @override
  String get rangeStartHoldHint => 'When the bar is full, that\'s your starting note.';

  @override
  String get rangeYourRange => 'Your range';

  @override
  String rangeProgressBetter(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count semitones',
      one: '+1 semitone',
    );
    return '$_temp0 compared to your last test';
  }

  @override
  String get rangeProgressSame => 'Same span as your last test';

  @override
  String rangeProgressWorse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitones',
      one: '-1 semitone',
    );
    return '$_temp0 compared to your last test';
  }

  @override
  String rangeProgressWorseEncouraging(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitones',
      one: '-1 semitone',
    );
    return '$_temp0 compared to your last test: it happens, your voice changes from day to day';
  }

  @override
  String get rangeSavedToProfile =>
      'Result saved to your profile: the test history shows your progress over time.';

  @override
  String get rangeRetryTest => 'Retry the test';

  @override
  String get rangeContinue => 'Continue';

  @override
  String get rangeCoachValidated => 'Great! Next note.';

  @override
  String get rangeCoachSkipped => 'No problem, let\'s try the next one.';

  @override
  String get rangeCoachSetup =>
      'Start from a comfortable note: we\'ll go down toward the low notes together.';

  @override
  String get rangeCoachFindingStart => 'Sing a comfortable note and hold it: I\'ll recognize it.';

  @override
  String get rangeCoachDescending => 'Sing the note: we\'re heading down.';

  @override
  String get rangeCoachAscending => 'Now let\'s go up toward the high notes!';

  @override
  String get rangeCoachDone => 'Here\'s your range! Great job.';

  @override
  String get rangeCoachRetry => 'Let\'s try again starting from a more comfortable note.';

  @override
  String get rangeMicDenied => 'Microphone permission denied: enable it in your system settings.';

  @override
  String get rangeAudioInitFailed =>
      'Audio not initialized: check the microphone and the SoundFont.';

  @override
  String get rangeNothingValidated => 'No notes validated: the test was not saved.';

  @override
  String get rangeResultFirst => 'Here\'s your vocal range!';

  @override
  String get rangeResultBetter => 'New record!';

  @override
  String get rangeResultSame => 'Range confirmed!';

  @override
  String get rangeResultWorse => 'Here\'s your range today';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSettingsTooltip => 'Settings';

  @override
  String get profileEmptyTitle => 'No sessions yet';

  @override
  String get profileEmptyBody =>
      'Complete a workout: here you\'ll find your streak, accuracy, vocal range and history.';

  @override
  String get profileStatSessions => 'Sessions';

  @override
  String get profileStatMinutes => 'Total minutes';

  @override
  String get profileStatAccuracy => 'Average accuracy';

  @override
  String get profileStatRange => 'Vocal range';

  @override
  String get profileBestWorstNotes => 'Best and worst notes';

  @override
  String get profileRangeTests => 'Vocal range tests';

  @override
  String profileRangeDeltaUp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count semitones',
      one: '+1 semitone',
    );
    return '$_temp0 vs. previous';
  }

  @override
  String profileRangeDeltaDown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '-$count semitones',
      one: '-1 semitone',
    );
    return '$_temp0 vs. previous';
  }

  @override
  String get profileRangeUnchanged => 'unchanged';

  @override
  String get profileDeleteRangeTooltip => 'Delete test';

  @override
  String get profileDeleteSessionTooltip => 'Delete session';

  @override
  String get profileAllSessions => 'All sessions';

  @override
  String get profileRecentSessions => 'Recent sessions';

  @override
  String profileFullHistoryPro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return 'Full history ($_temp0) with Intonia Pro';
  }

  @override
  String get profileDeleteRangeTitle => 'Delete this test?';

  @override
  String profileDeleteRangeBody(String date) {
    return 'The test from $date will be removed.';
  }

  @override
  String get profileDeleteSessionTitle => 'Delete this session?';

  @override
  String profileDeleteSessionBody(String name, String date) {
    return '\"$name\" from $date will be removed from your stats, streak and vocal range.';
  }

  @override
  String profileStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get profileStreakStart => 'Practice today to start your streak!';

  @override
  String get profileStreakKeep => 'Keep it up, don\'t break it!';

  @override
  String get exerciseNameTriadMajor => 'Major triad';

  @override
  String get exerciseNameTriadMinor => 'Minor triad';

  @override
  String get exerciseNameTriadAugmented => 'Augmented triad';

  @override
  String get exerciseNameTriadDiminished => 'Diminished triad';

  @override
  String get exerciseNameArpeggioMajorOctave => 'Major arpeggio (octave)';

  @override
  String get exerciseNameArpeggioMinorOctave => 'Minor arpeggio (octave)';

  @override
  String get exerciseNameMajorPentatonic => 'Major pentatonic';

  @override
  String get exerciseNameMinorPentatonic => 'Minor pentatonic';

  @override
  String get exerciseNameMajor => 'Major scale';

  @override
  String get exerciseNameNaturalMinor => 'Natural minor scale';

  @override
  String get exerciseNameHarmonicMinor => 'Harmonic minor scale';

  @override
  String get exerciseNameMelodicMinor => 'Melodic minor scale';

  @override
  String get exerciseNameBlues => 'Blues scale';

  @override
  String get exerciseNameHarmonizedMajor => 'Harmonized major scale';

  @override
  String get exerciseNameHarmonizedNaturalMinor => 'Harmonized natural minor scale';

  @override
  String get exerciseNameHarmonizedHarmonicMinor => 'Harmonized harmonic minor scale';

  @override
  String get exerciseNameHarmonizedMelodicMinor => 'Harmonized melodic minor scale';

  @override
  String get exerciseNameFiveNotePattern => '5-note pattern (1-2-3-4-5)';

  @override
  String get exerciseNameThirdLeaps => 'Leaps in thirds (1-3, 2-4...)';

  @override
  String get categoryLabelCustom => 'Your sequences';

  @override
  String get categoryDescriptionCustom => 'Create and practice your own custom sequences';

  @override
  String get categoryLabelTriads => 'Triads';

  @override
  String get categoryDescriptionTriads => 'Major, minor, augmented and diminished';

  @override
  String get categoryLabelArpeggios => 'Arpeggios';

  @override
  String get categoryDescriptionArpeggios => 'Triads extended to the octave';

  @override
  String get categoryLabelPentatonics => 'Pentatonic scales';

  @override
  String get categoryDescriptionPentatonics => 'Major and minor';

  @override
  String get categoryLabelScales => 'Scales';

  @override
  String get categoryDescriptionScales => 'Major, minor and blues';

  @override
  String get categoryLabelHarmonizations => 'Three-part harmonies';

  @override
  String get categoryDescriptionHarmonizations => 'Diatonic triads on every scale degree';

  @override
  String get categoryLabelPatterns => 'Patterns';

  @override
  String get categoryDescriptionPatterns => 'Melodic warm-up sequences';

  @override
  String get focusAccuracy => 'Accuracy';

  @override
  String get focusEar => 'Ear training';

  @override
  String get focusAgility => 'Agility';

  @override
  String get focusControl => 'Control';

  @override
  String get focusRange => 'Range';

  @override
  String get editorTitleNew => 'New sequence';

  @override
  String get editorTitleEdit => 'Edit sequence';

  @override
  String get editorNameLabel => 'Name';

  @override
  String get editorNameHint => 'e.g. Octave sirens / Vocalise 1-3-5-8';

  @override
  String get editorGroupLabel => 'Group (optional)';

  @override
  String get editorGroupHint => 'e.g. Warm-up, Lesson 3…';

  @override
  String get editorTagLabel => 'Tag (optional)';

  @override
  String get editorAddNotesTitle => 'Add notes';

  @override
  String get editorAddNotesHint =>
      'You can start from any note, repeat the same note and go below the first one. In the trainer you can still transpose the whole sequence.';

  @override
  String editorOctaveShort(int octave) {
    return 'Oct. $octave';
  }

  @override
  String editorSequenceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequence ($count notes)',
      one: 'Sequence (1 note)',
    );
    return '$_temp0';
  }

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorRemoveLast => 'Remove last note';

  @override
  String get editorEmptySequence => 'Tap the notes above to build the sequence.';

  @override
  String get editorErrorNoName => 'Give the sequence a name.';

  @override
  String get editorErrorTooFewNotes => 'Add at least 2 notes.';

  @override
  String get editorAudioUnavailable => 'Audio unavailable: check the piano.sf2 SoundFont.';

  @override
  String get editorProTitle => 'Create your sequence';

  @override
  String get editorProHeadline => 'Your sequences, made to measure';

  @override
  String get editorProBody =>
      'Compose any run of notes, starting from any note you like: vocalises, patterns, leaps, range work. Sequences are saved on the Home screen, grouped the way you prefer, and you practice them just like the built-in exercises.';

  @override
  String get editorProNote =>
      'Creating, editing and saving sequences is an Intonia Pro feature. Sequences you have already saved remain available.';

  @override
  String get editorProCta => 'Discover Intonia Pro';

  @override
  String noteSemanticsLabel(String note, int octave) {
    return '$note, octave $octave';
  }

  @override
  String statusStreakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Streak: $count days in a row',
      one: 'Streak: 1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get homeBubbleIdle => 'Sing or play a note: I\'ll tell you which one!';

  @override
  String get homeBubbleListening => 'I\'m listening… sing or play a note.';

  @override
  String get homeBubbleInTune => 'Perfectly in tune!';

  @override
  String get homeBubbleAlmost => 'Almost there: adjust just a little.';

  @override
  String get homeBubblePermissionDenied => 'Microphone access denied: enable it in Settings.';

  @override
  String get homeStartListening => 'Start listening';

  @override
  String get homeStopListening => 'Stop listening';

  @override
  String get homeMicStartSemantics => 'Start live note detection';

  @override
  String get homeMicStopSemantics => 'Stop note detection';

  @override
  String get homeNotePlaceholder => 'Here you\'ll see the detected note and how in tune you are.';

  @override
  String get homeNoteDetected => 'Detected note';

  @override
  String get homeLastNote => 'Last note';

  @override
  String get homeDeviation => 'Deviation';

  @override
  String homeCents(String value) {
    return '$value cents';
  }

  @override
  String get homeQuickNotation => 'Notation';

  @override
  String get homeQuickTheme => 'Theme';

  @override
  String get homeQuickSettings => 'Settings';

  @override
  String get exercisesCategories => 'Categories';

  @override
  String exercisesSequenceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sequences',
      one: '1 sequence',
    );
    return '$_temp0';
  }

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String exercisesNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get exercisesProBadge => 'PRO';

  @override
  String get exercisesEdit => 'Edit';

  @override
  String get exercisesDeleteTitle => 'Delete this sequence?';

  @override
  String exercisesDeleteMessage(String name) {
    return '“$name” will be permanently removed.';
  }

  @override
  String get exercisesCreateTitle => 'Create your sequence';

  @override
  String get exercisesCreateSubtitle =>
      'Compose any run of notes: patterns, vocal warm-ups, range drills…';

  @override
  String get chargesProSemantics => 'Intonia Pro: unlimited exercises';

  @override
  String get chargesProDeveloperSemantics => 'Intonia Pro, developer build: unlimited exercises';

  @override
  String chargesChipSemantics(int count, int max) {
    return 'Exercise charges: $count of $max';
  }

  @override
  String get chargesWaitUnderMinute => 'less than 1 min';

  @override
  String chargesWaitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String chargesWaitHours(int hours) {
    return '$hours h';
  }

  @override
  String chargesWaitHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get chargesTitle => 'Exercise charges';

  @override
  String get chargesExhaustedTitle => 'Out of charges';

  @override
  String chargesNextIn(String wait) {
    return 'Next charge in $wait.';
  }

  @override
  String chargesExplanation(int hours, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'One comes back every $hours hours',
      one: 'One comes back every hour',
    );
    return 'Each exercise session uses one charge. $_temp0, even with the app closed, up to $max.';
  }

  @override
  String get chargesFreeFeatures =>
      'Live note detection and the vocal range test are always free and unlimited.';

  @override
  String get chargesDiscoverPro => 'Discover Intonia Pro';

  @override
  String get chargesWaitForRecharge => 'I\'ll wait for a recharge';

  @override
  String chargesHint(int count, int max) {
    return 'Each session uses 1 charge · $count/$max available';
  }

  @override
  String get proTitle => 'Intonia Pro';

  @override
  String get proHeadlinePro => 'You have Intonia Pro';

  @override
  String get proHeadlineFree => 'Train without limits';

  @override
  String get proDeveloperNote => 'Developer build: Pro active without a subscription.';

  @override
  String get proBenefitUnlimitedTitle => 'Unlimited exercises';

  @override
  String get proBenefitUnlimitedText => 'No charges: as many sessions as you like.';

  @override
  String get proBenefitCustomTitle => 'Custom sequences';

  @override
  String get proBenefitCustomText => 'Create, edit and save your own exercises.';

  @override
  String get proBenefitHistoryTitle => 'Full history';

  @override
  String get proBenefitHistoryText => 'All your sessions in your profile.';

  @override
  String get proBenefitComingTitle => 'Coming soon';

  @override
  String get proBenefitComingText => 'Advanced statistics, progress charts and personalized paths.';

  @override
  String proFreeForever(int max) {
    return 'Free forever: live note detection, the vocal range test, every exercise with $max recharging charges, profile, essential stats and daily streak.';
  }

  @override
  String get proPlanMonthly => 'Monthly';

  @override
  String get proPlanYearly => 'Yearly';

  @override
  String get proPriceMonthly => '€4.99';

  @override
  String get proPriceYearly => '€39.99';

  @override
  String get proPeriodMonth => 'per month';

  @override
  String get proPeriodYear => 'per year';

  @override
  String get proYearlySaving => 'Save 33%';

  @override
  String get proSubscribe => 'Subscribe';

  @override
  String get proComingSoon =>
      'Subscriptions will be available soon through the App Store and Google Play.';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotation => 'Note names';

  @override
  String get settingsInfo => 'About';

  @override
  String settingsAbout(String version) {
    return 'Intonia $version — offline pitch training.';
  }

  @override
  String get settingsSoundCredit =>
      'Piano sound: Fluid (R3) SoundFont, © 2000–2002, 2008 Frank Wen, MIT license.';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get trainerDirectionForward => 'Straight';

  @override
  String get trainerDirectionReverse => 'Reverse';

  @override
  String get trainerDirectionComplete => 'Full';

  @override
  String get trainerRepeatTop => 'Repeat the top note';

  @override
  String get trainerRepeatTopHint => 'Repeats the highest note before going down';

  @override
  String get exercisesCreateFromScratch => 'Start from scratch';

  @override
  String get exercisesCreateFromExercise => 'Start from an exercise';

  @override
  String get exercisesCreateFromExerciseHint => 'Copy an exercise and edit it freely';

  @override
  String profileSessionKeyOctave(String key, int octave) {
    return '$key · Octave $octave';
  }

  @override
  String get profileSessionTopRepeated => 'top note repeated';

  @override
  String get guideTitle => 'Intonia guide';

  @override
  String get guideOpenHint => 'Replay the tour of the app\'s features';

  @override
  String get guideNext => 'Next';

  @override
  String get guideDone => 'Done';

  @override
  String get guideSkip => 'Skip';

  @override
  String guideProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get guideHome =>
      'Tap the microphone and sing or play a note: I\'ll tell you which note it is and how many cents off you are. At the top you\'ll find your streak and your exercise charges; at the bottom, quick access to note names, theme and settings.';

  @override
  String get guideExercises =>
      'Pick a category (triads, arpeggios, scales and more), open an exercise and press Play to train with your voice. Each session uses one charge. With Create your sequence you can write your own (Intonia Pro).';

  @override
  String get guideExerciseSettingsTitle => 'Exercise settings';

  @override
  String get guideExerciseSettings =>
      'In an exercise you choose the key and octave, the mode (Straight, Reverse or Full) and, in Full mode, whether to repeat the top note. The ? button in the exercise explains these options.';

  @override
  String get guideRange =>
      'The range test starts from a comfortable note, goes down to your lowest note and then up to your highest. The result shows the two extreme notes and the span in octaves and semitones; past tests are listed here and in your profile.';

  @override
  String get guideProfile =>
      'Your streak, sessions, total minutes, average accuracy, vocal range, best and worst notes, range tests and your recent sessions with key and octave.';

  @override
  String get guideSettingsTitle => 'Settings';

  @override
  String get guideSettings =>
      'Choose the language, the theme (System, Light, Dark or Neon) and the note names (C D E or DO RE MI). You can reopen this guide from here at any time.';

  @override
  String get guideKey => 'The note the exercise starts from.';

  @override
  String get guideOctave =>
      'How high or low the exercise is: pick one that\'s comfortable for your voice.';

  @override
  String get guideDirectionTitle => 'Mode';

  @override
  String get guideDirection =>
      'Straight plays the sequence forwards, Reverse plays it backwards, Full goes forwards and then comes back.';

  @override
  String get guideRepeatTop =>
      'Only in Full mode: you sing the highest note twice before going down.';
}
