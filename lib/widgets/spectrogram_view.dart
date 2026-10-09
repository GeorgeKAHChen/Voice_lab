import 'dart:ui' as ui;

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Spectrogram image with the pitch track overlaid.
/// [tracks] uses the native layout: [kTrackStride] floats per column (f0, clarity).
class SpectrogramView extends StatelessWidget {
  const SpectrogramView({
    super.key,
    required this.image,
    required this.tracks,
    required this.cols,
    required this.maxHz,
    this.cursor,
    this.onSeek,
  });

  final ValueListenable<ui.Image?> image;
  final Float32List tracks;
  final int cols;
  final double maxHz;
  final double? cursor; // 0..1
  final void Function(double fraction)? onSeek;

  static const double left = 36, right = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void seek(Offset o) {
          final w = c.maxWidth - left - right;
          onSeek?.call(((o.dx - left) / w).clamp(0.0, 1.0));
        }

        return GestureDetector(
          onTapDown: onSeek == null ? null : (d) => seek(d.localPosition),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (d) => seek(d.localPosition),
          child: ValueListenableBuilder<ui.Image?>(
            valueListenable: image,
            builder: (context, img, _) => CustomPaint(
              size: Size.infinite,
              painter: _SpecPainter(
                img,
                tracks,
                cols,
                maxHz,
                cursor,
                Theme.of(context).colorScheme,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpecPainter extends CustomPainter {
  _SpecPainter(
    this.img,
    this.tracks,
    this.cols,
    this.maxHz,
    this.cursor,
    this.scheme,
  );
  final ui.Image? img;
  final Float32List tracks;
  final int cols;
  final double maxHz;
  final double? cursor;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 4.0;
    final plot = Rect.fromLTRB(
      SpectrogramView.left,
      pad,
      size.width - SpectrogramView.right,
      size.height - pad,
    );
    canvas.drawRect(plot, Paint()..color = Colors.black);
    final i = img;
    if (i != null) {
      canvas.drawImageRect(
        i,
        Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble()),
        plot,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }

    final txt = TextStyle(color: scheme.onSurfaceVariant, fontSize: 10);
    final step = maxHz <= 6000 ? 1000.0 : 2000.0;
    for (var hz = 0.0; hz <= maxHz + 1; hz += step) {
      final y = plot.bottom - hz / maxHz * plot.height;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
      final tp = TextPainter(
        text: TextSpan(text: '${(hz / 1000).toStringAsFixed(0)}k', style: txt),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(plot.left - tp.width - 4, y - tp.height / 2));
    }

    // pitch track
    if (cols > 0) {
      canvas.save();
      canvas.clipRect(plot);
      final dotR = (plot.width / cols).clamp(1.2, 2.6);
      final dot = Paint()..color = Colors.white;
      for (var c = 0; c < cols; c++) {
        final o = c * kTrackStride;
        if (o + 1 >= tracks.length) break;
        final f0 = tracks[o];
        if (f0 > 0 && f0 <= maxHz && tracks[o + 1] >= 0.45) {
          final x = plot.left + (c + 0.5) / cols * plot.width;
          canvas.drawCircle(
            Offset(x, plot.bottom - f0 / maxHz * plot.height),
            dotR,
            dot,
          );
        }
      }
      canvas.restore();
    }

    final cu = cursor;
    if (cu != null) {
      final x = plot.left + cu * plot.width;
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpecPainter o) => true;
}
