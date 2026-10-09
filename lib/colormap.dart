import 'dart:typed_data';
import 'dart:ui' as ui;

const _stops = <List<int>>[
  [0, 0, 4],
  [40, 11, 84],
  [101, 21, 110],
  [159, 42, 99],
  [212, 72, 66],
  [245, 125, 21],
  [250, 193, 39],
  [252, 255, 164],
];

/// 256-entry inferno-like lookup, packed as RGBA bytes.
final Uint8List kColorLut = () {
  final l = Uint8List(256 * 4);
  for (var i = 0; i < 256; i++) {
    final t = i / 255 * (_stops.length - 1);
    final k = t.floor().clamp(0, _stops.length - 2);
    final f = t - k;
    for (var c = 0; c < 3; c++) {
      l[i * 4 + c] = (_stops[k][c] + (_stops[k + 1][c] - _stops[k][c]) * f)
          .round();
    }
    l[i * 4 + 3] = 255;
  }
  return l;
}();

/// Renders a spectrogram image: [db] is cols*bins floats (bin 0 = lowest freq).
/// Row 0 of the image is the highest frequency.
Future<ui.Image> buildSpectrogramImage(
  Float32List db,
  int cols,
  int bins,
  double floorDb,
  double ceilDb,
) async {
  final px = Uint8List(cols * bins * 4);
  final span = ceilDb - floorDb;
  for (var c = 0; c < cols; c++) {
    for (var b = 0; b < bins; b++) {
      final v = db[c * bins + b];
      var t = (v - floorDb) / span;
      t = t < 0 ? 0 : (t > 1 ? 1 : t);
      final li = (t * 255).round() * 4;
      final o = ((bins - 1 - b) * cols + c) * 4;
      px[o] = kColorLut[li];
      px[o + 1] = kColorLut[li + 1];
      px[o + 2] = kColorLut[li + 2];
      px[o + 3] = 255;
    }
  }
  final buf = await ui.ImmutableBuffer.fromUint8List(px);
  final desc = ui.ImageDescriptor.raw(
    buf,
    width: cols,
    height: bins,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await desc.instantiateCodec();
  final frame = await codec.getNextFrame();
  codec.dispose();
  desc.dispose();
  buf.dispose();
  return frame.image;
}
