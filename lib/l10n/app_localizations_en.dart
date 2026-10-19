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
  String get trainerDirectionForward => 'Ascending';

  @override
  String get trainerDirectionReverse => 'Descending';

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
  String get guideKey => 'The note the exercise starts from.';

  @override
  String get guideOctave =>
      'How high or low the exercise is: pick one that\'s comfortable for your voice.';

  @override
  String get guideDirectionTitle => 'Mode';

  @override
  String get guideDirection =>
      'Ascending plays the sequence from the bottom up, Descending from the top down, Full goes up and then comes back down.';

  @override
  String get guideRepeatTop =>
      'Only in Full mode: you sing the highest note twice before going down.';

  @override
  String get rangeNotMine => 'Not me';

  @override
  String get rangeNotMineResult => 'It wasn\'t me: remove this test';

  @override
  String get rangeNotMineTitle => 'Not your test?';

  @override
  String rangeNotMineBody(String date) {
    return 'The test from $date will be removed from your results and history.';
  }

  @override
  String get rangeNotMineConfirm => 'Remove';

  @override
  String get tessituraTitle => 'Comfort zone test';

  @override
  String get tessituraSectionTitle => 'Comfort zone (tessitura)';

  @override
  String get tessituraSectionIntro =>
      'Not your highest or lowest note: the part of your voice where singing feels easy.';

  @override
  String get tessituraStart => 'Find your comfort zone';

  @override
  String get tessituraRetake => 'Retake the comfort zone test';

  @override
  String get tessituraHowItWorks =>
      'You sing short phrases that go up and come back down (about 3–5 minutes). After each one, tell me how comfortable it felt. I also listen to how steady and centred each note is and whether you can hold it, but your answer counts the most.';

  @override
  String get tessituraUsesRange =>
      'I start from your latest range test and move up and down from there.';

  @override
  String get tessituraNoRange =>
      'No range test yet: you\'ll start by holding a comfortable note. A range test first gives a more reliable map.';

  @override
  String get tessituraNotAClassification =>
      'This is an estimate for practice, not a voice type (soprano, alto, tenor, bass) and not a medical assessment.';

  @override
  String get tessituraCoachIntro => 'Let\'s find where your voice feels at home!';

  @override
  String get tessituraCoachFindStart => 'Hold a note that feels easy.';

  @override
  String get tessituraCoachSing => 'Sing along, no need to push.';

  @override
  String get tessituraCoachSustain => 'Now hold it steady…';

  @override
  String get tessituraCoachRate => 'How did that one feel?';

  @override
  String get tessituraCoachDone => 'Here\'s your comfort zone!';

  @override
  String get tessituraCoachProvisional =>
      'A first estimate: repeat the test to make it more precise.';

  @override
  String tessituraTrial(int number) {
    return 'Phrase $number';
  }

  @override
  String get tessituraHoldNote => 'Hold this note';

  @override
  String get tessituraFinishNow => 'Finish now';

  @override
  String get tessituraCancel => 'Cancel';

  @override
  String get tessituraRateQuestion => 'How comfortable was it to sing?';

  @override
  String get tessituraRateEasy => 'Comfortable';

  @override
  String get tessituraRateEffort => 'A bit of effort';

  @override
  String get tessituraRateHard => 'Hard or strained';

  @override
  String get tessituraRateFailed => 'I couldn\'t sing it';

  @override
  String get tessituraComfortZone => 'Comfort zone';

  @override
  String get tessituraNoZone => 'Not enough data yet';

  @override
  String get tessituraMaxRange => 'Maximum range';

  @override
  String get tessituraToVerify => 'To verify';

  @override
  String tessituraReliability(String level) {
    return 'Reliability: $level';
  }

  @override
  String get tessituraReliabilityLow => 'low';

  @override
  String get tessituraReliabilityMedium => 'medium';

  @override
  String get tessituraReliabilityHigh => 'good';

  @override
  String get tessituraProvisional => 'Provisional estimate';

  @override
  String get tessituraLastResult => 'Last result';

  @override
  String tessituraCompareSame(String date) {
    return 'Same width as on $date.';
  }

  @override
  String tessituraCompareDelta(String date, String delta) {
    return '$delta semitones compared with $date.';
  }

  @override
  String get tessituraLegend =>
      'Coloured band: comfort zone. Light band: maximum range. Dots: notes to check again (uncertain or inconsistent results). The estimate is indicative and can change with the day, warm-up and tiredness.';

  @override
  String get workoutTitle => 'Daily workout';

  @override
  String get workoutGoal =>
      'A ready-made session with the exercises you already know: a warm-up, a few main exercises and a final review. When there is enough data it also brings back the exercises you find hardest.';

  @override
  String get workoutCoachReady => 'Ready for today\'s session?';

  @override
  String get workoutCoachDone => 'Workout done, well done!';

  @override
  String get workoutCoachPartial => 'Good work: next time try the ones you skipped.';

  @override
  String get workoutDurationLabel => 'Duration';

  @override
  String workoutMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String workoutSummaryLine(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return 'About $minutes min · $_temp0';
  }

  @override
  String get workoutBalanced => 'Balanced routine: there isn\'t enough data on your sessions yet.';

  @override
  String get workoutPersonalized => 'Based on your previous sessions.';

  @override
  String workoutPersonalizedHard(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return 'Based on your previous sessions, with $_temp0 to review.';
  }

  @override
  String get workoutDurationNote =>
      'Times are indicative: they come from your previous sessions or, if there are none, from the number of notes.';

  @override
  String workoutChargesNote(int count, int available) {
    return 'Each exercise uses 1 charge, like the other exercises ($count exercises, you have $available).';
  }

  @override
  String get workoutStart => 'Start workout';

  @override
  String get workoutRoleWarmUp => 'Warm-up';

  @override
  String get workoutRoleMain => 'Main';

  @override
  String get workoutRoleReview => 'Review';

  @override
  String get workoutDifficultTag => 'to practise';

  @override
  String get workoutDifficultReason => 'Chosen because it was harder for you in recent sessions.';

  @override
  String workoutApproxMinutes(int minutes) {
    return '~$minutes min';
  }

  @override
  String workoutApproxSeconds(int seconds) {
    return '~$seconds s';
  }

  @override
  String workoutProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String workoutRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises left',
      one: '1 exercise left',
      zero: 'Last one done',
    );
    return '$_temp0';
  }

  @override
  String workoutStepOf(int index, int total) {
    return '$index of $total';
  }

  @override
  String get workoutOpenStep => 'Start this exercise';

  @override
  String get workoutSkip => 'Skip';

  @override
  String get workoutSkipped => 'Skipped';

  @override
  String get workoutInterrupt => 'Stop workout';

  @override
  String get workoutInterruptTitle => 'Stop the workout?';

  @override
  String get workoutInterruptBody =>
      'It will be saved as interrupted, not completed. The exercises you finished stay in your history.';

  @override
  String get workoutKeepGoing => 'Keep going';

  @override
  String get workoutCompleted => 'Workout completed';

  @override
  String get workoutPartial => 'Workout finished with some skips';

  @override
  String workoutDoneLine(int done, int total) {
    return '$done of $total exercises completed';
  }

  @override
  String workoutAccuracyLine(int percent) {
    return 'Overall accuracy: $percent%';
  }

  @override
  String workoutInProgress(int done, int total) {
    return 'In progress: $done of $total';
  }

  @override
  String get workoutDoneToday => 'Completed today';

  @override
  String workoutPartialToday(int done, int total) {
    return 'Done today: $done of $total';
  }

  @override
  String get achievementsTitle => 'Goals and badges';

  @override
  String get achievementsCoach => 'Every small step counts!';

  @override
  String get achievementsStreakCurrent => 'Current streak';

  @override
  String get achievementsStreakBest => 'Best streak';

  @override
  String get achievementsBadges => 'Badges';

  @override
  String achievementsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String achievementsBadgeCount(int unlocked, int total) {
    return '$unlocked of $total';
  }

  @override
  String get achievementsDaily => 'Today\'s missions';

  @override
  String get achievementsDailyHint => 'New missions every day at midnight.';

  @override
  String get achievementsWeekly => 'This week\'s missions';

  @override
  String achievementsWeeklyHint(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Until Sunday $dateString.';
  }

  @override
  String get achievementsMissionDone => 'Done';

  @override
  String achievementsProgress(int value, int target) {
    return '$value of $target';
  }

  @override
  String achievementsUnlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Unlocked on $dateString';
  }

  @override
  String get achievementsLocked => 'Locked';

  @override
  String get achievementsUnlocked => 'Unlocked';

  @override
  String get achievementsToastTitle => 'Badge unlocked!';

  @override
  String achievementsProfileSummary(int unlocked, int total, int done, int missions) {
    return '$unlocked/$total badges · today\'s missions $done/$missions';
  }

  @override
  String get achievementsCategoryConsistency => 'Consistency';

  @override
  String get achievementsCategoryTraining => 'Practice';

  @override
  String get achievementsCategoryAccuracy => 'Accuracy';

  @override
  String get achievementsCategoryExploration => 'Exploration';

  @override
  String get achievementsCountingRules =>
      'Only completed exercises count (not interrupted ones), and each one counts once. Accuracy goals need at least 5 sung notes. The streak counts days with at least one session: opening the app is not enough.';

  @override
  String get achievementNoteRunHint =>
      'Counted from sessions recorded by this version of Intonia onwards.';

  @override
  String get achievementFirstExerciseName => 'First step';

  @override
  String get achievementFirstExerciseDesc => 'Complete your first exercise.';

  @override
  String get achievementDays3Name => 'Three days';

  @override
  String get achievementDays3Desc => 'Complete exercises on 3 different days.';

  @override
  String get achievementDays7Name => 'Seven days';

  @override
  String get achievementDays7Desc => 'Complete exercises on 7 different days.';

  @override
  String get achievementStreak7Name => '7-day streak';

  @override
  String get achievementStreak7Desc => 'Practise 7 days in a row.';

  @override
  String get achievementStreak30Name => '30-day streak';

  @override
  String get achievementStreak30Desc => 'Practise 30 days in a row.';

  @override
  String get achievementExercises5Name => 'Warming up';

  @override
  String get achievementExercises5Desc => 'Complete 5 exercises.';

  @override
  String get achievementExercises25Name => 'In good shape';

  @override
  String get achievementExercises25Desc => 'Complete 25 exercises.';

  @override
  String get achievementFirstWorkoutName => 'First workout';

  @override
  String get achievementFirstWorkoutDesc => 'Complete a daily workout.';

  @override
  String get achievementWorkouts5Name => 'Five workouts';

  @override
  String get achievementWorkouts5Desc => 'Complete 5 daily workouts.';

  @override
  String get achievementWorkouts10Name => 'Ten workouts';

  @override
  String get achievementWorkouts10Desc => 'Complete 10 daily workouts.';

  @override
  String get achievementPerfectName => 'Spot on!';

  @override
  String get achievementPerfectDesc => 'Complete an exercise with 100% accuracy.';

  @override
  String get achievementAccurate5Name => 'Sharp ear';

  @override
  String get achievementAccurate5Desc => 'Complete 5 exercises with at least 90% accuracy.';

  @override
  String get achievementNoteRun10Name => 'Ten in a row';

  @override
  String get achievementNoteRun10Desc => 'Sing 10 correct notes in a row in one exercise.';

  @override
  String get achievementCategories3Name => 'Explorer';

  @override
  String get achievementCategories3Desc => 'Complete exercises in 3 different categories.';

  @override
  String get achievementFirstTessituraName => 'Comfort zone';

  @override
  String get achievementFirstTessituraDesc => 'Complete the comfort zone test.';

  @override
  String get achievementSecondTessituraName => 'Back in the zone';

  @override
  String get achievementSecondTessituraDesc => 'Take the comfort zone test again on another day.';

  @override
  String get missionDailyExercises2 => 'Complete 2 exercises today';

  @override
  String get missionDailyExercises3 => 'Complete 3 exercises today';

  @override
  String get missionDailyWorkout => 'Complete the daily workout';

  @override
  String get missionDailyAccuracy90 => 'Get at least 90% in an exercise';

  @override
  String get missionWeeklyCategories2 => 'Complete exercises in 2 categories';

  @override
  String get missionWeeklyDays3 => 'Complete exercises on 3 different days';

  @override
  String get missionWeeklyWorkouts2 => 'Complete 2 daily workouts';

  @override
  String get guideMicTitle => 'The microphone';

  @override
  String get guideMicText =>
      'Hi, I\'m Intonia! Tap here and sing or play a note: I\'ll tell you which one it is and how many cents off you are.';

  @override
  String get guideWorkoutText =>
      'A ready-made session with the exercises you know: open this card, choose 5, 10 or 15 minutes and start.';

  @override
  String get guideStatusTitle => 'Streak and charges';

  @override
  String get guideStatusText =>
      'Here you see how many days in a row you\'ve practised and your exercise charges: each session uses one, and they refill over time.';

  @override
  String get guideCategoriesText =>
      'Exercises are grouped by category: triads, arpeggios, scales and more. Each one trains a different side of your voice.';

  @override
  String get guideCustomText =>
      'Here you compose your own sequences, from scratch or starting from an exercise (Intonia Pro).';

  @override
  String get guideRangeText =>
      'Find the lowest and highest notes you can sing. Your results stay here and in your profile.';

  @override
  String get guideTessituraText =>
      'The comfort zone test looks for the part of your voice where singing feels easy.';

  @override
  String get guideStatsTitle => 'Your statistics';

  @override
  String get guideStatsText =>
      'Streak, sessions, minutes and average accuracy: everything updates as you practise.';

  @override
  String get guideAchievementsText =>
      'Today\'s and this week\'s missions, plus badges to unlock along the way.';

  @override
  String get guideHistoryTitle => 'History';

  @override
  String get guideHistoryText => 'Your latest sessions with exercise, key, octave and result.';

  @override
  String get guideLanguageText => 'Italian or English: by default I use your phone\'s language.';

  @override
  String get guideThemeText => 'System, Light, Dark or Neon: choose the look you like best.';

  @override
  String get guideNotationText => 'C D E or DO RE MI: changes the note names throughout the app.';

  @override
  String get guideReopenText =>
      'You can reopen this guide from here whenever you like. Enjoy singing!';

  @override
  String get guideTargetUnavailable =>
      'You\'ll find it here once you\'ve used this part of the app.';

  @override
  String guideNavTitle(String section) {
    return 'Go to $section';
  }

  @override
  String guideNavText(String section) {
    return 'Tap “$section” in the bar at the bottom to continue.';
  }

  @override
  String get guideTapHint => 'Tap the highlighted spot to continue';

  @override
  String get guideOpenCategoryTitle => 'Open a category';

  @override
  String get guideOpenCategoryText => 'Tap the category to see its exercises.';

  @override
  String get guideOpenExerciseTitle => 'Open an exercise';

  @override
  String get guideOpenExerciseText => 'Now tap an exercise: I\'ll show you its settings.';

  @override
  String get guideModeTitle => 'Listen or train';

  @override
  String get guideModeText =>
      'With the headphones you listen to the sequence; with the microphone you sing and I check your pitch. Then press Play.';

  @override
  String get guideAdvancedText =>
      'Speed, tolerance, how long to hold each note, the guide on every note and background noise calibration.';

  @override
  String get guideHelpTitle => 'Help in every exercise';

  @override
  String get guideHelpText => 'Tap ? in any exercise to see these explanations again.';

  @override
  String get guideBackTitle => 'Back to the exercises';

  @override
  String get guideBackText => 'Tap the arrow at the top to go back to the list of exercises.';

  @override
  String get guideOpenSettingsTitle => 'Open the settings';

  @override
  String get guideOpenSettingsText => 'Tap the gear at the top to open the settings.';
}
