import 'dart:math' as math;

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine.dart';

/// Live magnitude spectrum with an F0 marker and a touch / hover read-out.
class SpectrumView extends StatefulWidget {
  const SpectrumView({
    super.key,
    required this.frame,
    required this.maxHz,
    required this.rangeDb,
    this.readout,
  });

  final ValueListenable<AnalysisFrame?> frame;
  final double maxHz;
  final double rangeDb;

  /// Smoothed pitch for the F0 marker (falls back to the raw frame).
  final Readout? readout;

  @override
  State<SpectrumView> createState() => _SpectrumViewState();
}

class _SpectrumViewState extends State<SpectrumView> {
  double? _cursorHz;
  Float32List? _avg; // exponentially averaged spectrum (dB) to calm flicker

  @override
  void initState() {
    super.initState();
    widget.frame.addListener(_onFrame);
  }

  @override
  void dispose() {
    widget.frame.removeListener(_onFrame);
    super.dispose();
  }

  void _onFrame() {
    final f = widget.frame.value;
    if (f == null) return;
    final a = _avg ??= Float32List.fromList(f.spectrum);
    for (var i = 0; i < a.length; i++) {
      a[i] += (f.spectrum[i] - a[i]) * 0.45;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void setCursor(Offset o) {
          const left = _SpectrumPainter.left, right = _SpectrumPainter.right;
          final w = c.maxWidth - left - right;
          setState(
            () => _cursorHz = ((o.dx - left) / w * widget.maxHz)
                .clamp(0, widget.maxHz)
                .toDouble(),
          );
        }

        return MouseRegion(
          onHover: (e) => setCursor(e.localPosition),
          onExit: (_) => setState(() => _cursorHz = null),
          child: GestureDetector(
            onPanDown: (d) => setCursor(d.localPosition),
            onPanUpdate: (d) => setCursor(d.localPosition),
            onPanEnd: (_) => setState(() => _cursorHz = null),
            child: ValueListenableBuilder<AnalysisFrame?>(
              valueListenable: widget.frame,
              builder: (context, f, _) => CustomPaint(
                size: Size.infinite,
                painter: _SpectrumPainter(
                  f,
                  _avg,
                  widget.readout,
                  widget.maxHz,
                  widget.rangeDb,
                  _cursorHz,
                  Theme.of(context).colorScheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter(
    this.f,
    this.avg,
    this.ro,
    this.maxHz,
    this.rangeDb,
    this.cursorHz,
    this.scheme,
  );
  final AnalysisFrame? f;
  final Float32List? avg;
  final Readout? ro;
  final double maxHz, rangeDb;
  final double? cursorHz;
  final ColorScheme scheme;

  static const double left = 36, right = 8, topPad = 18, bottomPad = 20;
  static const double topDb = -10;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      left,
      topPad,
      size.width - right,
      size.height - bottomPad,
    );
    final floor = topDb - rangeDb;
    double xOf(double hz) => plot.left + hz / maxHz * plot.width;
    double yOf(double db) =>
        plot.bottom -
        ((db - floor) / (topDb - floor)).clamp(0.0, 1.0) * plot.height;

    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final txt = TextStyle(color: scheme.onSurfaceVariant, fontSize: 10);
    void label(
      String s,
      Offset o, {
      TextStyle? style,
      bool rightAlign = false,
    }) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style ?? txt),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rightAlign ? o - Offset(tp.width, 0) : o);
    }

    // dB grid
    for (var db = topDb; db >= floor - 0.1; db -= 20) {
      final y = yOf(db);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      label('${db.round()}', Offset(plot.left - 4, y - 6), rightAlign: true);
    }
    // Hz grid
    final step = maxHz <= 6000 ? 500.0 : 1000.0;
    for (var hz = 0.0; hz <= maxHz + 1; hz += step) {
      final x = xOf(hz);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      if (hz % (step * 2) == 0 || maxHz > 6000) {
        label(
          hz >= 1000
              ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}k'
              : '${hz.round()}',
          Offset(x - 8, plot.bottom + 4),
        );
      }
    }
    label('Hz', Offset(plot.right - 10, plot.bottom + 4));

    final fr = f;
    if (fr == null) return;
    final spec = avg ?? fr.spectrum;
    final voiced = ro != null ? ro!.voiced : fr.voiced;
    final f0 = ro != null ? ro!.f0 : fr.f0;

    canvas.save();
    canvas.clipRect(plot.inflate(1));

    // spectrum curve, decimated to roughly one point per pixel
    final binHz = fr.binHz;
    final path = Path();
    final lastBin = math.min(kSpecBins - 1, (maxHz / binHz).ceil());
    final stride = math.max(1, (lastBin / plot.width).floor());
    var first = true;
    for (var k = 0; k <= lastBin; k += stride) {
      var m = spec[k];
      for (var j = 1; j < stride && k + j <= lastBin; j++) {
        if (spec[k + j] > m) m = spec[k + j];
      }
      final x = xOf(k * binHz), y = yOf(m);
      if (first) {
        path.moveTo(x, plot.bottom);
        path.lineTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(xOf(lastBin * binHz), plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary.withValues(alpha: 0.55),
            scheme.primary.withValues(alpha: 0.05),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = scheme.primary,
    );

    // F0 marker
    if (voiced) {
      final x = xOf(f0);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
    if (voiced) {
      label(
        'F0',
        Offset(xOf(f0) - 6, 3),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // cursor read-out
    final ch = cursorHz;
    if (ch != null) {
      final x = xOf(ch);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = scheme.onSurface.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
      final k = (ch / binHz).round().clamp(0, kSpecBins - 1);
      final s = '${ch.round()} Hz  ${spec[k].toStringAsFixed(1)} dB';
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(color: scheme.onSurface, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final ox = math.min(x + 6, plot.right - tp.width - 4);
      final r = Rect.fromLTWH(
        ox - 3,
        plot.top + 14,
        tp.width + 6,
        tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      );
      tp.paint(canvas, Offset(ox, plot.top + 16));
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter o) => true;
}
