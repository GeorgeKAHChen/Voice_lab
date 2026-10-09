import 'dart:async';
import 'dart:ui' as ui;

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../colormap.dart';
import '../engine.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pitch_readout.dart';
import '../widgets/spectrogram_view.dart';
import '../widgets/spectrum_view.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key, required this.engine, required this.path});
  final EngineController engine;
  final String path;

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final AmakawaCore core = AmakawaCore.instance;
  final ValueNotifier<ui.Image?> _image = ValueNotifier(null);
  FileAnalysis? _analysis;
  double _duration = 0;
  double _pos = 0;
  int _state = 0;
  bool _failed = false;
  Timer? _timer;

  EngineController get engine => widget.engine;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await engine.beginPlayback(widget.path);
    if (!ok) {
      setState(() => _failed = true);
      return;
    }
    _duration = core.playDuration;
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      setState(() {
        _pos = core.playPos;
        _state = core.playState;
      });
    });
    setState(() {});
    final st = engine.settings;
    final cols = (_duration * 40).round().clamp(300, 2400);
    final a = await AmakawaCore.analyzeFile(
      widget.path,
      cols: cols,
      specMaxHz: st.displayMaxHz,
    );
    if (a == null || !mounted) return;
    var mx = -200.0;
    for (final v in a.spec) {
      if (v > mx) mx = v;
    }
    final img = await buildSpectrogramImage(
      a.spec,
      a.cols,
      kFileSpecBins,
      mx - st.dynamicRangeDb,
      mx,
    );
    if (!mounted) return;
    _image.value = img;
    setState(() => _analysis = a);
  }

  @override
  void dispose() {
    _timer?.cancel();
    core.pause();
    // Defer so the pop animation doesn't rebuild listeners mid-teardown.
    WidgetsBinding.instance.addPostFrameCallback((_) => engine.endPlayback());
    _image.value?.dispose();
    super.dispose();
  }

  String _time(double s) {
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s - m * 60).toStringAsFixed(1).padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final st = engine.settings;
    final a = _analysis;
    final playing = _state == 1;
    return Scaffold(
      appBar: AppBar(title: Text(p.basenameWithoutExtension(widget.path))),
      body: _failed
          ? Center(child: Text(t.cannotOpenRecording))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 900;
                  final overview = Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: a == null
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              SizedBox(
                                height: 56,
                                child: _Wave(
                                  a.wave,
                                  _duration > 0 ? _pos / _duration : 0,
                                ),
                              ),
                              Expanded(
                                child: SpectrogramView(
                                  image: _image,
                                  tracks: a.tracks,
                                  cols: a.cols,
                                  maxHz: st.displayMaxHz,
                                  cursor: _duration > 0
                                      ? (_pos / _duration).clamp(0.0, 1.0)
                                      : 0,
                                  onSeek: (fr) => core.seek(fr * _duration),
                                ),
                              ),
                            ],
                          ),
                  );
                  final spectrum = Card(
                    margin: EdgeInsets.zero,
                    child: SpectrumView(
                      frame: engine.frame,
                      maxHz: st.displayMaxHz,
                      rangeDb: st.dynamicRangeDb,
                      readout: engine.readout,
                    ),
                  );
                  final pitch = Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: PitchReadout(
                        engine: engine,
                        fontSize: wide ? 56 : 40,
                      ),
                    ),
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: wide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(flex: 5, child: overview),
                                        const SizedBox(height: 8),
                                        Expanded(flex: 4, child: spectrum),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(width: 280, child: pitch),
                                ],
                              )
                            : Column(
                                children: [
                                  SizedBox(height: 132, child: pitch),
                                  const SizedBox(height: 8),
                                  Expanded(flex: 5, child: overview),
                                  const SizedBox(height: 8),
                                  Expanded(flex: 4, child: spectrum),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_5),
                                onPressed: () =>
                                    core.seek((_pos - 5).clamp(0, _duration)),
                              ),
                              IconButton.filled(
                                iconSize: 30,
                                icon: Icon(
                                  playing ? Icons.pause : Icons.play_arrow,
                                ),
                                onPressed: () =>
                                    playing ? core.pause() : core.play(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_5),
                                onPressed: () =>
                                    core.seek((_pos + 5).clamp(0, _duration)),
                              ),
                              const SizedBox(width: 12),
                              Text('${_time(_pos)} / ${_time(_duration)}'),
                              if (wide) ...[
                                const Spacer(),
                                Text(
                                  t.playbackHint,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave(this.peaks, this.progress);
  final List<double> peaks;
  final double progress;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _WavePainter(
      peaks,
      progress,
      Theme.of(context).colorScheme.primary,
    ),
  );
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.peaks, this.progress, this.color);
  final List<double> peaks;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - SpectrogramView.left - SpectrogramView.right;
    final mid = size.height / 2;
    var mx = 1e-6;
    for (final v in peaks) {
      if (v > mx) mx = v;
    }
    final n = peaks.length;
    final paint = Paint()..strokeWidth = 1;
    for (var i = 0; i < n; i++) {
      final x = SpectrogramView.left + (i + 0.5) / n * w;
      final h = peaks[i] / mx * (mid - 3);
      paint.color = (i / n) <= progress ? color : color.withValues(alpha: 0.35);
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter o) => true;
}
