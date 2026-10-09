// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabLive => 'Live';

  @override
  String get tabRecordings => 'Recordings';

  @override
  String get sectionPitch => 'Pitch (F0)';

  @override
  String get sectionSpectrum => 'Live spectrum';

  @override
  String get sectionSpectrogram => 'Spectrogram';

  @override
  String levelDb(int db) {
    return 'Level $db dB';
  }

  @override
  String get monitorOn => 'Turn headphone monitoring on';

  @override
  String get monitorOff => 'Turn headphone monitoring off';

  @override
  String get monitorWarning =>
      'Wear headphones, otherwise the speaker sound is picked up by the microphone and howls.';

  @override
  String get delayTooltip => 'Monitor delay';

  @override
  String get delayRealtime => 'Delay: real time';

  @override
  String delaySeconds(int seconds) {
    return 'Delay: $seconds s';
  }

  @override
  String get delayMenuRealtime => 'Real time (no delay)';

  @override
  String delayMenuSeconds(int seconds) {
    return 'Delay $seconds s';
  }

  @override
  String bufferLatency(int ms) {
    return '(buffer ≈ $ms ms)';
  }

  @override
  String get record => 'Record';

  @override
  String get stop => 'Stop';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get recordingSaved =>
      'Recording saved. Find it in the Recordings tab.';

  @override
  String get takeHint => 'Speak, then hear it back (not saved)';

  @override
  String get takeStart => 'Start';

  @override
  String takeSpeaking(String time) {
    return 'Speaking $time';
  }

  @override
  String get takeStopAndReplay => 'Stop & replay';

  @override
  String get takePlaying => 'Playing back';

  @override
  String get takeFinished => 'Playback finished';

  @override
  String get takeReplay => 'Replay';

  @override
  String get takeSave => 'Save this take';

  @override
  String get takeDiscard => 'Discard';

  @override
  String get takeRecordAgain => 'Record again';

  @override
  String get takeSaved => 'Saved to the Recordings tab.';

  @override
  String get errMicPermission =>
      'Microphone permission is required. Please allow amakawa to use the microphone in system settings.';

  @override
  String errOpenDevice(int code) {
    return 'Could not open the audio device (error $code). Check that a microphone and headphones are connected.';
  }

  @override
  String errRecordStart(int code) {
    return 'Could not start recording (error $code)';
  }

  @override
  String get recordingsEmpty =>
      'No recordings yet. Press Record on the Live tab to start.';

  @override
  String savedIn(String path) {
    return 'Saved in: $path';
  }

  @override
  String get menuRename => 'Rename';

  @override
  String get menuShare => 'Export / share';

  @override
  String get menuDelete => 'Delete';

  @override
  String get renameTitle => 'Rename';

  @override
  String get deleteTitle => 'Delete recording?';

  @override
  String get delete => 'Delete';

  @override
  String get cannotOpenRecording => 'Could not open this recording';

  @override
  String get playbackHint =>
      'Tap or drag the spectrogram to seek. The spectrum and pitch show the analysis at the playhead.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get spectrumRange => 'Spectrum range';

  @override
  String get dynamicRange => 'Dynamic range';

  @override
  String get audioDevices => 'Audio devices';

  @override
  String get inputDevice => 'Input (microphone)';

  @override
  String get outputDevice => 'Output (headphones)';

  @override
  String get systemDefault => 'System default';

  @override
  String get applyDevices => 'Apply devices';

  @override
  String latencyTip(int ms) {
    return 'Tip: wired headphones give the lowest latency; Bluetooth headphones usually add 100 ms or more. Current buffer latency ≈ $ms ms.';
  }

  @override
  String get backgroundTitle => 'Background';

  @override
  String get backgroundKeepRunning =>
      'Keep running when the screen is off or in another app';

  @override
  String get backgroundKeepRunningHint =>
      'Shows a persistent notification (required by Android)';

  @override
  String get serviceRunning => 'Background service: running';

  @override
  String get serviceStopped => 'Background service: not running';

  @override
  String serviceReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String backgroundStartFailed(String reason) {
    return 'Background mode could not start: $reason (Settings → Background)';
  }

  @override
  String get notificationsAllowed => 'Notifications: allowed';

  @override
  String get notificationsDenied => 'Notifications: not allowed';

  @override
  String get notificationsHint =>
      'Needed to show the “running” notification while amakawa works in the background';

  @override
  String get allow => 'Allow';

  @override
  String get batteryOk => 'Battery optimization is ignored for this app';

  @override
  String get batteryWarn => 'Battery optimization may stop background audio';

  @override
  String get batteryHint =>
      'Recommended on phones that aggressively stop background apps (Xiaomi, Huawei, OPPO, vivo, Samsung…)';

  @override
  String get notifChannelName => 'amakawa background';

  @override
  String get notifChannelDescription =>
      'Keeps amakawa running in the background while monitoring or recording';

  @override
  String get notifIdle => 'Analyzing — tap to return';

  @override
  String get notifRecording => 'Recording';

  @override
  String get notifMonitoring => 'Monitoring';

  @override
  String get notifPlayback => 'Playing back';

  @override
  String get notifTake => 'Capturing a take (replays when you stop)';

  @override
  String notifBusy(String parts) {
    return '$parts — tap to return';
  }

  @override
  String get listSeparator => ', ';
}
