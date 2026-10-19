import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('it')];

  /// Product name, never translated.
  ///
  /// In en, this message translates to:
  /// **'Intonia'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get navExercises;

  /// No description provided for @navRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get navRange;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @spanSemitones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 semitone} other{{count} semitones}}'**
  String spanSemitones(int count);

  /// No description provided for @spanOctaves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 octave} other{{count} octaves}}'**
  String spanOctaves(int count);

  /// Range width, e.g. '2 octaves + 7 semitones'. Both parts are already pluralized.
  ///
  /// In en, this message translates to:
  /// **'{octaves} + {semitones}'**
  String spanOctavesAndSemitones(String octaves, String semitones);

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'The note names (C D E or DO RE MI) are chosen separately, under Note names.'**
  String get languageHint;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get themeNeon;

  /// No description provided for @notationInternational.
  ///
  /// In en, this message translates to:
  /// **'C D E'**
  String get notationInternational;

  /// No description provided for @notationItalian.
  ///
  /// In en, this message translates to:
  /// **'DO RE MI'**
  String get notationItalian;

  /// No description provided for @trainerAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get trainerAdvancedSettings;

  /// No description provided for @trainerCurrentNote.
  ///
  /// In en, this message translates to:
  /// **'Current note'**
  String get trainerCurrentNote;

  /// No description provided for @trainerPlayCurrentNote.
  ///
  /// In en, this message translates to:
  /// **'Play the current note'**
  String get trainerPlayCurrentNote;

  /// No description provided for @trainerSessionStats.
  ///
  /// In en, this message translates to:
  /// **'Session stats'**
  String get trainerSessionStats;

  /// Followed by the note name (custom sequences).
  ///
  /// In en, this message translates to:
  /// **'Starting note:'**
  String get trainerStartingNote;

  /// No description provided for @trainerKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get trainerKey;

  /// No description provided for @trainerOctave.
  ///
  /// In en, this message translates to:
  /// **'Octave'**
  String get trainerOctave;

  /// No description provided for @trainerModeListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get trainerModeListen;

  /// No description provided for @trainerModeTrain.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainerModeTrain;

  /// No description provided for @trainerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trainerPlay;

  /// No description provided for @trainerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get trainerStop;

  /// No description provided for @trainerBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get trainerBpm;

  /// Slider caption, e.g. 'Tolerance: ± 25 cents'.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String trainerSettingValue(String label, String value);

  /// No description provided for @trainerTolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get trainerTolerance;

  /// No description provided for @trainerToleranceValue.
  ///
  /// In en, this message translates to:
  /// **'± {cents} cents'**
  String trainerToleranceValue(int cents);

  /// No description provided for @trainerStabilityTime.
  ///
  /// In en, this message translates to:
  /// **'Stability time'**
  String get trainerStabilityTime;

  /// No description provided for @trainerMilliseconds.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String trainerMilliseconds(int ms);

  /// No description provided for @trainerGuideEveryNote.
  ///
  /// In en, this message translates to:
  /// **'Play the guide note on every note'**
  String get trainerGuideEveryNote;

  /// No description provided for @trainerGuideEveryNoteHint.
  ///
  /// In en, this message translates to:
  /// **'When off, you only hear the first note: tap a note to hear it again'**
  String get trainerGuideEveryNoteHint;

  /// No description provided for @trainerLoop.
  ///
  /// In en, this message translates to:
  /// **'Loop (Listen mode only)'**
  String get trainerLoop;

  /// No description provided for @trainerCalibrate.
  ///
  /// In en, this message translates to:
  /// **'Calibrate background noise'**
  String get trainerCalibrate;

  /// No description provided for @trainerCalibrating.
  ///
  /// In en, this message translates to:
  /// **'Stay silent… (3 s)'**
  String get trainerCalibrating;

  /// No description provided for @trainerCalibrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Calibration failed: check the microphone permission.'**
  String get trainerCalibrationFailed;

  /// No description provided for @trainerCalibrationDone.
  ///
  /// In en, this message translates to:
  /// **'Calibration complete: background noise filtered out.'**
  String get trainerCalibrationDone;

  /// No description provided for @trainerStatusMicOn.
  ///
  /// In en, this message translates to:
  /// **'Microphone on'**
  String get trainerStatusMicOn;

  /// No description provided for @trainerStatusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get trainerStatusPlaying;

  /// No description provided for @trainerStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get trainerStatusReady;

  /// No description provided for @trainerMicrophoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied: enable it in your system settings to train.'**
  String get trainerMicrophoneDenied;

  /// No description provided for @trainerAudioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio could not start: check the microphone and the piano.sf2 SoundFont.'**
  String get trainerAudioUnavailable;

  /// No description provided for @trainerDetection.
  ///
  /// In en, this message translates to:
  /// **'Detection'**
  String get trainerDetection;

  /// No description provided for @trainerDetectedNote.
  ///
  /// In en, this message translates to:
  /// **'Detected note'**
  String get trainerDetectedNote;

  /// No description provided for @trainerDeviation.
  ///
  /// In en, this message translates to:
  /// **'Deviation'**
  String get trainerDeviation;

  /// Signed deviation, e.g. '+12 cents'.
  ///
  /// In en, this message translates to:
  /// **'{value} cents'**
  String trainerCentsValue(String value);

  /// No description provided for @trainerListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get trainerListening;

  /// No description provided for @trainerInTune.
  ///
  /// In en, this message translates to:
  /// **'in tune'**
  String get trainerInTune;

  /// No description provided for @trainerTooLow.
  ///
  /// In en, this message translates to:
  /// **'too low'**
  String get trainerTooLow;

  /// No description provided for @trainerTooHigh.
  ///
  /// In en, this message translates to:
  /// **'too high'**
  String get trainerTooHigh;

  /// No description provided for @trainerStatTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get trainerStatTime;

  /// No description provided for @trainerStatErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get trainerStatErrors;

  /// No description provided for @trainerStatAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get trainerStatAccuracy;

  /// No description provided for @trainerStatCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get trainerStatCorrect;

  /// No description provided for @trainerViewNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get trainerViewNotes;

  /// No description provided for @trainerViewStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get trainerViewStaff;

  /// No description provided for @trainerNoteCorrect.
  ///
  /// In en, this message translates to:
  /// **'{note}, correct'**
  String trainerNoteCorrect(String note);

  /// No description provided for @trainerNoteWrong.
  ///
  /// In en, this message translates to:
  /// **'{note}, to retry'**
  String trainerNoteWrong(String note);

  /// No description provided for @trainerNoteCurrent.
  ///
  /// In en, this message translates to:
  /// **'{note}, current note'**
  String trainerNoteCurrent(String note);

  /// No description provided for @trainerNotePending.
  ///
  /// In en, this message translates to:
  /// **'{note}, to sing'**
  String trainerNotePending(String note);

  /// No description provided for @trainerTapToHear.
  ///
  /// In en, this message translates to:
  /// **'tap to hear it'**
  String get trainerTapToHear;

  /// Screen reader label for the staff, followed by the comma-separated note names.
  ///
  /// In en, this message translates to:
  /// **'Staff: {notes}'**
  String trainerStaffSemantics(String notes);

  /// No description provided for @mascotSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Intonia mascot'**
  String get mascotSemanticLabel;

  /// No description provided for @mascotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise complete! Great job.'**
  String get mascotCompleted;

  /// No description provided for @mascotSuccess.
  ///
  /// In en, this message translates to:
  /// **'Perfect! Keep it up.'**
  String get mascotSuccess;

  /// No description provided for @mascotRetry.
  ///
  /// In en, this message translates to:
  /// **'Almost! Try again.'**
  String get mascotRetry;

  /// No description provided for @mascotListenSequence.
  ///
  /// In en, this message translates to:
  /// **'Listen closely to the sequence…'**
  String get mascotListenSequence;

  /// No description provided for @mascotSingNote.
  ///
  /// In en, this message translates to:
  /// **'Sing the note: I\'m listening.'**
  String get mascotSingNote;

  /// No description provided for @mascotIdleListen.
  ///
  /// In en, this message translates to:
  /// **'Press Play and listen to the sequence.'**
  String get mascotIdleListen;

  /// No description provided for @mascotIdleTrain.
  ///
  /// In en, this message translates to:
  /// **'Ready to train your ear?'**
  String get mascotIdleTrain;

  /// No description provided for @sessionPerfectTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get sessionPerfectTitle;

  /// No description provided for @sessionPerfectMessage.
  ///
  /// In en, this message translates to:
  /// **'No mistakes: you were perfectly in tune!'**
  String get sessionPerfectMessage;

  /// No description provided for @sessionGreatTitle.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get sessionGreatTitle;

  /// No description provided for @sessionGreatMessage.
  ///
  /// In en, this message translates to:
  /// **'Almost perfect: your ear is getting better.'**
  String get sessionGreatMessage;

  /// No description provided for @sessionGoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get sessionGoodTitle;

  /// No description provided for @sessionGoodMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re nearly there: repeat it to lock in the notes.'**
  String get sessionGoodMessage;

  /// No description provided for @sessionRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t give up!'**
  String get sessionRetryTitle;

  /// No description provided for @sessionRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Listen to the notes again and retry: you improve every round.'**
  String get sessionRetryMessage;

  /// No description provided for @sessionCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get sessionCorrect;

  /// No description provided for @sessionErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get sessionErrors;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sessionDuration;

  /// No description provided for @sessionSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String sessionSeconds(int seconds);

  /// No description provided for @sessionAccuracy.
  ///
  /// In en, this message translates to:
  /// **'accuracy'**
  String get sessionAccuracy;

  /// No description provided for @sessionAccuracySemantics.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {percent} percent'**
  String sessionAccuracySemantics(int percent);

  /// No description provided for @sessionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sessionContinue;

  /// No description provided for @sessionRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat exercise'**
  String get sessionRepeat;

  /// No description provided for @rangeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocal range'**
  String get rangeSectionTitle;

  /// No description provided for @rangeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Discover your vocal range'**
  String get rangeHeadline;

  /// No description provided for @rangeIntro.
  ///
  /// In en, this message translates to:
  /// **'Start from a comfortable note: we go down to the lowest and up to the highest note you can sing. The result stays in your profile so you can track your progress.'**
  String get rangeIntro;

  /// No description provided for @rangeStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get rangeStartTest;

  /// No description provided for @rangeRetakeTest.
  ///
  /// In en, this message translates to:
  /// **'Retake the test'**
  String get rangeRetakeTest;

  /// No description provided for @rangeNoTestsYet.
  ///
  /// In en, this message translates to:
  /// **'No tests yet: your result will appear here.'**
  String get rangeNoTestsYet;

  /// No description provided for @rangePreviousTests.
  ///
  /// In en, this message translates to:
  /// **'Previous tests'**
  String get rangePreviousTests;

  /// No description provided for @rangeHistoryInProfile.
  ///
  /// In en, this message translates to:
  /// **'Test history in your profile'**
  String get rangeHistoryInProfile;

  /// No description provided for @rangeLatestResult.
  ///
  /// In en, this message translates to:
  /// **'Latest result'**
  String get rangeLatestResult;

  /// Range width followed by the total semitones, e.g. '2 octaves + 5 semitones (29 semitones)'. span is already localized.
  ///
  /// In en, this message translates to:
  /// **'{span} ({count, plural, =1{1 semitone} other{{count} semitones}})'**
  String rangeSpanDetail(String span, int count);

  /// No description provided for @rangeLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get rangeLowest;

  /// No description provided for @rangeHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get rangeHighest;

  /// Compact signed change in semitones, e.g. '+2 st'.
  ///
  /// In en, this message translates to:
  /// **'{delta} st'**
  String rangeDeltaShort(String delta);

  /// No description provided for @rangeTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocal range test'**
  String get rangeTestTitle;

  /// No description provided for @rangeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get rangeHowItWorks;

  /// No description provided for @rangeHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start the test\" and sing a comfortable note, holding it for a moment: I\'ll recognize it and from there we go down one semitone at a time. You only move on when you hit the note; when you really can\'t reach it, tap \"Low limit reached\" (or skip that single note). Then we go up toward the high notes the same way. At the end your range is saved in your profile.'**
  String get rangeHowItWorksBody;

  /// No description provided for @rangeSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get rangeSensitivity;

  /// No description provided for @rangeTolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get rangeTolerance;

  /// No description provided for @rangeStabilityTime.
  ///
  /// In en, this message translates to:
  /// **'Stability time'**
  String get rangeStabilityTime;

  /// No description provided for @rangeCents.
  ///
  /// In en, this message translates to:
  /// **'± {cents} cents'**
  String rangeCents(int cents);

  /// No description provided for @rangeLastTestPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last test: '**
  String get rangeLastTestPrefix;

  /// No description provided for @rangeStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get rangeStartButton;

  /// No description provided for @rangeTowardLow.
  ///
  /// In en, this message translates to:
  /// **'Going down'**
  String get rangeTowardLow;

  /// No description provided for @rangeTowardHigh.
  ///
  /// In en, this message translates to:
  /// **'Going up'**
  String get rangeTowardHigh;

  /// No description provided for @rangeSingThisNote.
  ///
  /// In en, this message translates to:
  /// **'Sing this note (tap to hear it again)'**
  String get rangeSingThisNote;

  /// No description provided for @rangeValidatedSoFar.
  ///
  /// In en, this message translates to:
  /// **'Range validated so far: '**
  String get rangeValidatedSoFar;

  /// No description provided for @rangeSkipNote.
  ///
  /// In en, this message translates to:
  /// **'Skip this note'**
  String get rangeSkipNote;

  /// No description provided for @rangeLowLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Low limit reached'**
  String get rangeLowLimitReached;

  /// No description provided for @rangeHighLimitReached.
  ///
  /// In en, this message translates to:
  /// **'High limit reached'**
  String get rangeHighLimitReached;

  /// No description provided for @rangeCancelTest.
  ///
  /// In en, this message translates to:
  /// **'Cancel the test'**
  String get rangeCancelTest;

  /// No description provided for @rangeSingComfortable.
  ///
  /// In en, this message translates to:
  /// **'Sing a comfortable note and hold it'**
  String get rangeSingComfortable;

  /// No description provided for @rangeListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get rangeListening;

  /// No description provided for @rangeStartHoldHint.
  ///
  /// In en, this message translates to:
  /// **'When the bar is full, that\'s your starting note.'**
  String get rangeStartHoldHint;

  /// No description provided for @rangeYourRange.
  ///
  /// In en, this message translates to:
  /// **'Your range'**
  String get rangeYourRange;

  /// No description provided for @rangeProgressBetter.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 semitone} other{+{count} semitones}} compared to your last test'**
  String rangeProgressBetter(int count);

  /// No description provided for @rangeProgressSame.
  ///
  /// In en, this message translates to:
  /// **'Same span as your last test'**
  String get rangeProgressSame;

  /// count is the absolute number of semitones lost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{-1 semitone} other{-{count} semitones}} compared to your last test'**
  String rangeProgressWorse(int count);

  /// count is the absolute number of semitones lost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{-1 semitone} other{-{count} semitones}} compared to your last test: it happens, your voice changes from day to day'**
  String rangeProgressWorseEncouraging(int count);

  /// No description provided for @rangeSavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Result saved to your profile: the test history shows your progress over time.'**
  String get rangeSavedToProfile;

  /// No description provided for @rangeRetryTest.
  ///
  /// In en, this message translates to:
  /// **'Retry the test'**
  String get rangeRetryTest;

  /// No description provided for @rangeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get rangeContinue;

  /// No description provided for @rangeCoachValidated.
  ///
  /// In en, this message translates to:
  /// **'Great! Next note.'**
  String get rangeCoachValidated;

  /// No description provided for @rangeCoachSkipped.
  ///
  /// In en, this message translates to:
  /// **'No problem, let\'s try the next one.'**
  String get rangeCoachSkipped;

  /// No description provided for @rangeCoachSetup.
  ///
  /// In en, this message translates to:
  /// **'Start from a comfortable note: we\'ll go down toward the low notes together.'**
  String get rangeCoachSetup;

  /// No description provided for @rangeCoachFindingStart.
  ///
  /// In en, this message translates to:
  /// **'Sing a comfortable note and hold it: I\'ll recognize it.'**
  String get rangeCoachFindingStart;

  /// No description provided for @rangeCoachDescending.
  ///
  /// In en, this message translates to:
  /// **'Sing the note: we\'re heading down.'**
  String get rangeCoachDescending;

  /// No description provided for @rangeCoachAscending.
  ///
  /// In en, this message translates to:
  /// **'Now let\'s go up toward the high notes!'**
  String get rangeCoachAscending;

  /// No description provided for @rangeCoachDone.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your range! Great job.'**
  String get rangeCoachDone;

  /// No description provided for @rangeCoachRetry.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try again starting from a more comfortable note.'**
  String get rangeCoachRetry;

  /// No description provided for @rangeMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied: enable it in your system settings.'**
  String get rangeMicDenied;

  /// No description provided for @rangeAudioInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio not initialized: check the microphone and the SoundFont.'**
  String get rangeAudioInitFailed;

  /// No description provided for @rangeNothingValidated.
  ///
  /// In en, this message translates to:
  /// **'No notes validated: the test was not saved.'**
  String get rangeNothingValidated;

  /// No description provided for @rangeResultFirst.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your vocal range!'**
  String get rangeResultFirst;

  /// No description provided for @rangeResultBetter.
  ///
  /// In en, this message translates to:
  /// **'New record!'**
  String get rangeResultBetter;

  /// No description provided for @rangeResultSame.
  ///
  /// In en, this message translates to:
  /// **'Range confirmed!'**
  String get rangeResultSame;

  /// No description provided for @rangeResultWorse.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your range today'**
  String get rangeResultWorse;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettingsTooltip;

  /// No description provided for @profileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get profileEmptyTitle;

  /// No description provided for @profileEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a workout: here you\'ll find your streak, accuracy, vocal range and history.'**
  String get profileEmptyBody;

  /// No description provided for @profileStatSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get profileStatSessions;

  /// No description provided for @profileStatMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total minutes'**
  String get profileStatMinutes;

  /// No description provided for @profileStatAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Average accuracy'**
  String get profileStatAccuracy;

  /// No description provided for @profileStatRange.
  ///
  /// In en, this message translates to:
  /// **'Vocal range'**
  String get profileStatRange;

  /// No description provided for @profileBestWorstNotes.
  ///
  /// In en, this message translates to:
  /// **'Best and worst notes'**
  String get profileBestWorstNotes;

  /// No description provided for @profileRangeTests.
  ///
  /// In en, this message translates to:
  /// **'Vocal range tests'**
  String get profileRangeTests;

  /// No description provided for @profileRangeDeltaUp.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 semitone} other{+{count} semitones}} vs. previous'**
  String profileRangeDeltaUp(int count);

  /// count is the absolute number of semitones lost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{-1 semitone} other{-{count} semitones}} vs. previous'**
  String profileRangeDeltaDown(int count);

  /// No description provided for @profileRangeUnchanged.
  ///
  /// In en, this message translates to:
  /// **'unchanged'**
  String get profileRangeUnchanged;

  /// No description provided for @profileDeleteRangeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete test'**
  String get profileDeleteRangeTooltip;

  /// No description provided for @profileDeleteSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get profileDeleteSessionTooltip;

  /// No description provided for @profileAllSessions.
  ///
  /// In en, this message translates to:
  /// **'All sessions'**
  String get profileAllSessions;

  /// No description provided for @profileRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get profileRecentSessions;

  /// No description provided for @profileFullHistoryPro.
  ///
  /// In en, this message translates to:
  /// **'Full history ({count, plural, =1{1 session} other{{count} sessions}}) with Intonia Pro'**
  String profileFullHistoryPro(int count);

  /// No description provided for @profileDeleteRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this test?'**
  String get profileDeleteRangeTitle;

  /// No description provided for @profileDeleteRangeBody.
  ///
  /// In en, this message translates to:
  /// **'The test from {date} will be removed.'**
  String profileDeleteRangeBody(String date);

  /// No description provided for @profileDeleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get profileDeleteSessionTitle;

  /// No description provided for @profileDeleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" from {date} will be removed from your stats, streak and vocal range.'**
  String profileDeleteSessionBody(String name, String date);

  /// No description provided for @profileStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String profileStreakDays(int count);

  /// No description provided for @profileStreakStart.
  ///
  /// In en, this message translates to:
  /// **'Practice today to start your streak!'**
  String get profileStreakStart;

  /// No description provided for @profileStreakKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it up, don\'t break it!'**
  String get profileStreakKeep;

  /// No description provided for @exerciseNameTriadMajor.
  ///
  /// In en, this message translates to:
  /// **'Major triad'**
  String get exerciseNameTriadMajor;

  /// No description provided for @exerciseNameTriadMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor triad'**
  String get exerciseNameTriadMinor;

  /// No description provided for @exerciseNameTriadAugmented.
  ///
  /// In en, this message translates to:
  /// **'Augmented triad'**
  String get exerciseNameTriadAugmented;

  /// No description provided for @exerciseNameTriadDiminished.
  ///
  /// In en, this message translates to:
  /// **'Diminished triad'**
  String get exerciseNameTriadDiminished;

  /// No description provided for @exerciseNameArpeggioMajorOctave.
  ///
  /// In en, this message translates to:
  /// **'Major arpeggio (octave)'**
  String get exerciseNameArpeggioMajorOctave;

  /// No description provided for @exerciseNameArpeggioMinorOctave.
  ///
  /// In en, this message translates to:
  /// **'Minor arpeggio (octave)'**
  String get exerciseNameArpeggioMinorOctave;

  /// No description provided for @exerciseNameMajorPentatonic.
  ///
  /// In en, this message translates to:
  /// **'Major pentatonic'**
  String get exerciseNameMajorPentatonic;

  /// No description provided for @exerciseNameMinorPentatonic.
  ///
  /// In en, this message translates to:
  /// **'Minor pentatonic'**
  String get exerciseNameMinorPentatonic;

  /// No description provided for @exerciseNameMajor.
  ///
  /// In en, this message translates to:
  /// **'Major scale'**
  String get exerciseNameMajor;

  /// No description provided for @exerciseNameNaturalMinor.
  ///
  /// In en, this message translates to:
  /// **'Natural minor scale'**
  String get exerciseNameNaturalMinor;

  /// No description provided for @exerciseNameHarmonicMinor.
  ///
  /// In en, this message translates to:
  /// **'Harmonic minor scale'**
  String get exerciseNameHarmonicMinor;

  /// No description provided for @exerciseNameMelodicMinor.
  ///
  /// In en, this message translates to:
  /// **'Melodic minor scale'**
  String get exerciseNameMelodicMinor;

  /// No description provided for @exerciseNameBlues.
  ///
  /// In en, this message translates to:
  /// **'Blues scale'**
  String get exerciseNameBlues;

  /// No description provided for @exerciseNameHarmonizedMajor.
  ///
  /// In en, this message translates to:
  /// **'Harmonized major scale'**
  String get exerciseNameHarmonizedMajor;

  /// No description provided for @exerciseNameHarmonizedNaturalMinor.
  ///
  /// In en, this message translates to:
  /// **'Harmonized natural minor scale'**
  String get exerciseNameHarmonizedNaturalMinor;

  /// No description provided for @exerciseNameHarmonizedHarmonicMinor.
  ///
  /// In en, this message translates to:
  /// **'Harmonized harmonic minor scale'**
  String get exerciseNameHarmonizedHarmonicMinor;

  /// No description provided for @exerciseNameHarmonizedMelodicMinor.
  ///
  /// In en, this message translates to:
  /// **'Harmonized melodic minor scale'**
  String get exerciseNameHarmonizedMelodicMinor;

  /// No description provided for @exerciseNameFiveNotePattern.
  ///
  /// In en, this message translates to:
  /// **'5-note pattern (1-2-3-4-5)'**
  String get exerciseNameFiveNotePattern;

  /// No description provided for @exerciseNameThirdLeaps.
  ///
  /// In en, this message translates to:
  /// **'Leaps in thirds (1-3, 2-4...)'**
  String get exerciseNameThirdLeaps;

  /// No description provided for @categoryLabelCustom.
  ///
  /// In en, this message translates to:
  /// **'Your sequences'**
  String get categoryLabelCustom;

  /// No description provided for @categoryDescriptionCustom.
  ///
  /// In en, this message translates to:
  /// **'Create and practice your own custom sequences'**
  String get categoryDescriptionCustom;

  /// No description provided for @categoryLabelTriads.
  ///
  /// In en, this message translates to:
  /// **'Triads'**
  String get categoryLabelTriads;

  /// No description provided for @categoryDescriptionTriads.
  ///
  /// In en, this message translates to:
  /// **'Major, minor, augmented and diminished'**
  String get categoryDescriptionTriads;

  /// No description provided for @categoryLabelArpeggios.
  ///
  /// In en, this message translates to:
  /// **'Arpeggios'**
  String get categoryLabelArpeggios;

  /// No description provided for @categoryDescriptionArpeggios.
  ///
  /// In en, this message translates to:
  /// **'Triads extended to the octave'**
  String get categoryDescriptionArpeggios;

  /// No description provided for @categoryLabelPentatonics.
  ///
  /// In en, this message translates to:
  /// **'Pentatonic scales'**
  String get categoryLabelPentatonics;

  /// No description provided for @categoryDescriptionPentatonics.
  ///
  /// In en, this message translates to:
  /// **'Major and minor'**
  String get categoryDescriptionPentatonics;

  /// No description provided for @categoryLabelScales.
  ///
  /// In en, this message translates to:
  /// **'Scales'**
  String get categoryLabelScales;

  /// No description provided for @categoryDescriptionScales.
  ///
  /// In en, this message translates to:
  /// **'Major, minor and blues'**
  String get categoryDescriptionScales;

  /// No description provided for @categoryLabelHarmonizations.
  ///
  /// In en, this message translates to:
  /// **'Three-part harmonies'**
  String get categoryLabelHarmonizations;

  /// No description provided for @categoryDescriptionHarmonizations.
  ///
  /// In en, this message translates to:
  /// **'Diatonic triads on every scale degree'**
  String get categoryDescriptionHarmonizations;

  /// No description provided for @categoryLabelPatterns.
  ///
  /// In en, this message translates to:
  /// **'Patterns'**
  String get categoryLabelPatterns;

  /// No description provided for @categoryDescriptionPatterns.
  ///
  /// In en, this message translates to:
  /// **'Melodic warm-up sequences'**
  String get categoryDescriptionPatterns;

  /// No description provided for @focusAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get focusAccuracy;

  /// No description provided for @focusEar.
  ///
  /// In en, this message translates to:
  /// **'Ear training'**
  String get focusEar;

  /// No description provided for @focusAgility.
  ///
  /// In en, this message translates to:
  /// **'Agility'**
  String get focusAgility;

  /// No description provided for @focusControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get focusControl;

  /// No description provided for @focusRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get focusRange;

  /// No description provided for @editorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New sequence'**
  String get editorTitleNew;

  /// No description provided for @editorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit sequence'**
  String get editorTitleEdit;

  /// No description provided for @editorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editorNameLabel;

  /// No description provided for @editorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Octave sirens / Vocalise 1-3-5-8'**
  String get editorNameHint;

  /// No description provided for @editorGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get editorGroupLabel;

  /// No description provided for @editorGroupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Warm-up, Lesson 3…'**
  String get editorGroupHint;

  /// No description provided for @editorTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag (optional)'**
  String get editorTagLabel;

  /// No description provided for @editorAddNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add notes'**
  String get editorAddNotesTitle;

  /// No description provided for @editorAddNotesHint.
  ///
  /// In en, this message translates to:
  /// **'You can start from any note, repeat the same note and go below the first one. In the trainer you can still transpose the whole sequence.'**
  String get editorAddNotesHint;

  /// Short label of the octave selector in the note picker.
  ///
  /// In en, this message translates to:
  /// **'Oct. {octave}'**
  String editorOctaveShort(int octave);

  /// No description provided for @editorSequenceTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sequence (1 note)} other{Sequence ({count} notes)}}'**
  String editorSequenceTitle(int count);

  /// No description provided for @editorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// No description provided for @editorRemoveLast.
  ///
  /// In en, this message translates to:
  /// **'Remove last note'**
  String get editorRemoveLast;

  /// No description provided for @editorEmptySequence.
  ///
  /// In en, this message translates to:
  /// **'Tap the notes above to build the sequence.'**
  String get editorEmptySequence;

  /// No description provided for @editorErrorNoName.
  ///
  /// In en, this message translates to:
  /// **'Give the sequence a name.'**
  String get editorErrorNoName;

  /// No description provided for @editorErrorTooFewNotes.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 notes.'**
  String get editorErrorTooFewNotes;

  /// No description provided for @editorAudioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable: check the piano.sf2 SoundFont.'**
  String get editorAudioUnavailable;

  /// No description provided for @editorProTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your sequence'**
  String get editorProTitle;

  /// No description provided for @editorProHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your sequences, made to measure'**
  String get editorProHeadline;

  /// No description provided for @editorProBody.
  ///
  /// In en, this message translates to:
  /// **'Compose any run of notes, starting from any note you like: vocalises, patterns, leaps, range work. Sequences are saved on the Home screen, grouped the way you prefer, and you practice them just like the built-in exercises.'**
  String get editorProBody;

  /// No description provided for @editorProNote.
  ///
  /// In en, this message translates to:
  /// **'Creating, editing and saving sequences is an Intonia Pro feature. Sequences you have already saved remain available.'**
  String get editorProNote;

  /// No description provided for @editorProCta.
  ///
  /// In en, this message translates to:
  /// **'Discover Intonia Pro'**
  String get editorProCta;

  /// Screen reader label of a note name with its octave, e.g. 'C, octave 4'.
  ///
  /// In en, this message translates to:
  /// **'{note}, octave {octave}'**
  String noteSemanticsLabel(String note, int octave);

  /// Screen reader label of the streak pill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Streak: 1 day in a row} other{Streak: {count} days in a row}}'**
  String statusStreakSemantics(int count);

  /// Mascot speech bubble. Must fit two short lines.
  ///
  /// In en, this message translates to:
  /// **'Sing or play a note: I\'ll tell you which one!'**
  String get homeBubbleIdle;

  /// Mascot speech bubble. Must fit two short lines.
  ///
  /// In en, this message translates to:
  /// **'I\'m listening… sing or play a note.'**
  String get homeBubbleListening;

  /// No description provided for @homeBubbleInTune.
  ///
  /// In en, this message translates to:
  /// **'Perfectly in tune!'**
  String get homeBubbleInTune;

  /// No description provided for @homeBubbleAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there: adjust just a little.'**
  String get homeBubbleAlmost;

  /// Mascot speech bubble. Must fit two short lines.
  ///
  /// In en, this message translates to:
  /// **'Microphone access denied: enable it in Settings.'**
  String get homeBubblePermissionDenied;

  /// No description provided for @homeStartListening.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get homeStartListening;

  /// No description provided for @homeStopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get homeStopListening;

  /// No description provided for @homeMicStartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Start live note detection'**
  String get homeMicStartSemantics;

  /// No description provided for @homeMicStopSemantics.
  ///
  /// In en, this message translates to:
  /// **'Stop note detection'**
  String get homeMicStopSemantics;

  /// No description provided for @homeNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Here you\'ll see the detected note and how in tune you are.'**
  String get homeNotePlaceholder;

  /// No description provided for @homeNoteDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected note'**
  String get homeNoteDetected;

  /// No description provided for @homeLastNote.
  ///
  /// In en, this message translates to:
  /// **'Last note'**
  String get homeLastNote;

  /// No description provided for @homeDeviation.
  ///
  /// In en, this message translates to:
  /// **'Deviation'**
  String get homeDeviation;

  /// Signed deviation in cents, e.g. '+3 cents'.
  ///
  /// In en, this message translates to:
  /// **'{value} cents'**
  String homeCents(String value);

  /// No description provided for @homeQuickNotation.
  ///
  /// In en, this message translates to:
  /// **'Notation'**
  String get homeQuickNotation;

  /// No description provided for @homeQuickTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get homeQuickTheme;

  /// No description provided for @homeQuickSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeQuickSettings;

  /// No description provided for @exercisesCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get exercisesCategories;

  /// No description provided for @exercisesSequenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sequence} other{{count} sequences}}'**
  String exercisesSequenceCount(int count);

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exercisesCount(int count);

  /// No description provided for @exercisesNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String exercisesNoteCount(int count);

  /// No description provided for @exercisesProBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get exercisesProBadge;

  /// No description provided for @exercisesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get exercisesEdit;

  /// No description provided for @exercisesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this sequence?'**
  String get exercisesDeleteTitle;

  /// No description provided for @exercisesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be permanently removed.'**
  String exercisesDeleteMessage(String name);

  /// No description provided for @exercisesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your sequence'**
  String get exercisesCreateTitle;

  /// No description provided for @exercisesCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compose any run of notes: patterns, vocal warm-ups, range drills…'**
  String get exercisesCreateSubtitle;

  /// No description provided for @chargesProSemantics.
  ///
  /// In en, this message translates to:
  /// **'Intonia Pro: unlimited exercises'**
  String get chargesProSemantics;

  /// No description provided for @chargesProDeveloperSemantics.
  ///
  /// In en, this message translates to:
  /// **'Intonia Pro, developer build: unlimited exercises'**
  String get chargesProDeveloperSemantics;

  /// No description provided for @chargesChipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Exercise charges: {count} of {max}'**
  String chargesChipSemantics(int count, int max);

  /// No description provided for @chargesWaitUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'less than 1 min'**
  String get chargesWaitUnderMinute;

  /// No description provided for @chargesWaitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String chargesWaitMinutes(int minutes);

  /// No description provided for @chargesWaitHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String chargesWaitHours(int hours);

  /// No description provided for @chargesWaitHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String chargesWaitHoursMinutes(int hours, int minutes);

  /// No description provided for @chargesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise charges'**
  String get chargesTitle;

  /// No description provided for @chargesExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of charges'**
  String get chargesExhaustedTitle;

  /// No description provided for @chargesNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next charge in {wait}.'**
  String chargesNextIn(String wait);

  /// No description provided for @chargesExplanation.
  ///
  /// In en, this message translates to:
  /// **'Each exercise session uses one charge. {hours, plural, =1{One comes back every hour} other{One comes back every {hours} hours}}, even with the app closed, up to {max}.'**
  String chargesExplanation(int hours, int max);

  /// No description provided for @chargesFreeFeatures.
  ///
  /// In en, this message translates to:
  /// **'Live note detection and the vocal range test are always free and unlimited.'**
  String get chargesFreeFeatures;

  /// No description provided for @chargesDiscoverPro.
  ///
  /// In en, this message translates to:
  /// **'Discover Intonia Pro'**
  String get chargesDiscoverPro;

  /// No description provided for @chargesWaitForRecharge.
  ///
  /// In en, this message translates to:
  /// **'I\'ll wait for a recharge'**
  String get chargesWaitForRecharge;

  /// No description provided for @chargesHint.
  ///
  /// In en, this message translates to:
  /// **'Each session uses 1 charge · {count}/{max} available'**
  String chargesHint(int count, int max);

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Intonia Pro'**
  String get proTitle;

  /// No description provided for @proHeadlinePro.
  ///
  /// In en, this message translates to:
  /// **'You have Intonia Pro'**
  String get proHeadlinePro;

  /// No description provided for @proHeadlineFree.
  ///
  /// In en, this message translates to:
  /// **'Train without limits'**
  String get proHeadlineFree;

  /// No description provided for @proDeveloperNote.
  ///
  /// In en, this message translates to:
  /// **'Developer build: Pro active without a subscription.'**
  String get proDeveloperNote;

  /// No description provided for @proBenefitUnlimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited exercises'**
  String get proBenefitUnlimitedTitle;

  /// No description provided for @proBenefitUnlimitedText.
  ///
  /// In en, this message translates to:
  /// **'No charges: as many sessions as you like.'**
  String get proBenefitUnlimitedText;

  /// No description provided for @proBenefitCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom sequences'**
  String get proBenefitCustomTitle;

  /// No description provided for @proBenefitCustomText.
  ///
  /// In en, this message translates to:
  /// **'Create, edit and save your own exercises.'**
  String get proBenefitCustomText;

  /// No description provided for @proBenefitHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Full history'**
  String get proBenefitHistoryTitle;

  /// No description provided for @proBenefitHistoryText.
  ///
  /// In en, this message translates to:
  /// **'All your sessions in your profile.'**
  String get proBenefitHistoryText;

  /// No description provided for @proBenefitComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get proBenefitComingTitle;

  /// No description provided for @proBenefitComingText.
  ///
  /// In en, this message translates to:
  /// **'Advanced statistics, progress charts and personalized paths.'**
  String get proBenefitComingText;

  /// No description provided for @proFreeForever.
  ///
  /// In en, this message translates to:
  /// **'Free forever: live note detection, the vocal range test, every exercise with {max} recharging charges, profile, essential stats and daily streak.'**
  String proFreeForever(int max);

  /// No description provided for @proPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get proPlanMonthly;

  /// No description provided for @proPlanYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get proPlanYearly;

  /// Indicative price, formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'€4.99'**
  String get proPriceMonthly;

  /// Indicative price, formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'€39.99'**
  String get proPriceYearly;

  /// No description provided for @proPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get proPeriodMonth;

  /// No description provided for @proPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get proPeriodYear;

  /// No description provided for @proYearlySaving.
  ///
  /// In en, this message translates to:
  /// **'Save 33%'**
  String get proYearlySaving;

  /// No description provided for @proSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get proSubscribe;

  /// No description provided for @proComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions will be available soon through the App Store and Google Play.'**
  String get proComingSoon;

  /// No description provided for @proRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get proRestore;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsNotation.
  ///
  /// In en, this message translates to:
  /// **'Note names'**
  String get settingsNotation;

  /// No description provided for @settingsInfo.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsInfo;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'Intonia {version} — offline pitch training.'**
  String settingsAbout(String version);

  /// No description provided for @settingsSoundCredit.
  ///
  /// In en, this message translates to:
  /// **'Piano sound: Fluid (R3) SoundFont, © 2000–2002, 2008 Frank Wen, MIT license.'**
  String get settingsSoundCredit;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// No description provided for @trainerDirectionForward.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get trainerDirectionForward;

  /// No description provided for @trainerDirectionReverse.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get trainerDirectionReverse;

  /// No description provided for @trainerDirectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get trainerDirectionComplete;

  /// No description provided for @trainerRepeatTop.
  ///
  /// In en, this message translates to:
  /// **'Repeat the top note'**
  String get trainerRepeatTop;

  /// No description provided for @trainerRepeatTopHint.
  ///
  /// In en, this message translates to:
  /// **'Repeats the highest note before going down'**
  String get trainerRepeatTopHint;

  /// No description provided for @exercisesCreateFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Start from scratch'**
  String get exercisesCreateFromScratch;

  /// No description provided for @exercisesCreateFromExercise.
  ///
  /// In en, this message translates to:
  /// **'Start from an exercise'**
  String get exercisesCreateFromExercise;

  /// No description provided for @exercisesCreateFromExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'Copy an exercise and edit it freely'**
  String get exercisesCreateFromExerciseHint;

  /// No description provided for @profileSessionKeyOctave.
  ///
  /// In en, this message translates to:
  /// **'{key} · Octave {octave}'**
  String profileSessionKeyOctave(String key, int octave);

  /// No description provided for @profileSessionTopRepeated.
  ///
  /// In en, this message translates to:
  /// **'top note repeated'**
  String get profileSessionTopRepeated;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Intonia guide'**
  String get guideTitle;

  /// No description provided for @guideOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Replay the tour of the app\'s features'**
  String get guideOpenHint;

  /// No description provided for @guideNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideNext;

  /// No description provided for @guideDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guideDone;

  /// No description provided for @guideSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guideSkip;

  /// No description provided for @guideProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String guideProgress(int current, int total);

  /// No description provided for @guideKey.
  ///
  /// In en, this message translates to:
  /// **'The note the exercise starts from.'**
  String get guideKey;

  /// No description provided for @guideOctave.
  ///
  /// In en, this message translates to:
  /// **'How high or low the exercise is: pick one that\'s comfortable for your voice.'**
  String get guideOctave;

  /// No description provided for @guideDirectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get guideDirectionTitle;

  /// No description provided for @guideDirection.
  ///
  /// In en, this message translates to:
  /// **'Ascending plays the sequence from the bottom up, Descending from the top down, Full goes up and then comes back down.'**
  String get guideDirection;

  /// No description provided for @guideRepeatTop.
  ///
  /// In en, this message translates to:
  /// **'Only in Full mode: you sing the highest note twice before going down.'**
  String get guideRepeatTop;

  /// No description provided for @rangeNotMine.
  ///
  /// In en, this message translates to:
  /// **'Not me'**
  String get rangeNotMine;

  /// No description provided for @rangeNotMineResult.
  ///
  /// In en, this message translates to:
  /// **'It wasn\'t me: remove this test'**
  String get rangeNotMineResult;

  /// No description provided for @rangeNotMineTitle.
  ///
  /// In en, this message translates to:
  /// **'Not your test?'**
  String get rangeNotMineTitle;

  /// No description provided for @rangeNotMineBody.
  ///
  /// In en, this message translates to:
  /// **'The test from {date} will be removed from your results and history.'**
  String rangeNotMineBody(String date);

  /// No description provided for @rangeNotMineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get rangeNotMineConfirm;

  /// No description provided for @tessituraTitle.
  ///
  /// In en, this message translates to:
  /// **'Comfort zone test'**
  String get tessituraTitle;

  /// No description provided for @tessituraSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comfort zone (tessitura)'**
  String get tessituraSectionTitle;

  /// No description provided for @tessituraSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Not your highest or lowest note: the part of your voice where singing feels easy.'**
  String get tessituraSectionIntro;

  /// No description provided for @tessituraStart.
  ///
  /// In en, this message translates to:
  /// **'Find your comfort zone'**
  String get tessituraStart;

  /// No description provided for @tessituraRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake the comfort zone test'**
  String get tessituraRetake;

  /// No description provided for @tessituraHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'You sing short phrases that go up and come back down (about 3–5 minutes). After each one, tell me how comfortable it felt. I also listen to how steady and centred each note is and whether you can hold it, but your answer counts the most.'**
  String get tessituraHowItWorks;

  /// No description provided for @tessituraUsesRange.
  ///
  /// In en, this message translates to:
  /// **'I start from your latest range test and move up and down from there.'**
  String get tessituraUsesRange;

  /// No description provided for @tessituraNoRange.
  ///
  /// In en, this message translates to:
  /// **'No range test yet: you\'ll start by holding a comfortable note. A range test first gives a more reliable map.'**
  String get tessituraNoRange;

  /// No description provided for @tessituraNotAClassification.
  ///
  /// In en, this message translates to:
  /// **'This is an estimate for practice, not a voice type (soprano, alto, tenor, bass) and not a medical assessment.'**
  String get tessituraNotAClassification;

  /// No description provided for @tessituraCoachIntro.
  ///
  /// In en, this message translates to:
  /// **'Let\'s find where your voice feels at home!'**
  String get tessituraCoachIntro;

  /// No description provided for @tessituraCoachFindStart.
  ///
  /// In en, this message translates to:
  /// **'Hold a note that feels easy.'**
  String get tessituraCoachFindStart;

  /// No description provided for @tessituraCoachSing.
  ///
  /// In en, this message translates to:
  /// **'Sing along, no need to push.'**
  String get tessituraCoachSing;

  /// No description provided for @tessituraCoachSustain.
  ///
  /// In en, this message translates to:
  /// **'Now hold it steady…'**
  String get tessituraCoachSustain;

  /// No description provided for @tessituraCoachRate.
  ///
  /// In en, this message translates to:
  /// **'How did that one feel?'**
  String get tessituraCoachRate;

  /// No description provided for @tessituraCoachDone.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your comfort zone!'**
  String get tessituraCoachDone;

  /// No description provided for @tessituraCoachProvisional.
  ///
  /// In en, this message translates to:
  /// **'A first estimate: repeat the test to make it more precise.'**
  String get tessituraCoachProvisional;

  /// No description provided for @tessituraTrial.
  ///
  /// In en, this message translates to:
  /// **'Phrase {number}'**
  String tessituraTrial(int number);

  /// No description provided for @tessituraHoldNote.
  ///
  /// In en, this message translates to:
  /// **'Hold this note'**
  String get tessituraHoldNote;

  /// No description provided for @tessituraFinishNow.
  ///
  /// In en, this message translates to:
  /// **'Finish now'**
  String get tessituraFinishNow;

  /// No description provided for @tessituraCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tessituraCancel;

  /// No description provided for @tessituraRateQuestion.
  ///
  /// In en, this message translates to:
  /// **'How comfortable was it to sing?'**
  String get tessituraRateQuestion;

  /// No description provided for @tessituraRateEasy.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get tessituraRateEasy;

  /// No description provided for @tessituraRateEffort.
  ///
  /// In en, this message translates to:
  /// **'A bit of effort'**
  String get tessituraRateEffort;

  /// No description provided for @tessituraRateHard.
  ///
  /// In en, this message translates to:
  /// **'Hard or strained'**
  String get tessituraRateHard;

  /// No description provided for @tessituraRateFailed.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t sing it'**
  String get tessituraRateFailed;

  /// No description provided for @tessituraComfortZone.
  ///
  /// In en, this message translates to:
  /// **'Comfort zone'**
  String get tessituraComfortZone;

  /// No description provided for @tessituraNoZone.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get tessituraNoZone;

  /// No description provided for @tessituraMaxRange.
  ///
  /// In en, this message translates to:
  /// **'Maximum range'**
  String get tessituraMaxRange;

  /// No description provided for @tessituraToVerify.
  ///
  /// In en, this message translates to:
  /// **'To verify'**
  String get tessituraToVerify;

  /// No description provided for @tessituraReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability: {level}'**
  String tessituraReliability(String level);

  /// No description provided for @tessituraReliabilityLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get tessituraReliabilityLow;

  /// No description provided for @tessituraReliabilityMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get tessituraReliabilityMedium;

  /// No description provided for @tessituraReliabilityHigh.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get tessituraReliabilityHigh;

  /// No description provided for @tessituraProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional estimate'**
  String get tessituraProvisional;

  /// No description provided for @tessituraLastResult.
  ///
  /// In en, this message translates to:
  /// **'Last result'**
  String get tessituraLastResult;

  /// No description provided for @tessituraCompareSame.
  ///
  /// In en, this message translates to:
  /// **'Same width as on {date}.'**
  String tessituraCompareSame(String date);

  /// No description provided for @tessituraCompareDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} semitones compared with {date}.'**
  String tessituraCompareDelta(String date, String delta);

  /// No description provided for @tessituraLegend.
  ///
  /// In en, this message translates to:
  /// **'Coloured band: comfort zone. Light band: maximum range. Dots: notes to check again (uncertain or inconsistent results). The estimate is indicative and can change with the day, warm-up and tiredness.'**
  String get tessituraLegend;

  /// No description provided for @workoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily workout'**
  String get workoutTitle;

  /// No description provided for @workoutGoal.
  ///
  /// In en, this message translates to:
  /// **'A ready-made session with the exercises you already know: a warm-up, a few main exercises and a final review. When there is enough data it also brings back the exercises you find hardest.'**
  String get workoutGoal;

  /// No description provided for @workoutCoachReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for today\'s session?'**
  String get workoutCoachReady;

  /// No description provided for @workoutCoachDone.
  ///
  /// In en, this message translates to:
  /// **'Workout done, well done!'**
  String get workoutCoachDone;

  /// No description provided for @workoutCoachPartial.
  ///
  /// In en, this message translates to:
  /// **'Good work: next time try the ones you skipped.'**
  String get workoutCoachPartial;

  /// No description provided for @workoutDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutDurationLabel;

  /// No description provided for @workoutMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String workoutMinutes(int minutes);

  /// No description provided for @workoutSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min · {count, plural, =1{1 exercise} other{{count} exercises}}'**
  String workoutSummaryLine(int minutes, int count);

  /// No description provided for @workoutBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced routine: there isn\'t enough data on your sessions yet.'**
  String get workoutBalanced;

  /// No description provided for @workoutPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Based on your previous sessions.'**
  String get workoutPersonalized;

  /// No description provided for @workoutPersonalizedHard.
  ///
  /// In en, this message translates to:
  /// **'Based on your previous sessions, with {count, plural, =1{1 exercise} other{{count} exercises}} to review.'**
  String workoutPersonalizedHard(int count);

  /// No description provided for @workoutDurationNote.
  ///
  /// In en, this message translates to:
  /// **'Times are indicative: they come from your previous sessions or, if there are none, from the number of notes.'**
  String get workoutDurationNote;

  /// No description provided for @workoutChargesNote.
  ///
  /// In en, this message translates to:
  /// **'Each exercise uses 1 charge, like the other exercises ({count} exercises, you have {available}).'**
  String workoutChargesNote(int count, int available);

  /// No description provided for @workoutStart.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutStart;

  /// No description provided for @workoutRoleWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get workoutRoleWarmUp;

  /// No description provided for @workoutRoleMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get workoutRoleMain;

  /// No description provided for @workoutRoleReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get workoutRoleReview;

  /// No description provided for @workoutDifficultTag.
  ///
  /// In en, this message translates to:
  /// **'to practise'**
  String get workoutDifficultTag;

  /// No description provided for @workoutDifficultReason.
  ///
  /// In en, this message translates to:
  /// **'Chosen because it was harder for you in recent sessions.'**
  String get workoutDifficultReason;

  /// No description provided for @workoutApproxMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String workoutApproxMinutes(int minutes);

  /// No description provided for @workoutApproxSeconds.
  ///
  /// In en, this message translates to:
  /// **'~{seconds} s'**
  String workoutApproxSeconds(int seconds);

  /// No description provided for @workoutProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String workoutProgress(int done, int total);

  /// No description provided for @workoutRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Last one done} =1{1 exercise left} other{{count} exercises left}}'**
  String workoutRemaining(int count);

  /// No description provided for @workoutStepOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String workoutStepOf(int index, int total);

  /// No description provided for @workoutOpenStep.
  ///
  /// In en, this message translates to:
  /// **'Start this exercise'**
  String get workoutOpenStep;

  /// No description provided for @workoutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get workoutSkip;

  /// No description provided for @workoutSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get workoutSkipped;

  /// No description provided for @workoutInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Stop workout'**
  String get workoutInterrupt;

  /// No description provided for @workoutInterruptTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the workout?'**
  String get workoutInterruptTitle;

  /// No description provided for @workoutInterruptBody.
  ///
  /// In en, this message translates to:
  /// **'It will be saved as interrupted, not completed. The exercises you finished stay in your history.'**
  String get workoutInterruptBody;

  /// No description provided for @workoutKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get workoutKeepGoing;

  /// No description provided for @workoutCompleted.
  ///
  /// In en, this message translates to:
  /// **'Workout completed'**
  String get workoutCompleted;

  /// No description provided for @workoutPartial.
  ///
  /// In en, this message translates to:
  /// **'Workout finished with some skips'**
  String get workoutPartial;

  /// No description provided for @workoutDoneLine.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} exercises completed'**
  String workoutDoneLine(int done, int total);

  /// No description provided for @workoutAccuracyLine.
  ///
  /// In en, this message translates to:
  /// **'Overall accuracy: {percent}%'**
  String workoutAccuracyLine(int percent);

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress: {done} of {total}'**
  String workoutInProgress(int done, int total);

  /// No description provided for @workoutDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get workoutDoneToday;

  /// No description provided for @workoutPartialToday.
  ///
  /// In en, this message translates to:
  /// **'Done today: {done} of {total}'**
  String workoutPartialToday(int done, int total);

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals and badges'**
  String get achievementsTitle;

  /// No description provided for @achievementsCoach.
  ///
  /// In en, this message translates to:
  /// **'Every small step counts!'**
  String get achievementsCoach;

  /// No description provided for @achievementsStreakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get achievementsStreakCurrent;

  /// No description provided for @achievementsStreakBest.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get achievementsStreakBest;

  /// No description provided for @achievementsBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get achievementsBadges;

  /// No description provided for @achievementsDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String achievementsDays(int count);

  /// No description provided for @achievementsBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total}'**
  String achievementsBadgeCount(int unlocked, int total);

  /// No description provided for @achievementsDaily.
  ///
  /// In en, this message translates to:
  /// **'Today\'s missions'**
  String get achievementsDaily;

  /// No description provided for @achievementsDailyHint.
  ///
  /// In en, this message translates to:
  /// **'New missions every day at midnight.'**
  String get achievementsDailyHint;

  /// No description provided for @achievementsWeekly.
  ///
  /// In en, this message translates to:
  /// **'This week\'s missions'**
  String get achievementsWeekly;

  /// No description provided for @achievementsWeeklyHint.
  ///
  /// In en, this message translates to:
  /// **'Until Sunday {date}.'**
  String achievementsWeeklyHint(DateTime date);

  /// No description provided for @achievementsMissionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get achievementsMissionDone;

  /// No description provided for @achievementsProgress.
  ///
  /// In en, this message translates to:
  /// **'{value} of {target}'**
  String achievementsProgress(int value, int target);

  /// No description provided for @achievementsUnlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String achievementsUnlockedOn(DateTime date);

  /// No description provided for @achievementsLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementsLocked;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementsUnlocked;

  /// No description provided for @achievementsToastTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocked!'**
  String get achievementsToastTitle;

  /// No description provided for @achievementsProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'{unlocked}/{total} badges · today\'s missions {done}/{missions}'**
  String achievementsProfileSummary(int unlocked, int total, int done, int missions);

  /// No description provided for @achievementsCategoryConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get achievementsCategoryConsistency;

  /// No description provided for @achievementsCategoryTraining.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get achievementsCategoryTraining;

  /// No description provided for @achievementsCategoryAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get achievementsCategoryAccuracy;

  /// No description provided for @achievementsCategoryExploration.
  ///
  /// In en, this message translates to:
  /// **'Exploration'**
  String get achievementsCategoryExploration;

  /// No description provided for @achievementsCountingRules.
  ///
  /// In en, this message translates to:
  /// **'Only completed exercises count (not interrupted ones), and each one counts once. Accuracy goals need at least 5 sung notes. The streak counts days with at least one session: opening the app is not enough.'**
  String get achievementsCountingRules;

  /// No description provided for @achievementNoteRunHint.
  ///
  /// In en, this message translates to:
  /// **'Counted from sessions recorded by this version of Intonia onwards.'**
  String get achievementNoteRunHint;

  /// No description provided for @achievementFirstExerciseName.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get achievementFirstExerciseName;

  /// No description provided for @achievementFirstExerciseDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first exercise.'**
  String get achievementFirstExerciseDesc;

  /// No description provided for @achievementDays3Name.
  ///
  /// In en, this message translates to:
  /// **'Three days'**
  String get achievementDays3Name;

  /// No description provided for @achievementDays3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises on 3 different days.'**
  String get achievementDays3Desc;

  /// No description provided for @achievementDays7Name.
  ///
  /// In en, this message translates to:
  /// **'Seven days'**
  String get achievementDays7Name;

  /// No description provided for @achievementDays7Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises on 7 different days.'**
  String get achievementDays7Desc;

  /// No description provided for @achievementStreak7Name.
  ///
  /// In en, this message translates to:
  /// **'7-day streak'**
  String get achievementStreak7Name;

  /// No description provided for @achievementStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Practise 7 days in a row.'**
  String get achievementStreak7Desc;

  /// No description provided for @achievementStreak30Name.
  ///
  /// In en, this message translates to:
  /// **'30-day streak'**
  String get achievementStreak30Name;

  /// No description provided for @achievementStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Practise 30 days in a row.'**
  String get achievementStreak30Desc;

  /// No description provided for @achievementExercises5Name.
  ///
  /// In en, this message translates to:
  /// **'Warming up'**
  String get achievementExercises5Name;

  /// No description provided for @achievementExercises5Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 exercises.'**
  String get achievementExercises5Desc;

  /// No description provided for @achievementExercises25Name.
  ///
  /// In en, this message translates to:
  /// **'In good shape'**
  String get achievementExercises25Name;

  /// No description provided for @achievementExercises25Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 exercises.'**
  String get achievementExercises25Desc;

  /// No description provided for @achievementFirstWorkoutName.
  ///
  /// In en, this message translates to:
  /// **'First workout'**
  String get achievementFirstWorkoutName;

  /// No description provided for @achievementFirstWorkoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a daily workout.'**
  String get achievementFirstWorkoutDesc;

  /// No description provided for @achievementWorkouts5Name.
  ///
  /// In en, this message translates to:
  /// **'Five workouts'**
  String get achievementWorkouts5Name;

  /// No description provided for @achievementWorkouts5Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 daily workouts.'**
  String get achievementWorkouts5Desc;

  /// No description provided for @achievementWorkouts10Name.
  ///
  /// In en, this message translates to:
  /// **'Ten workouts'**
  String get achievementWorkouts10Name;

  /// No description provided for @achievementWorkouts10Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 daily workouts.'**
  String get achievementWorkouts10Desc;

  /// No description provided for @achievementPerfectName.
  ///
  /// In en, this message translates to:
  /// **'Spot on!'**
  String get achievementPerfectName;

  /// No description provided for @achievementPerfectDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete an exercise with 100% accuracy.'**
  String get achievementPerfectDesc;

  /// No description provided for @achievementAccurate5Name.
  ///
  /// In en, this message translates to:
  /// **'Sharp ear'**
  String get achievementAccurate5Name;

  /// No description provided for @achievementAccurate5Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 5 exercises with at least 90% accuracy.'**
  String get achievementAccurate5Desc;

  /// No description provided for @achievementNoteRun10Name.
  ///
  /// In en, this message translates to:
  /// **'Ten in a row'**
  String get achievementNoteRun10Name;

  /// No description provided for @achievementNoteRun10Desc.
  ///
  /// In en, this message translates to:
  /// **'Sing 10 correct notes in a row in one exercise.'**
  String get achievementNoteRun10Desc;

  /// No description provided for @achievementCategories3Name.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achievementCategories3Name;

  /// No description provided for @achievementCategories3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises in 3 different categories.'**
  String get achievementCategories3Desc;

  /// No description provided for @achievementFirstTessituraName.
  ///
  /// In en, this message translates to:
  /// **'Comfort zone'**
  String get achievementFirstTessituraName;

  /// No description provided for @achievementFirstTessituraDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the comfort zone test.'**
  String get achievementFirstTessituraDesc;

  /// No description provided for @achievementSecondTessituraName.
  ///
  /// In en, this message translates to:
  /// **'Back in the zone'**
  String get achievementSecondTessituraName;

  /// No description provided for @achievementSecondTessituraDesc.
  ///
  /// In en, this message translates to:
  /// **'Take the comfort zone test again on another day.'**
  String get achievementSecondTessituraDesc;

  /// No description provided for @missionDailyExercises2.
  ///
  /// In en, this message translates to:
  /// **'Complete 2 exercises today'**
  String get missionDailyExercises2;

  /// No description provided for @missionDailyExercises3.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 exercises today'**
  String get missionDailyExercises3;

  /// No description provided for @missionDailyWorkout.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily workout'**
  String get missionDailyWorkout;

  /// No description provided for @missionDailyAccuracy90.
  ///
  /// In en, this message translates to:
  /// **'Get at least 90% in an exercise'**
  String get missionDailyAccuracy90;

  /// No description provided for @missionWeeklyCategories2.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises in 2 categories'**
  String get missionWeeklyCategories2;

  /// No description provided for @missionWeeklyDays3.
  ///
  /// In en, this message translates to:
  /// **'Complete exercises on 3 different days'**
  String get missionWeeklyDays3;

  /// No description provided for @missionWeeklyWorkouts2.
  ///
  /// In en, this message translates to:
  /// **'Complete 2 daily workouts'**
  String get missionWeeklyWorkouts2;

  /// No description provided for @guideMicTitle.
  ///
  /// In en, this message translates to:
  /// **'The microphone'**
  String get guideMicTitle;

  /// No description provided for @guideMicText.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Intonia! Tap here and sing or play a note: I\'ll tell you which one it is and how many cents off you are.'**
  String get guideMicText;

  /// No description provided for @guideWorkoutText.
  ///
  /// In en, this message translates to:
  /// **'A ready-made session with the exercises you know: open this card, choose 5, 10 or 15 minutes and start.'**
  String get guideWorkoutText;

  /// No description provided for @guideStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak and charges'**
  String get guideStatusTitle;

  /// No description provided for @guideStatusText.
  ///
  /// In en, this message translates to:
  /// **'Here you see how many days in a row you\'ve practised and your exercise charges: each session uses one, and they refill over time.'**
  String get guideStatusText;

  /// No description provided for @guideCategoriesText.
  ///
  /// In en, this message translates to:
  /// **'Exercises are grouped by category: triads, arpeggios, scales and more. Each one trains a different side of your voice.'**
  String get guideCategoriesText;

  /// No description provided for @guideCustomText.
  ///
  /// In en, this message translates to:
  /// **'Here you compose your own sequences, from scratch or starting from an exercise (Intonia Pro).'**
  String get guideCustomText;

  /// No description provided for @guideRangeText.
  ///
  /// In en, this message translates to:
  /// **'Find the lowest and highest notes you can sing. Your results stay here and in your profile.'**
  String get guideRangeText;

  /// No description provided for @guideTessituraText.
  ///
  /// In en, this message translates to:
  /// **'The comfort zone test looks for the part of your voice where singing feels easy.'**
  String get guideTessituraText;

  /// No description provided for @guideStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your statistics'**
  String get guideStatsTitle;

  /// No description provided for @guideStatsText.
  ///
  /// In en, this message translates to:
  /// **'Streak, sessions, minutes and average accuracy: everything updates as you practise.'**
  String get guideStatsText;

  /// No description provided for @guideAchievementsText.
  ///
  /// In en, this message translates to:
  /// **'Today\'s and this week\'s missions, plus badges to unlock along the way.'**
  String get guideAchievementsText;

  /// No description provided for @guideHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get guideHistoryTitle;

  /// No description provided for @guideHistoryText.
  ///
  /// In en, this message translates to:
  /// **'Your latest sessions with exercise, key, octave and result.'**
  String get guideHistoryText;

  /// No description provided for @guideLanguageText.
  ///
  /// In en, this message translates to:
  /// **'Italian or English: by default I use your phone\'s language.'**
  String get guideLanguageText;

  /// No description provided for @guideThemeText.
  ///
  /// In en, this message translates to:
  /// **'System, Light, Dark or Neon: choose the look you like best.'**
  String get guideThemeText;

  /// No description provided for @guideNotationText.
  ///
  /// In en, this message translates to:
  /// **'C D E or DO RE MI: changes the note names throughout the app.'**
  String get guideNotationText;

  /// No description provided for @guideReopenText.
  ///
  /// In en, this message translates to:
  /// **'You can reopen this guide from here whenever you like. Enjoy singing!'**
  String get guideReopenText;

  /// No description provided for @guideTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You\'ll find it here once you\'ve used this part of the app.'**
  String get guideTargetUnavailable;

  /// No description provided for @guideNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Go to {section}'**
  String guideNavTitle(String section);

  /// No description provided for @guideNavText.
  ///
  /// In en, this message translates to:
  /// **'Tap “{section}” in the bar at the bottom to continue.'**
  String guideNavText(String section);

  /// No description provided for @guideTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue'**
  String get guideTapHint;

  /// No description provided for @guideOpenCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a category'**
  String get guideOpenCategoryTitle;

  /// No description provided for @guideOpenCategoryText.
  ///
  /// In en, this message translates to:
  /// **'Tap the category to see its exercises.'**
  String get guideOpenCategoryText;

  /// No description provided for @guideOpenExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Open an exercise'**
  String get guideOpenExerciseTitle;

  /// No description provided for @guideOpenExerciseText.
  ///
  /// In en, this message translates to:
  /// **'Now tap an exercise: I\'ll show you its settings.'**
  String get guideOpenExerciseText;

  /// No description provided for @guideModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen or train'**
  String get guideModeTitle;

  /// No description provided for @guideModeText.
  ///
  /// In en, this message translates to:
  /// **'With the headphones you listen to the sequence; with the microphone you sing and I check your pitch. Then press Play.'**
  String get guideModeText;

  /// No description provided for @guideAdvancedText.
  ///
  /// In en, this message translates to:
  /// **'Speed, tolerance, how long to hold each note, the guide on every note and background noise calibration.'**
  String get guideAdvancedText;

  /// No description provided for @guideHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help in every exercise'**
  String get guideHelpTitle;

  /// No description provided for @guideHelpText.
  ///
  /// In en, this message translates to:
  /// **'Tap ? in any exercise to see these explanations again.'**
  String get guideHelpText;

  /// No description provided for @guideBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to the exercises'**
  String get guideBackTitle;

  /// No description provided for @guideBackText.
  ///
  /// In en, this message translates to:
  /// **'Tap the arrow at the top to go back to the list of exercises.'**
  String get guideBackText;

  /// No description provided for @guideOpenSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the settings'**
  String get guideOpenSettingsTitle;

  /// No description provided for @guideOpenSettingsText.
  ///
  /// In en, this message translates to:
  /// **'Tap the gear at the top to open the settings.'**
  String get guideOpenSettingsText;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
