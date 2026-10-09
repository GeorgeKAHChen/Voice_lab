import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_utils.dart';

/// User-adjustable options, persisted across launches.
class AppSettings extends ChangeNotifier {
  double displayMaxHz = 6000; // upper frequency of the spectrum / spectrogram
  double dynamicRangeDb = 80;
  double monitorGain = 1.0;
  double monitorDelay = 0; // seconds, 0 = real time
  bool backgroundRun =
      true; // keep alive in the background (Android foreground service)
  int captureDevice = -1; // -1 = system default
  int playbackDevice = -1;
  String language =
      ''; // '' = follow the system, otherwise a key of [kLanguages]

  SharedPreferences? _p;

  /// The explicitly chosen locale, or null to follow the system.
  Locale? get locale => localeFromCode(language);

  Future<void> load() async {
    final p = _p = await SharedPreferences.getInstance();
    displayMaxHz = p.getDouble('displayMaxHz') ?? displayMaxHz;
    dynamicRangeDb = p.getDouble('dynamicRangeDb') ?? dynamicRangeDb;
    monitorGain = p.getDouble('monitorGain') ?? monitorGain;
    monitorDelay = p.getDouble('monitorDelay') ?? monitorDelay;
    backgroundRun = p.getBool('backgroundRun') ?? backgroundRun;
    captureDevice = p.getInt('captureDevice') ?? captureDevice;
    playbackDevice = p.getInt('playbackDevice') ?? playbackDevice;
    language = p.getString('language') ?? language;
  }

  void update({
    double? displayMaxHz,
    double? dynamicRangeDb,
    double? monitorGain,
    double? monitorDelay,
    bool? backgroundRun,
    int? captureDevice,
    int? playbackDevice,
    String? language,
  }) {
    this.displayMaxHz = displayMaxHz ?? this.displayMaxHz;
    this.dynamicRangeDb = dynamicRangeDb ?? this.dynamicRangeDb;
    this.monitorGain = monitorGain ?? this.monitorGain;
    this.monitorDelay = monitorDelay ?? this.monitorDelay;
    this.backgroundRun = backgroundRun ?? this.backgroundRun;
    this.captureDevice = captureDevice ?? this.captureDevice;
    this.playbackDevice = playbackDevice ?? this.playbackDevice;
    this.language = language ?? this.language;
    final p = _p;
    if (p != null) {
      p.setDouble('displayMaxHz', this.displayMaxHz);
      p.setDouble('dynamicRangeDb', this.dynamicRangeDb);
      p.setDouble('monitorGain', this.monitorGain);
      p.setDouble('monitorDelay', this.monitorDelay);
      p.setBool('backgroundRun', this.backgroundRun);
      p.setInt('captureDevice', this.captureDevice);
      p.setInt('playbackDevice', this.playbackDevice);
      p.setString('language', this.language);
    }
    notifyListeners();
  }
}
