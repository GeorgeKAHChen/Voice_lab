# Voice_lab

[English](README.md) · [繁體中文](README.zh-TW.md)

A voice tool for your headphones: hear yourself in real time and see your pitch,
spectrum and spectrogram while you speak or sing. Record, replay, and analyse
recordings. Runs on Android, Windows and macOS.

## Features

- **Live analysis** – three collapsible panels:
  - **Pitch (F0)** with note name and cents, a level meter and a pitch trace of the last few seconds
  - **Live spectrum** with touch / hover read-out of frequency and level
  - **Spectrogram** (heat map) with the pitch track overlaid
- **Headphone monitoring** – your microphone in your headphones with low latency,
  adjustable volume (0–300 %), and an optional **monitor delay** (1, 2, 3, 5 or 8 s)
  so you hear yourself a few seconds late.
- **Speak, then replay** – press *Start*, talk, press *Stop & replay* and the take is
  played back immediately. Nothing is saved unless you choose to keep it.
- **Recording and playback** – 16-bit WAV recordings; rename, delete and share them.
  The player shows the waveform, the whole-file spectrogram and pitch track, and the
  spectrum / pitch at the playhead (tap or drag to seek).
- **Background mode (Android)** – keeps monitoring and recording going with the screen off
  or in another app, using a foreground service with a persistent notification.
- **Languages** – English, 日本語, 简体中文, 繁體中文 (or follow the system); switch in *Settings*.
- Choose input / output devices, spectrum range and dynamic range in *Settings*.

## Tips

- Use **wired headphones**. Without headphones the speaker sound is picked up by the
  microphone and howls; Bluetooth headphones usually add 100 ms or more of latency.
- For a stable pitch reading, hold a steady tone and keep the microphone a little away
  from your mouth to avoid pops.

## Build

See [BUILD.md](BUILD.md) for Android, Windows and macOS (also available in
[繁體中文](BUILD.zh-TW.md)). In short, with Flutter installed:

```bash
flutter pub get
flutter run            # on a connected device / desktop
make test              # Dart tests + C++ DSP test
make android           # release APK
```

## How it works

```
lib/                       Flutter UI (Dart): screens, painters, state, localization
packages/amakawa_core/     FFI plugin: the native audio + analysis core
  src/amakawa_core.cpp       full-duplex engine: monitor, delay line, recording, playback
  src/dsp.cpp                FFT spectrum, YIN pitch detection, level
  src/miniaudio*             miniaudio (audio I/O + decoding for every platform)
  lib/amakawa_core.dart      dart:ffi bindings
  test_native/               C++ unit test of the DSP code (no audio hardware needed)
```

The audio callback runs in C++ (WASAPI on Windows, CoreAudio on macOS, AAudio / OpenSL ES
on Android). The UI polls the analysis about 25 times a second; recording is written to
disk from a separate thread.

## Adding a language

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb` and translate the values.
2. Add the language to `kLanguages` and `localeFromCode` in `lib/locale_utils.dart`.
3. Run `make l10n`, then `make test`.

## Known limitations

- Pitch is estimated for a single voice in the range 60–1000 Hz.
- Release builds are signed with the debug key; configure your own signing for distribution.
- The Linux desktop app has not been tried (the native core builds and its tests pass there).

## License

[MIT](LICENSE). The bundled [miniaudio](https://miniaud.io) is public domain / MIT-0.
