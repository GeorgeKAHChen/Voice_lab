import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app (and its microphone access) alive while it is in the
/// background. On Android this is a foreground service with the microphone and
/// media-playback types; desktop platforms keep running audio in the background
/// without any help.
class BackgroundKeeper {
  bool _inited = false;
  bool _busy = false;
  bool _want = false;
  String _text = '';
  String _channelName = 'amakawa';
  String _channelDescription = '';

  /// Last start/stop error, or null when the service is fine. Observed by the UI.
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Whether the service is currently running.
  final ValueNotifier<bool> running = ValueNotifier(false);

  void _init() {
    if (_inited) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'amakawa_running',
        channelName: _channelName,
        channelDescription: _channelDescription,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      // Note: do NOT pass stopWithTask here. In this plugin it makes the service
      // stop as soon as the app is no longer visible (screen off, other app).
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowAutoRestart: false,
        allowWakeLock: true,
      ),
    );
    _inited = true;
  }

  /// Starts, updates or stops the service so that it matches [active].
  /// [channelName] / [channelDescription] are only used the first time.
  Future<void> sync({
    required bool active,
    required String text,
    String? channelName,
    String? channelDescription,
  }) async {
    if (!Platform.isAndroid) return;
    _want = active;
    _text = text;
    if (!_inited) {
      _channelName = channelName ?? _channelName;
      _channelDescription = channelDescription ?? _channelDescription;
    }
    if (_busy) return; // the running call re-checks the final state below
    _busy = true;
    try {
      _init();
      while (true) {
        final want = _want, txt = _text;
        final up = await FlutterForegroundTask.isRunningService;
        if (want && !up) {
          final perm =
              await FlutterForegroundTask.checkNotificationPermission();
          if (perm != NotificationPermission.granted) {
            await FlutterForegroundTask.requestNotificationPermission();
          }
          final r = await FlutterForegroundTask.startService(
            serviceTypes: [
              ForegroundServiceTypes.microphone,
              ForegroundServiceTypes.mediaPlayback,
            ],
            notificationTitle: 'amakawa',
            notificationText: txt,
          );
          if (r is ServiceRequestFailure) {
            error.value = '${r.error}';
            break;
          }
          error.value = null;
        } else if (want && up) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'amakawa',
            notificationText: txt,
          );
        } else if (!want && up) {
          await FlutterForegroundTask.stopService();
        }
        running.value = await FlutterForegroundTask.isRunningService;
        if (want == _want && txt == _text) break;
      }
    } catch (e) {
      // Best effort; audio still works in the foreground. Surface the reason.
      error.value = '$e';
    } finally {
      _busy = false;
    }
  }
}

/// Battery-optimisation helpers (some Android vendors kill background apps).
class BatteryOptimization {
  static Future<bool> get ignoring async => Platform.isAndroid
      ? FlutterForegroundTask.isIgnoringBatteryOptimizations
      : true;

  static Future<void> request() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}
