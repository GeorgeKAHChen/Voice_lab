import 'dart:math' as math;

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/material.dart';

import '../engine.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pitch_readout.dart';
import '../widgets/spectrogram_view.dart';
import '../widgets/spectrum_view.dart';
import 'settings_sheet.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({
    super.key,
    required this.engine,
    required this.onRecordingSaved,
  });
  final EngineController engine;
  final VoidCallback onRecordingSaved;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  bool _showF0 = false;
  bool _showSpectrum = true;
  bool _showHeatmap = true;

  EngineController get engine => widget.engine;

  @override
  void initState() {
    super.initState();
    engine.addListener(_onEngine);
  }

  @override
  void dispose() {
    engine.removeListener(_onEngine);
    super.dispose();
  }

  /// Errors that happen while running (e.g. recording could not start) are shown
  /// as a snackbar; start-up errors get the full-screen view below.
  void _onEngine() {
    final e = engine.error;
    if (e == null || !engine.ready || !mounted) return;
    engine.clearError();
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.errRecordStart(e.code ?? 0))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([engine, engine.settings]),
      builder: (context, _) {
        if (engine.error != null && !engine.ready) {
          return _ErrorView(engine: engine);
        }
        if (!engine.ready) {
          return const Center(child: CircularProgressIndicator());
        }
        final st = engine.settings;
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                // On very short windows (e.g. a phone in landscape) the panels keep a
                // minimum height and the area scrolls instead of overflowing.
                child: LayoutBuilder(
                  builder: (context, c) {
                    const header = 48.0,
                        gap = 8.0,
                        minPlot = 80.0,
                        pitchPlot = 140.0;
                    final needed =
                        3 * header +
                        2 * gap +
                        (_showF0 ? pitchPlot : 0) +
                        (_showSpectrum ? minPlot : 0) +
                        (_showHeatmap ? minPlot : 0);
                    return SingleChildScrollView(
                      child: SizedBox(
                        height: math.max(c.maxHeight, needed),
                        child: Column(
                          children: [
                            _Section(
                              title: t.sectionPitch,
                              icon: Icons.music_note,
                              expanded: _showF0,
                              fixedHeight: 140,
                              onToggle: () =>
                                  setState(() => _showF0 = !_showF0),
                              summary: ValueListenableBuilder<int>(
                                valueListenable: engine.panelTick,
                                builder: (_, _, _) {
                                  final r = engine.readout;
                                  return Text(
                                    r.voiced
                                        ? '${r.f0.toStringAsFixed(1)} Hz · ${noteName(r.f0)}'
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              child: _F0Content(engine: engine),
                            ),
                            const SizedBox(height: 8),
                            _Section(
                              title: t.sectionSpectrum,
                              icon: Icons.show_chart,
                              expanded: _showSpectrum,
                              flex: 5,
                              onToggle: () => setState(
                                () => _showSpectrum = !_showSpectrum,
                              ),
                              child: SpectrumView(
                                frame: engine.frame,
                                maxHz: st.displayMaxHz,
                                rangeDb: st.dynamicRangeDb,
                                readout: engine.readout,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _Section(
                              title: t.sectionSpectrogram,
                              icon: Icons.grid_on,
                              expanded: _showHeatmap,
                              flex: 5,
                              onToggle: () =>
                                  setState(() => _showHeatmap = !_showHeatmap),
                              child: AnimatedBuilder(
                                animation: engine.readoutTick,
                                builder: (context, _) => SpectrogramView(
                                  image: engine.liveImage,
                                  tracks: engine.histTracks,
                                  cols: kHistoryCols,
                                  maxHz: st.displayMaxHz,
                                ),
                              ),
                            ),
                            if (!_showSpectrum && !_showHeatmap) const Spacer(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: engine.backgroundError,
                builder: (_, e, _) => e == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          t.backgroundStartFailed(e),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              _Controls(engine: engine, onSaved: widget.onRecordingSaved),
            ],
          ),
        );
      },
    );
  }
}

/// A card with a tappable header; takes flexible space only while expanded
/// (or a fixed height when [fixedHeight] is given).
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.flex = 1,
    this.fixedHeight,
    this.summary,
  });
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final int flex;
  final double? fixedHeight;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  ?summary,
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            fixedHeight != null
                ? SizedBox(height: fixedHeight, child: child)
                : Expanded(child: child),
        ],
      ),
    );
    return expanded && fixedHeight == null
        ? Expanded(flex: flex, child: card)
        : card;
  }
}

/// Pitch read-out next to a pitch trace over the last few seconds.
class _F0Content extends StatelessWidget {
  const _F0Content({required this.engine});
  final EngineController engine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          SizedBox(width: 150, child: PitchReadout(engine: engine)),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: engine.readoutTick,
              builder: (_, _) => CustomPaint(
                size: Size.infinite,
                painter: _PitchTracePainter(engine.histTracks, scheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchTracePainter extends CustomPainter {
  _PitchTracePainter(this.tracks, this.scheme);
  final List<double> tracks;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final n = tracks.length ~/ kTrackStride;
    var lo = double.infinity, hi = 0.0;
    for (var i = 0; i < n; i++) {
      final f = tracks[i * kTrackStride];
      if (f > 0) {
        lo = math.min(lo, f);
        hi = math.max(hi, f);
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.35),
    );
    if (hi == 0) return;
    // log-frequency axis with at least one octave of range
    var a = math.log(lo * 0.9), b = math.log(hi * 1.1);
    if (b - a < math.ln2) {
      final mid = (a + b) / 2;
      a = mid - math.ln2 / 2;
      b = mid + math.ln2 / 2;
    }
    double yOf(double f) =>
        size.height - (math.log(f) - a) / (b - a) * size.height;
    final line = Paint()
      ..color = scheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Path? path;
    for (var i = 0; i < n; i++) {
      final f = tracks[i * kTrackStride];
      final x = (i + 0.5) / n * size.width;
      if (f <= 0) {
        if (path != null) canvas.drawPath(path, line);
        path = null;
        continue;
      }
      final y = yOf(f);
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) canvas.drawPath(path, line);
    void axisLabel(double logHz, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${math.exp(logHz).round()} Hz',
          style: TextStyle(color: scheme.outline, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(0, at.dy > size.height / 2 ? tp.height : 0));
    }

    axisLabel(b, const Offset(6, 4));
    axisLabel(a, Offset(6, size.height - 4));
  }

  @override
  bool shouldRepaint(covariant _PitchTracePainter o) => true;
}

/// Bottom area: monitor + volume, delay, recording and take/replay.
class _Controls extends StatelessWidget {
  const _Controls({required this.engine, required this.onSaved});
  final EngineController engine;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    final st = engine.settings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: monitor toggle + full-width volume slider
                Row(
                  children: [
                    IconButton.filledTonal(
                      isSelected: engine.monitor,
                      tooltip: engine.monitor ? t.monitorOff : t.monitorOn,
                      icon: const Icon(Icons.headphones_outlined),
                      selectedIcon: const Icon(Icons.headphones),
                      onPressed: () {
                        final on = !engine.monitor;
                        engine.setMonitor(on);
                        if (on) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.monitorWarning)),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.volume_mute, size: 20),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 11,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 22,
                          ),
                        ),
                        child: Slider(
                          value: st.monitorGain.clamp(0.0, 3.0),
                          min: 0,
                          max: 3,
                          onChanged: engine.setGain,
                        ),
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 20),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(st.monitorGain * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                // Row 2: delay, latency, record, settings
                Row(
                  children: [
                    PopupMenuButton<double>(
                      tooltip: t.delayTooltip,
                      initialValue: st.monitorDelay,
                      onSelected: engine.setDelay,
                      itemBuilder: (_) => [
                        for (final d in const [0.0, 1.0, 2.0, 3.0, 5.0, 8.0])
                          PopupMenuItem(
                            value: d,
                            child: Text(
                              d == 0
                                  ? t.delayMenuRealtime
                                  : t.delayMenuSeconds(d.round()),
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              st.monitorDelay == 0
                                  ? t.delayRealtime
                                  : t.delaySeconds(st.monitorDelay.round()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (MediaQuery.of(context).size.width > 520)
                      Text(
                        t.bufferLatency(engine.latencyMs.round()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const Spacer(),
                    if (engine.recording)
                      ValueListenableBuilder<double>(
                        valueListenable: engine.recSeconds,
                        builder: (_, s, _) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _fmt(s),
                            style: TextStyle(color: scheme.error, fontSize: 16),
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: engine.recording
                            ? scheme.surfaceContainerHighest
                            : scheme.error,
                        foregroundColor: engine.recording
                            ? scheme.onSurface
                            : scheme.onError,
                      ),
                      icon: Icon(
                        engine.recording
                            ? Icons.stop
                            : Icons.fiber_manual_record,
                      ),
                      label: Text(engine.recording ? t.stop : t.record),
                      onPressed: engine.take != TakeState.idle
                          ? null
                          : () async {
                              if (engine.recording) {
                                await engine.stopRecording();
                                onSaved();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.recordingSaved)),
                                  );
                                }
                              } else {
                                await engine.startRecording();
                              }
                            },
                    ),
                    IconButton(
                      tooltip: t.settingsTitle,
                      icon: const Icon(Icons.tune),
                      onPressed: () => showSettings(context, engine),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _TakeBar(engine: engine, onSaved: onSaved),
      ],
    );
  }
}

/// "Speak, press stop, hear it back immediately" - the take is not saved
/// unless you choose to keep it.
class _TakeBar extends StatelessWidget {
  const _TakeBar({required this.engine, required this.onSaved});
  final EngineController engine;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    Widget content;
    switch (engine.take) {
      case TakeState.idle:
        content = Row(
          children: [
            Icon(Icons.replay_circle_filled_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(t.takeHint)),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.mic),
              label: Text(t.takeStart),
              onPressed: engine.recording ? null : engine.startTake,
            ),
          ],
        );
      case TakeState.recording:
        content = Row(
          children: [
            Icon(Icons.fiber_manual_record, color: scheme.error),
            const SizedBox(width: 10),
            ValueListenableBuilder<double>(
              valueListenable: engine.recSeconds,
              builder: (_, s, _) => Text(
                t.takeSpeaking(_fmt(s)),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Spacer(),
            TextButton(onPressed: engine.discardTake, child: Text(t.cancel)),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(t.takeStopAndReplay),
              onPressed: engine.stopTakeAndReplay,
            ),
          ],
        );
      case TakeState.replaying:
      case TakeState.done:
        final playing = engine.take == TakeState.replaying;
        content = Row(
          children: [
            Icon(
              playing ? Icons.volume_up : Icons.check_circle_outline,
              color: scheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: engine.takePos,
                builder: (_, pos, _) {
                  final dur = engine.takeDuration;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${playing ? t.takePlaying : t.takeFinished}  ${_fmt(playing ? pos : dur)} / ${_fmt(dur)}',
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: dur > 0
                            ? (playing ? pos / dur : 1.0)
                                  .clamp(0.0, 1.0)
                                  .toDouble()
                            : 0.0,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            if (playing)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.stop),
                label: Text(t.stop),
                onPressed: engine.stopReplay,
              )
            else ...[
              IconButton(
                tooltip: t.takeReplay,
                icon: const Icon(Icons.replay),
                onPressed: engine.replayTake,
              ),
              IconButton(
                tooltip: t.takeSave,
                icon: const Icon(Icons.save_alt),
                onPressed: () async {
                  final path = await engine.saveTake();
                  onSaved();
                  if (path != null && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(t.takeSaved)));
                  }
                },
              ),
              IconButton(
                tooltip: t.takeDiscard,
                icon: const Icon(Icons.delete_outline),
                onPressed: engine.discardTake,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.mic),
                label: Text(t.takeRecordAgain),
                onPressed: engine.startTake,
              ),
            ],
          ],
        );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: content,
      ),
    );
  }
}

String _fmt(double s) {
  final m = s ~/ 60;
  final r = s - m * 60;
  return '${m.toString().padLeft(2, '0')}:${r.toStringAsFixed(1).padLeft(4, '0')}';
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.engine});
  final EngineController engine;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final e = engine.error!;
    final message = switch (e.kind) {
      EngineErrorKind.micPermission => t.errMicPermission,
      EngineErrorKind.openDevice => t.errOpenDevice(e.code ?? 0),
      EngineErrorKind.recordStart => t.errRecordStart(e.code ?? 0),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: engine.start, child: Text(t.retry)),
          ],
        ),
      ),
    );
  }
}
