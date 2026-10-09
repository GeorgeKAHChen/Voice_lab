import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:amakawa_core/amakawa_core.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'background.dart';
import 'colormap.dart';
import 'l10n/app_localizations.dart';
import 'settings.dart';

const int kHistoryCols = 320;

/// State of the "speak, then replay immediately" take.
enum TakeState { idle, recording, replaying, done }

enum EngineErrorKind { micPermission, openDevice, recordStart }

/// A failure to report to the user; the UI turns it into a localized message.
class EngineError {
  const EngineError(this.kind, [this.code]);
  final EngineErrorKind kind;
  final int? code;
}

/// Median-smoothed pitch of the last few voiced frames.
class Readout {
  double f0 = 0;
  bool voiced = false;
  double levelDb = -120;
}

/// Owns the native engine, polls the analysis, keeps the rolling spectrogram.
class EngineController extends ChangeNotifier with WidgetsBindingObserver {
  EngineController(this.settings) {
    WidgetsBinding.instance.addObserver(this);
    _lastDisplayMax = settings.displayMaxHz;
    settings.addListener(() {
      _syncBackground();
      if (settings.displayMaxHz != _lastDisplayMax) {
        _lastDisplayMax = settings.displayMaxHz;
        _histDb.fillRange(0, _histDb.length, -200);
        histTracks.fillRange(0, histTracks.length, 0);
      }
    });
  }

  final AppSettings settings;
  final AmakawaCore core = AmakawaCore.instance;

  /// Current UI strings, used for the background notification text.
  AppLocalizations? _l10n;

  void setStrings(AppLocalizations strings) {
    final changed = _l10n?.localeName != strings.localeName;
    _l10n = strings;
    if (changed && ready) _syncBackground();
  }

  // coarse state (rebuilds whole screens)
  bool ready = false;
  EngineError? error;
  bool monitor = false;
  bool recording = false;
  bool playbackActive = false;
  TakeState take = TakeState.idle;
  final ValueNotifier<double> takePos = ValueNotifier(0);
  double takeDuration = 0;
  double latencyMs = 0;

  // fast state (separate notifiers so only painters rebuild)
  final ValueNotifier<AnalysisFrame?> frame = ValueNotifier(null);
  final ValueNotifier<ui.Image?> liveImage = ValueNotifier(null);
  final ValueNotifier<double> recSeconds = ValueNotifier(0);
  final Readout readout = Readout();
  final ValueNotifier<int> readoutTick = ValueNotifier(0); // every frame
  final ValueNotifier<int> panelTick = ValueNotifier(0); // ~5 Hz, for numbers

  // rolling history: kHistoryCols columns of kFileSpecBins dB + pitch track
  final Float32List _histDb = Float32List(kHistoryCols * kFileSpecBins)
    ..fillRange(0, kHistoryCols * kFileSpecBins, -200);
  final Float32List histTracks = Float32List(kHistoryCols * kTrackStride);
  double _lastDisplayMax = 6000;

  Timer? _timer;
  final BackgroundKeeper _bg = BackgroundKeeper();
  ValueNotifier<String?> get backgroundError => _bg.error;
  ValueNotifier<bool> get backgroundRunning => _bg.running;
  bool _decoding = false;
  final List<AnalysisFrame> _recent = [];
  String? _takePath;
  AudioSession? _session;

  /// Marks the current error as shown (without rebuilding).
  void clearError() => error = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-assert the background service if the system dropped it meanwhile.
    if (state == AppLifecycleState.resumed) _syncBackground();
  }

  /// Holds audio focus so Android keeps routing our audio while in the background.
  Future<void> _activateAudioSession() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final s = _session ??= await AudioSession.instance;
      await s.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      await s.setActive(true);
    } catch (_) {
      // Non-fatal: capture and playback still work without explicit focus.
    }
  }

  Future<Directory> recordingsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'amakawa'));
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  static String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  Future<void> start() async {
    error = null;
    ready = false;
    notifyListeners();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final st = await Permission.microphone.request();
      if (!st.isGranted) {
        error = const EngineError(EngineErrorKind.micPermission);
        notifyListeners();
        return;
      }
    }
    final r = core.open(
      capture: settings.captureDevice,
      playback: settings.playbackDevice,
    );
    if (r != 0) {
      error = EngineError(EngineErrorKind.openDevice, r);
      notifyListeners();
      return;
    }
    core.setMonitor(monitor);
    core.setMonitorGain(settings.monitorGain);
    core.setMonitorDelay(settings.monitorDelay);
    latencyMs = core.latencyMs;
    ready = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
    await _activateAudioSession();
    if (Platform.isAndroid &&
        !(await Permission.notification.status).isGranted) {
      await Permission.notification.request();
    }
    _syncBackground(); // start the keep-alive service while the app is visible
    notifyListeners();
  }

  Future<void> restart() async {
    if (recording) await stopRecording();
    if (take != TakeState.idle) discardTake();
    _timer?.cancel();
    core.close();
    await start();
  }

  /// Keeps the Android foreground service in step with what the app is doing.
  void _syncBackground() {
    final t = _l10n ?? lookupAppLocalizations(const Locale('en'));
    final parts = <String>[
      if (recording) t.notifRecording,
      if (monitor) t.notifMonitoring,
      if (playbackActive || take == TakeState.replaying) t.notifPlayback,
      if (take == TakeState.recording) t.notifTake,
    ];
    _bg.sync(
      active: ready && settings.backgroundRun,
      text: parts.isEmpty
          ? t.notifIdle
          : t.notifBusy(parts.join(t.listSeparator)),
      channelName: t.notifChannelName,
      channelDescription: t.notifChannelDescription,
    );
  }

  void setMonitor(bool on) {
    monitor = on;
    core.setMonitor(on);
    _syncBackground();
    notifyListeners();
  }

  void setDelay(double seconds) {
    settings.update(monitorDelay: seconds);
    core.setMonitorDelay(seconds);
    notifyListeners();
  }

  void setGain(double g) {
    settings.update(monitorGain: g);
    core.setMonitorGain(g);
  }

  // ---------------------------------------------------------- take & replay
  /// Starts capturing a temporary take (not saved unless asked).
  Future<void> startTake() async {
    if (!ready || recording || take == TakeState.recording || playbackActive) {
      return;
    }
    if (take != TakeState.idle) discardTake();
    final dir = await getTemporaryDirectory();
    _takePath = p.join(dir.path, 'amakawa_take.wav');
    final r = core.recordStart(_takePath!);
    if (r != 0) {
      error = EngineError(EngineErrorKind.recordStart, r);
      notifyListeners();
      return;
    }
    take = TakeState.recording;
    _syncBackground();
    notifyListeners();
  }

  /// Stops capturing and immediately plays the take back.
  void stopTakeAndReplay() {
    if (take != TakeState.recording) return;
    core.recordStop();
    recSeconds.value = 0;
    replayTake();
  }

  void replayTake() {
    final path = _takePath;
    if (path == null) return;
    if (core.playLoad(path) != 0) {
      take = TakeState.idle;
      _syncBackground();
      notifyListeners();
      return;
    }
    takeDuration = core.playDuration;
    core.seek(0);
    core.play();
    take = TakeState.replaying;
    _syncBackground();
    notifyListeners();
  }

  void stopReplay() {
    core.pause();
    take = TakeState.done;
    notifyListeners();
  }

  /// Keeps the take as a normal recording. Returns the saved path.
  Future<String?> saveTake() async {
    final path = _takePath;
    if (path == null || take == TakeState.idle) return null;
    core.playUnload();
    final d = await recordingsDir();
    final dest = p.join(d.path, 'take_${_stamp()}.wav');
    await File(path).copy(dest);
    discardTake();
    return dest;
  }

  void discardTake() {
    if (take == TakeState.recording) core.recordStop();
    if (take != TakeState.idle) core.playUnload();
    final path = _takePath;
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
    take = TakeState.idle;
    takePos.value = 0;
    _syncBackground();
    notifyListeners();
  }

  // ---------------------------------------------------------- recording
  String? _recordingPath;

  Future<void> startRecording() async {
    if (!ready || recording || take != TakeState.idle) return;
    final d = await recordingsDir();
    final path = p.join(d.path, 'rec_${_stamp()}.wav');
    final r = core.recordStart(path);
    if (r != 0) {
      error = EngineError(EngineErrorKind.recordStart, r);
      notifyListeners();
      return;
    }
    _recordingPath = path;
    recording = true;
    _syncBackground();
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (!recording) return null;
    core.recordStop();
    recording = false;
    recSeconds.value = 0;
    _syncBackground();
    notifyListeners();
    return _recordingPath;
  }

  // ---------------------------------------------------------- playback of a file
  Future<bool> beginPlayback(String path) async {
    if (!ready) return false;
    if (take != TakeState.idle) discardTake();
    if (core.playLoad(path) != 0) return false;
    playbackActive = true;
    core.seek(0);
    _syncBackground();
    notifyListeners();
    return true;
  }

  void endPlayback() {
    core.playUnload();
    playbackActive = false;
    _syncBackground();
    notifyListeners();
  }

  // ---------------------------------------------------------- polling
  void _tick() {
    if (!ready) return;
    final f = core.analyze();
    if (f == null) return;
    frame.value = f;
    if (recording || take == TakeState.recording) {
      recSeconds.value = core.recordSeconds;
    }
    if (take == TakeState.replaying) {
      takePos.value = core.playPos;
      if (core.playState == 2) {
        take = TakeState.done;
        _syncBackground();
        notifyListeners();
      }
    }
    _updateReadout(f);
    if (!playbackActive) {
      _pushHistory(f);
      _rebuildImage();
    }
  }

  static const int _win = 9; // median window (~0.36 s at 25 fps)
  static const int _holdFrames =
      8; // keep the last value through short dropouts
  int _gap = 0;
  DateTime _lastPanel = DateTime.fromMillisecondsSinceEpoch(0);

  void _updateReadout(AnalysisFrame f) {
    readout.levelDb = f.rmsDb;
    if (f.voiced) {
      _recent.add(f);
      if (_recent.length > _win) _recent.removeAt(0);
      _gap = 0;
    } else if (++_gap > _holdFrames && _recent.isNotEmpty) {
      _recent.removeAt(0);
    }
    readout.voiced = _recent.length >= 3;
    if (readout.voiced) {
      // Median pitch, ignoring octave outliers relative to that median.
      final f0s = _recent.map((e) => e.f0).toList();
      final med = _median(List.of(f0s));
      final ok = f0s.where((v) => v > med * 0.75 && v < med * 1.33).toList();
      readout.f0 = _median(ok.isEmpty ? f0s : ok);
    } else {
      readout.f0 = 0;
    }
    readoutTick.value++;
    final now = DateTime.now();
    if (now.difference(_lastPanel).inMilliseconds >= 200) {
      _lastPanel = now;
      panelTick.value++;
    }
  }

  static double _median(List<double> v) {
    v.sort();
    return v[v.length ~/ 2];
  }

  void _pushHistory(AnalysisFrame f) {
    // shift left by one column
    _histDb.setRange(
      0,
      (kHistoryCols - 1) * kFileSpecBins,
      _histDb,
      kFileSpecBins,
    );
    histTracks.setRange(
      0,
      (kHistoryCols - 1) * kTrackStride,
      histTracks,
      kTrackStride,
    );
    final o = (kHistoryCols - 1) * kFileSpecBins;
    final binHz = f.binHz;
    final maxHz = settings.displayMaxHz;
    for (var k = 0; k < kFileSpecBins; k++) {
      final b0 = (k * maxHz / kFileSpecBins / binHz).floor();
      final b1 = math.max(
        b0 + 1,
        ((k + 1) * maxHz / kFileSpecBins / binHz).floor(),
      );
      var m = -200.0;
      for (
        var j = math.min(b0, kSpecBins - 1);
        j < math.min(b1, kSpecBins);
        j++
      ) {
        if (f.spectrum[j] > m) m = f.spectrum[j];
      }
      _histDb[o + k] = m;
    }
    final t = (kHistoryCols - 1) * kTrackStride;
    histTracks[t] = readout.voiced ? readout.f0 : 0;
    histTracks[t + 1] = readout.voiced ? 1 : 0;
  }

  Future<void> _rebuildImage() async {
    if (_decoding) return;
    _decoding = true;
    try {
      const ceil = -20.0;
      final img = await buildSpectrogramImage(
        _histDb,
        kHistoryCols,
        kFileSpecBins,
        ceil - settings.dynamicRangeDb,
        ceil,
      );
      final old = liveImage.value;
      liveImage.value = img;
      old?.dispose();
    } finally {
      _decoding = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (recording || take == TakeState.recording) core.recordStop();
    core.close();
    _bg.sync(active: false, text: '');
    super.dispose();
  }
}
