# Building amakawa

[English](BUILD.md) · [繁體中文](BUILD.zh-TW.md)

The native C++ part (`packages/amakawa_core`) is compiled automatically by Flutter
during the build – there is no separate CMake step. Use Flutter **stable 3.47 or newer**.

## Common

1. Install Flutter: <https://docs.flutter.dev/get-started/install> and check `flutter doctor`.
2. Get the whole repository (the app refers to `packages/amakawa_core` by relative path).
3. Optional sanity check: `make test` (runs the Dart tests and the C++ DSP test; the latter
   needs `g++` or `clang++`).

```
make deps      # flutter pub get
make l10n      # regenerate localization code after editing lib/l10n/*.arb
make analyze   # static analysis
make test      # Dart tests + C++ DSP test
```

## macOS

**Requirements:** macOS 12+, Xcode (run `sudo xcodebuild -runFirstLaunch` once), CocoaPods
(`brew install cocoapods`). `flutter doctor` must be green for Xcode and CocoaPods.

```bash
make macos        # -> build/macos/Build/Products/Release/amakawa.app
make macos-dmg    # also packages build/amakawa-macos.dmg
```

Equivalent to `flutter config --enable-macos-desktop && flutter pub get && flutter build macos --release`.
For development: `flutter run -d macos`.

Notes:

- **Microphone permission** is declared in `macos/Runner/Info.plist`
  (`NSMicrophoneUsageDescription`) and in both `.entitlements` files
  (`com.apple.security.device.audio-input`). macOS asks on first launch; if you denied it,
  enable it under *System Settings → Privacy & Security → Microphone*.
- Release builds are **sandboxed**: recordings live in the app's sandbox Documents folder.
  Use *Export / share* in the Recordings tab to get a file out.
- An unsigned app is blocked by Gatekeeper on other Macs (right-click → Open works around
  it). To distribute it, sign and notarize it with an Apple Developer account
  (open `macos/Runner.xcworkspace` in Xcode → *Signing & Capabilities*).
- If CocoaPods fails: `cd macos && pod install --repo-update`, then retry.

## Windows

**Requirements:** Windows 10/11 x64, **Visual Studio 2022** with the *Desktop development
with C++* workload (MSVC, Windows SDK, CMake), and **Developer Mode** turned on (Settings →
System → For developers) because Flutter plugins need symlinks. `flutter doctor` must be
green for Visual Studio.

```powershell
.\scripts\build_windows.ps1
```

which is equivalent to:

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\amakawa.exe`. Keep `amakawa_core.dll`,
`flutter_windows.dll` and the `data\` folder next to the exe – copy the whole `Release`
folder (the script also zips it to `build\amakawa-windows-x64.zip`). Machines without the
VC++ runtime need the *Microsoft Visual C++ Redistributable (x64)*.

For development: `flutter run -d windows`. Windows asks for microphone access on first use
(Settings → Privacy → Microphone, "let desktop apps access your microphone").

## Android

```bash
make android        # build/app/outputs/flutter-apk/app-release.apk
flutter install     # to a connected phone with USB debugging
```

**Requirements:** Android SDK, NDK (Flutter downloads the version it needs) and JDK 17.
The first build is slow because of those downloads. If the build says *Could not find
Ninja*, install CMake from the SDK Manager or run `pip install ninja`. On machines with
less than 8 GB of RAM, lower `org.gradle.jvmargs` in `android/gradle.properties`.

Release builds are signed with the **debug key**; create your own keystore before
publishing (see <https://docs.flutter.dev/deployment/android#sign-the-app>).

**Privacy note:** a Flutter release build embeds the absolute path of the project folder
(for example `file:///home/<user>/…/dart_plugin_registrant.dart`) in `libapp.so`. For a public
release, build from a neutral directory or on CI (the GitHub Actions workflow does) so your
local user name does not end up in the APK.

Background mode uses a foreground service (microphone + media playback types). On some
phones (Xiaomi, Huawei, OPPO, vivo, Samsung, …) also allow *ignore battery optimization*
in amakawa's *Settings → Background*.

## GitHub Actions

`.github/workflows/build.yml` builds macOS, Windows and Android in the cloud. Push the
repository to GitHub, open *Actions → build → Run workflow*, and download the `.dmg`, `.zip`
and `.apk` from the run's artifacts.

## Troubleshooting

| Symptom | What to do |
|---|---|
| "Could not open the audio device" | Make sure an input and an output device exist; pick them explicitly in *Settings → Audio devices* |
| Howling while monitoring | Wear headphones, or turn monitoring off |
| `amakawa_core.dll` not found (Windows) | Don't copy only the exe – copy the whole `Release` folder |
| Symlink error during `flutter build` (Windows) | Turn on Developer Mode |
| `Pods` errors (macOS) | `cd macos && pod install --repo-update` |
