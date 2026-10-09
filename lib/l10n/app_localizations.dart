import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @tabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tabLive;

  /// No description provided for @tabRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get tabRecordings;

  /// No description provided for @sectionPitch.
  ///
  /// In en, this message translates to:
  /// **'Pitch (F0)'**
  String get sectionPitch;

  /// No description provided for @sectionSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Live spectrum'**
  String get sectionSpectrum;

  /// No description provided for @sectionSpectrogram.
  ///
  /// In en, this message translates to:
  /// **'Spectrogram'**
  String get sectionSpectrogram;

  /// No description provided for @levelDb.
  ///
  /// In en, this message translates to:
  /// **'Level {db} dB'**
  String levelDb(int db);

  /// No description provided for @monitorOn.
  ///
  /// In en, this message translates to:
  /// **'Turn headphone monitoring on'**
  String get monitorOn;

  /// No description provided for @monitorOff.
  ///
  /// In en, this message translates to:
  /// **'Turn headphone monitoring off'**
  String get monitorOff;

  /// No description provided for @monitorWarning.
  ///
  /// In en, this message translates to:
  /// **'Wear headphones, otherwise the speaker sound is picked up by the microphone and howls.'**
  String get monitorWarning;

  /// No description provided for @delayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Monitor delay'**
  String get delayTooltip;

  /// No description provided for @delayRealtime.
  ///
  /// In en, this message translates to:
  /// **'Delay: real time'**
  String get delayRealtime;

  /// No description provided for @delaySeconds.
  ///
  /// In en, this message translates to:
  /// **'Delay: {seconds} s'**
  String delaySeconds(int seconds);

  /// No description provided for @delayMenuRealtime.
  ///
  /// In en, this message translates to:
  /// **'Real time (no delay)'**
  String get delayMenuRealtime;

  /// No description provided for @delayMenuSeconds.
  ///
  /// In en, this message translates to:
  /// **'Delay {seconds} s'**
  String delayMenuSeconds(int seconds);

  /// No description provided for @bufferLatency.
  ///
  /// In en, this message translates to:
  /// **'(buffer ≈ {ms} ms)'**
  String bufferLatency(int ms);

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved. Find it in the Recordings tab.'**
  String get recordingSaved;

  /// No description provided for @takeHint.
  ///
  /// In en, this message translates to:
  /// **'Speak, then hear it back (not saved)'**
  String get takeHint;

  /// No description provided for @takeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get takeStart;

  /// No description provided for @takeSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking {time}'**
  String takeSpeaking(String time);

  /// No description provided for @takeStopAndReplay.
  ///
  /// In en, this message translates to:
  /// **'Stop & replay'**
  String get takeStopAndReplay;

  /// No description provided for @takePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing back'**
  String get takePlaying;

  /// No description provided for @takeFinished.
  ///
  /// In en, this message translates to:
  /// **'Playback finished'**
  String get takeFinished;

  /// No description provided for @takeReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get takeReplay;

  /// No description provided for @takeSave.
  ///
  /// In en, this message translates to:
  /// **'Save this take'**
  String get takeSave;

  /// No description provided for @takeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get takeDiscard;

  /// No description provided for @takeRecordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get takeRecordAgain;

  /// No description provided for @takeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to the Recordings tab.'**
  String get takeSaved;

  /// No description provided for @errMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required. Please allow amakawa to use the microphone in system settings.'**
  String get errMicPermission;

  /// No description provided for @errOpenDevice.
  ///
  /// In en, this message translates to:
  /// **'Could not open the audio device (error {code}). Check that a microphone and headphones are connected.'**
  String errOpenDevice(int code);

  /// No description provided for @errRecordStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording (error {code})'**
  String errRecordStart(int code);

  /// No description provided for @recordingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet. Press Record on the Live tab to start.'**
  String get recordingsEmpty;

  /// No description provided for @savedIn.
  ///
  /// In en, this message translates to:
  /// **'Saved in: {path}'**
  String savedIn(String path);

  /// No description provided for @menuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get menuRename;

  /// No description provided for @menuShare.
  ///
  /// In en, this message translates to:
  /// **'Export / share'**
  String get menuShare;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameTitle;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recording?'**
  String get deleteTitle;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cannotOpenRecording.
  ///
  /// In en, this message translates to:
  /// **'Could not open this recording'**
  String get cannotOpenRecording;

  /// No description provided for @playbackHint.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag the spectrogram to seek. The spectrum and pitch show the analysis at the playhead.'**
  String get playbackHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @spectrumRange.
  ///
  /// In en, this message translates to:
  /// **'Spectrum range'**
  String get spectrumRange;

  /// No description provided for @dynamicRange.
  ///
  /// In en, this message translates to:
  /// **'Dynamic range'**
  String get dynamicRange;

  /// No description provided for @audioDevices.
  ///
  /// In en, this message translates to:
  /// **'Audio devices'**
  String get audioDevices;

  /// No description provided for @inputDevice.
  ///
  /// In en, this message translates to:
  /// **'Input (microphone)'**
  String get inputDevice;

  /// No description provided for @outputDevice.
  ///
  /// In en, this message translates to:
  /// **'Output (headphones)'**
  String get outputDevice;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @applyDevices.
  ///
  /// In en, this message translates to:
  /// **'Apply devices'**
  String get applyDevices;

  /// No description provided for @latencyTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: wired headphones give the lowest latency; Bluetooth headphones usually add 100 ms or more. Current buffer latency ≈ {ms} ms.'**
  String latencyTip(int ms);

  /// No description provided for @backgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundTitle;

  /// No description provided for @backgroundKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running when the screen is off or in another app'**
  String get backgroundKeepRunning;

  /// No description provided for @backgroundKeepRunningHint.
  ///
  /// In en, this message translates to:
  /// **'Shows a persistent notification (required by Android)'**
  String get backgroundKeepRunningHint;

  /// No description provided for @serviceRunning.
  ///
  /// In en, this message translates to:
  /// **'Background service: running'**
  String get serviceRunning;

  /// No description provided for @serviceStopped.
  ///
  /// In en, this message translates to:
  /// **'Background service: not running'**
  String get serviceStopped;

  /// No description provided for @serviceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String serviceReason(String reason);

  /// No description provided for @backgroundStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Background mode could not start: {reason} (Settings → Background)'**
  String backgroundStartFailed(String reason);

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications: allowed'**
  String get notificationsAllowed;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications: not allowed'**
  String get notificationsDenied;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Needed to show the “running” notification while amakawa works in the background'**
  String get notificationsHint;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @batteryOk.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is ignored for this app'**
  String get batteryOk;

  /// No description provided for @batteryWarn.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization may stop background audio'**
  String get batteryWarn;

  /// No description provided for @batteryHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended on phones that aggressively stop background apps (Xiaomi, Huawei, OPPO, vivo, Samsung…)'**
  String get batteryHint;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'amakawa background'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps amakawa running in the background while monitoring or recording'**
  String get notifChannelDescription;

  /// No description provided for @notifIdle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing — tap to return'**
  String get notifIdle;

  /// No description provided for @notifRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get notifRecording;

  /// No description provided for @notifMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get notifMonitoring;

  /// No description provided for @notifPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playing back'**
  String get notifPlayback;

  /// No description provided for @notifTake.
  ///
  /// In en, this message translates to:
  /// **'Capturing a take (replays when you stop)'**
  String get notifTake;

  /// No description provided for @notifBusy.
  ///
  /// In en, this message translates to:
  /// **'{parts} — tap to return'**
  String notifBusy(String parts);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
