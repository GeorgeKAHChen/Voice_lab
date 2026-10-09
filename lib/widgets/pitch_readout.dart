import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine.dart';
import '../l10n/app_localizations.dart';

const _names = [
  'C',
  'C♯',
  'D',
  'D♯',
  'E',
  'F',
  'F♯',
  'G',
  'G♯',
  'A',
  'A♯',
  'B',
];

/// Note name with the deviation in cents, e.g. `A4 +0¢`. Empty for non-positive input.
String noteName(double hz) {
  if (hz <= 0) return '';
  final midi = 69 + 12 * math.log(hz / 440) / math.ln2;
  final n = midi.round();
  final cents = ((midi - n) * 100).round();
  final oct = (n ~/ 12) - 1;
  return '${_names[n % 12]}$oct ${cents >= 0 ? '+' : ''}$cents¢';
}

/// Big pitch number, note name and a level meter. Updates about 5 times a second.
class PitchReadout extends StatelessWidget {
  const PitchReadout({super.key, required this.engine, this.fontSize = 44});
  final EngineController engine;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: engine.panelTick,
      builder: (context, _, _) {
        final r = engine.readout;
        final level = ((r.levelDb + 80) / 80).clamp(0.0, 1.0).toDouble();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                r.voiced ? r.f0.toStringAsFixed(1) : '—',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  color: r.voiced ? Colors.white : scheme.outline,
                ),
              ),
            ),
            Text(
              r.voiced ? 'Hz · ${noteName(r.f0)}' : 'Hz',
              style: TextStyle(color: scheme.primary),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: level,
                minHeight: 6,
                color: level > 0.93 ? Colors.redAccent : scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              t.levelDb(r.levelDb.clamp(-99, 0).round()),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }
}
