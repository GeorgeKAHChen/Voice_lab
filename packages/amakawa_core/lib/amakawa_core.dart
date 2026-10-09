/// Dart bindings to the native amakawa audio core (miniaudio + DSP).
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// Layout constants shared with src/amakawa_core.h.
const int kOutSize = 4 + 2048;
const int kSpecBins = 2048; // FFT bins per live frame: bin k = k * rate / 4096
const int kFftSize = 4096;
const int kTrackStride = 2; // per column: f0, clarity
const int kFileSpecBins = 256; // spectrogram rows per column of a file analysis

DynamicLibrary _open() {
  if (Platform.isMacOS || Platform.isIOS) {
    try {
      return DynamicLibrary.open('amakawa_core.framework/amakawa_core');
    } catch (_) {
      return DynamicLibrary.process();
    }
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libamakawa_core.so');
  }
  if (Platform.isWindows) return DynamicLibrary.open('amakawa_core.dll');
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

final DynamicLibrary _lib = _open();

// ---- native functions
final _deviceCount = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>(
      'vc_device_count',
    );
final _deviceName = _lib
    .lookupFunction<
      Int32 Function(Int32, Int32, Pointer<Utf8>, Int32),
      int Function(int, int, Pointer<Utf8>, int)
    >('vc_device_name');
final _open_ = _lib
    .lookupFunction<
      Int32 Function(Int32, Int32, Int32, Int32),
      int Function(int, int, int, int)
    >('vc_open');
final _close = _lib.lookupFunction<Void Function(), void Function()>(
  'vc_close',
);
final _latency = _lib.lookupFunction<Double Function(), double Function()>(
  'vc_latency_ms',
);
final _rate = _lib.lookupFunction<Int32 Function(), int Function()>(
  'vc_sample_rate',
);
final _setMonitor = _lib
    .lookupFunction<Void Function(Int32), void Function(int)>('vc_set_monitor');
final _setGain = _lib
    .lookupFunction<Void Function(Float), void Function(double)>(
      'vc_set_monitor_gain',
    );
final _setDelay = _lib
    .lookupFunction<Void Function(Float), void Function(double)>(
      'vc_set_monitor_delay',
    );
final _analyze = _lib
    .lookupFunction<
      Int32 Function(Pointer<Float>),
      int Function(Pointer<Float>)
    >('vc_analyze');
final _recStart = _lib
    .lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
      'vc_record_start',
    );
final _recStop = _lib.lookupFunction<Void Function(), void Function()>(
  'vc_record_stop',
);
final _recSecs = _lib.lookupFunction<Double Function(), double Function()>(
  'vc_record_seconds',
);
final _playLoad = _lib
    .lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
      'vc_play_load',
    );
final _playUnload = _lib.lookupFunction<Void Function(), void Function()>(
  'vc_play_unload',
);
final _playStart = _lib.lookupFunction<Void Function(), void Function()>(
  'vc_play_start',
);
final _playPause = _lib.lookupFunction<Void Function(), void Function()>(
  'vc_play_pause',
);
final _playSeek = _lib
    .lookupFunction<Void Function(Double), void Function(double)>(
      'vc_play_seek',
    );
final _playPos = _lib.lookupFunction<Double Function(), double Function()>(
  'vc_play_pos',
);
final _playDur = _lib.lookupFunction<Double Function(), double Function()>(
  'vc_play_duration',
);
final _playState = _lib.lookupFunction<Int32 Function(), int Function()>(
  'vc_play_state',
);

/// One analysis snapshot of the current audio source.
class AnalysisFrame {
  AnalysisFrame(this.sampleRate, Float32List raw)
    : rmsDb = raw[0],
      f0 = raw[1],
      clarity = raw[2],
      spectrum = Float32List.fromList(raw.sublist(4, 4 + kSpecBins));

  final int sampleRate;
  final double rmsDb;
  final double f0; // Hz, 0 = unvoiced
  final double clarity; // 0..1
  final Float32List spectrum; // dB, bin k = k * binHz

  bool get voiced => f0 > 0 && clarity >= 0.45;
  double get binHz => sampleRate / kFftSize;
}

/// Result of offline analysis of a whole recording.
class FileAnalysis {
  FileAnalysis(this.cols, this.tracks, this.spec, this.wave, this.specMaxHz);
  final int cols;
  final Float32List tracks; // cols * kTrackStride: f0, clarity
  final Float32List spec; // cols * kFileSpecBins, dB (bin 0 = lowest frequency)
  final Float32List wave; // cols peak amplitudes
  final double specMaxHz;
}

class AmakawaCore {
  AmakawaCore._();
  static final AmakawaCore instance = AmakawaCore._();

  final Pointer<Float> _buf = malloc<Float>(kOutSize);

  List<String> devices({required bool capture}) {
    final n = _deviceCount(capture ? 1 : 0);
    final names = <String>[];
    final p = malloc<Uint8>(256).cast<Utf8>();
    for (var i = 0; i < n; i++) {
      names.add(
        _deviceName(capture ? 1 : 0, i, p, 256) == 0
            ? p.toDartString()
            : 'Device $i',
      );
    }
    malloc.free(p);
    return names;
  }

  /// Opens the full-duplex engine. Returns 0 on success.
  int open({
    int capture = -1,
    int playback = -1,
    int sampleRate = 48000,
    int period = 0,
  }) => _open_(capture, playback, sampleRate, period);
  void close() => _close();
  double get latencyMs => _latency();
  int get sampleRate => _rate();

  void setMonitor(bool on) => _setMonitor(on ? 1 : 0);
  void setMonitorGain(double g) => _setGain(g);
  void setMonitorDelay(double seconds) => _setDelay(seconds);

  AnalysisFrame? analyze() {
    if (_analyze(_buf) == 0) return null;
    return AnalysisFrame(
      _rate(),
      Float32List.fromList(_buf.asTypedList(kOutSize)),
    );
  }

  int recordStart(String path) {
    final p = path.toNativeUtf8();
    try {
      return _recStart(p);
    } finally {
      malloc.free(p);
    }
  }

  void recordStop() => _recStop();
  double get recordSeconds => _recSecs();

  int playLoad(String path) {
    final p = path.toNativeUtf8();
    try {
      return _playLoad(p);
    } finally {
      malloc.free(p);
    }
  }

  void playUnload() => _playUnload();
  void play() => _playStart();
  void pause() => _playPause();
  void seek(double s) => _playSeek(s);
  double get playPos => _playPos();
  double get playDuration => _playDur();

  /// 0 paused, 1 playing, 2 finished
  int get playState => _playState();

  static FileAnalysis? _analyzeFileSync(
    String path,
    int cols,
    double specMaxHz,
  ) {
    final fn = _lib
        .lookupFunction<
          Int32 Function(
            Pointer<Utf8>,
            Int32,
            Float,
            Pointer<Float>,
            Pointer<Float>,
            Pointer<Float>,
          ),
          int Function(
            Pointer<Utf8>,
            int,
            double,
            Pointer<Float>,
            Pointer<Float>,
            Pointer<Float>,
          )
        >('vc_file_analyze');
    final pp = path.toNativeUtf8();
    final tr = malloc<Float>(cols * kTrackStride);
    final sp = malloc<Float>(cols * kFileSpecBins);
    final wv = malloc<Float>(cols);
    try {
      if (fn(pp, cols, specMaxHz, tr, sp, wv) != 0) return null;
      return FileAnalysis(
        cols,
        Float32List.fromList(tr.asTypedList(cols * kTrackStride)),
        Float32List.fromList(sp.asTypedList(cols * kFileSpecBins)),
        Float32List.fromList(wv.asTypedList(cols)),
        specMaxHz,
      );
    } finally {
      malloc.free(pp);
      malloc.free(tr);
      malloc.free(sp);
      malloc.free(wv);
    }
  }

  /// Analyzes a whole file off the UI thread: spectrogram, pitch track, waveform.
  static Future<FileAnalysis?> analyzeFile(
    String path, {
    required int cols,
    required double specMaxHz,
  }) {
    return Isolate.run(() => _analyzeFileSync(path, cols, specMaxHz));
  }

  /// Duration (seconds) of an audio file, or null if it cannot be decoded.
  static double? fileDuration(String path) {
    final fn = _lib
        .lookupFunction<
          Int32 Function(Pointer<Utf8>, Pointer<Double>, Pointer<Int32>),
          int Function(Pointer<Utf8>, Pointer<Double>, Pointer<Int32>)
        >('vc_file_info');
    final pp = path.toNativeUtf8();
    final d = malloc<Double>();
    final r = malloc<Int32>();
    try {
      return fn(pp, d, r) == 0 ? d.value : null;
    } finally {
      malloc.free(pp);
      malloc.free(d);
      malloc.free(r);
    }
  }
}
