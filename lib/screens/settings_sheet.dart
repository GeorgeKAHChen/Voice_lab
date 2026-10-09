import 'dart:io';

import 'package:amakawa_core/amakawa_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../background.dart';
import '../engine.dart';
import '../l10n/app_localizations.dart';
import '../locale_utils.dart';
import '../settings.dart';

Future<void> showSettings(BuildContext context, EngineController engine) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SettingsBody(engine),
  );
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody(this.engine);
  final EngineController engine;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late final List<String> inputs = AmakawaCore.instance.devices(capture: true);
  late final List<String> outputs = AmakawaCore.instance.devices(
    capture: false,
  );
  late int _cap = s.captureDevice;
  late int _play = s.playbackDevice;

  AppSettings get s => widget.engine.settings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.settingsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: s.language,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t.language,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(t.languageSystem)),
                for (final e in kLanguages.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => s.update(language: v ?? ''),
            ),
            const Divider(height: 28),
            _slider(
              t.spectrumRange,
              s.displayMaxHz,
              3000,
              12000,
              'Hz',
              (v) => s.update(displayMaxHz: v.roundToDouble()),
              step: 500,
            ),
            _slider(
              t.dynamicRange,
              s.dynamicRangeDb,
              40,
              110,
              'dB',
              (v) => s.update(dynamicRangeDb: v.roundToDouble()),
              step: 5,
            ),
            if (Platform.isAndroid) ...[
              const Divider(height: 28),
              Text(t.backgroundTitle, style: theme.textTheme.labelLarge),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.backgroundKeepRunning),
                subtitle: Text(t.backgroundKeepRunningHint),
                value: s.backgroundRun,
                onChanged: (v) => setState(() => s.update(backgroundRun: v)),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: widget.engine.backgroundRunning,
                builder: (_, on, _) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    on ? Icons.check_circle : Icons.error_outline,
                    color: on ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  title: Text(on ? t.serviceRunning : t.serviceStopped),
                  subtitle: ValueListenableBuilder<String?>(
                    valueListenable: widget.engine.backgroundError,
                    builder: (_, e, _) =>
                        Text(e == null ? '' : t.serviceReason(e)),
                  ),
                ),
              ),
              FutureBuilder<PermissionStatus>(
                future: Permission.notification.status,
                builder: (context, snap) {
                  final ok = snap.data?.isGranted ?? false;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      ok ? Icons.notifications_active : Icons.notifications_off,
                      color: ok ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    title: Text(
                      ok ? t.notificationsAllowed : t.notificationsDenied,
                    ),
                    subtitle: Text(t.notificationsHint),
                    trailing: ok
                        ? null
                        : FilledButton.tonal(
                            onPressed: () async {
                              final r = await Permission.notification.request();
                              if (!r.isGranted) await openAppSettings();
                              if (context.mounted) setState(() {});
                            },
                            child: Text(t.allow),
                          ),
                  );
                },
              ),
              FutureBuilder<bool>(
                future: BatteryOptimization.ignoring,
                builder: (context, snap) {
                  final ok = snap.data ?? false;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      ok ? Icons.battery_full : Icons.battery_alert,
                    ),
                    title: Text(ok ? t.batteryOk : t.batteryWarn),
                    subtitle: Text(t.batteryHint),
                    trailing: ok
                        ? null
                        : FilledButton.tonal(
                            onPressed: () async {
                              await BatteryOptimization.request();
                              if (context.mounted) setState(() {});
                            },
                            child: Text(t.allow),
                          ),
                  );
                },
              ),
            ],
            const Divider(height: 28),
            Text(t.audioDevices, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _deviceDropdown(
              t,
              t.inputDevice,
              inputs,
              _cap,
              (v) => setState(() => _cap = v),
            ),
            const SizedBox(height: 12),
            _deviceDropdown(
              t,
              t.outputDevice,
              outputs,
              _play,
              (v) => setState(() => _play = v),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed:
                    (_cap != s.captureDevice || _play != s.playbackDevice)
                    ? () async {
                        s.update(captureDevice: _cap, playbackDevice: _play);
                        Navigator.pop(context);
                        await widget.engine.restart();
                      }
                    : null,
                child: Text(t.applyDevices),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.latencyTip(widget.engine.latencyMs.round()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceDropdown(
    AppLocalizations t,
    String label,
    List<String> names,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value >= names.length ? -1 : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: -1, child: Text(t.systemDefault)),
        for (var i = 0; i < names.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(names[i], overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => onChanged(v ?? -1),
    );
  }

  Widget _slider(
    String label,
    double v,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged, {
    required double step,
  }) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: v.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: (x) {
              onChanged(x);
              setState(() {});
            },
          ),
        ),
        SizedBox(
          width: 70,
          child: Text('${v.round()} $unit', textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
