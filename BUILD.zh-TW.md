# 編譯 Voice_lab

[English](BUILD.md) · [繁體中文](BUILD.zh-TW.md)

原生 C++ 部分（`packages/amakawa_core`）由 Flutter 在建置時自動編譯，**不需要**另外執行 CMake。
請使用 Flutter **stable 3.47 以上**。

## 通用準備

1. 安裝 Flutter：<https://docs.flutter.dev/get-started/install>，用 `flutter doctor` 檢查環境。
2. 取得整個專案目錄（App 以相對路徑引用 `packages/amakawa_core`）。
3. （建議）先執行 `make test`，會跑 Dart 測試和 C++ DSP 測試（後者需要 `g++` 或 `clang++`）。

```
make deps      # flutter pub get
make l10n      # 修改 lib/l10n/*.arb 後重新產生多語言程式碼
make analyze   # 靜態分析
make test      # Dart 測試 + C++ DSP 測試
```

## macOS

**環境：** macOS 12+、Xcode（首次需執行 `sudo xcodebuild -runFirstLaunch`）、CocoaPods
（`brew install cocoapods`）。`flutter doctor` 中 Xcode 和 CocoaPods 須為綠色。

```bash
make macos        # -> build/macos/Build/Products/Release/amakawa.app
make macos-dmg    # 並打包 build/amakawa-macos.dmg
```

等同於 `flutter config --enable-macos-desktop && flutter pub get && flutter build macos --release`。
開發除錯：`flutter run -d macos`。

注意事項：

- **麥克風權限**已寫在 `macos/Runner/Info.plist`（`NSMicrophoneUsageDescription`）和兩個
  `.entitlements`（`com.apple.security.device.audio-input`）。首次啟動會詢問；若誤按拒絕，到
  「系統設定 → 隱私與安全性 → 麥克風」開啟。
- Release 版本啟用 **App 沙盒**：錄音存放在沙盒的 Documents 資料夾，可在「錄音」頁用
  「匯出 / 分享」取出檔案。
- 未簽名的 App 在其他 Mac 上會被 Gatekeeper 攔截（右鍵 → 打開可繞過）。要正式發佈需要 Apple
  Developer 帳號簽名並公證（用 Xcode 打開 `macos/Runner.xcworkspace` →「Signing & Capabilities」）。
- 若 CocoaPods 失敗：`cd macos && pod install --repo-update`，再重試。

## Windows

**環境：** Windows 10/11 x64、**Visual Studio 2022**（工作負載選「使用 C++ 的桌面開發」，含 MSVC、
Windows SDK、CMake），並開啟**開發人員模式**（設定 → 系統 → 開發人員專用），因為 Flutter 插件需要符號連結。
`flutter doctor` 中 Visual Studio 須為綠色。

```powershell
.\scripts\build_windows.ps1
```

等同於：

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```

產出：`build\windows\x64\runner\Release\amakawa.exe`。`amakawa_core.dll`、`flutter_windows.dll` 和
`data\` 資料夾必須與 exe 放在一起；請複製整個 `Release` 資料夾（腳本也會壓縮成
`build\amakawa-windows-x64.zip`）。沒有 VC++ 執行庫的電腦需要安裝
*Microsoft Visual C++ Redistributable (x64)*。

開發除錯：`flutter run -d windows`。首次使用時 Windows 會詢問麥克風權限
（設定 → 隱私 → 麥克風，允許桌面應用程式存取）。

## Android

```bash
make android        # build/app/outputs/flutter-apk/app-release.apk
flutter install     # 安裝到已連接（開啟 USB 偵錯）的手機
```

**環境：** Android SDK、NDK（Flutter 會自動下載所需版本）和 JDK 17。首次建置要下載這些，會比較慢。
若報「Could not find Ninja」，請在 SDK Manager 安裝 CMake，或執行 `pip install ninja`。
記憶體小於 8 GB 的機器可調低 `android/gradle.properties` 的 `org.gradle.jvmargs`。

Release 版本目前使用 **debug 簽名**；正式發佈前請建立自己的 keystore
（見 <https://docs.flutter.dev/deployment/android#sign-the-app>）。

**隱私提醒：** Flutter 的 release 建置會把專案資料夾的絕對路徑（例如
`file:///home/<使用者>/…/dart_plugin_registrant.dart`）寫進 `libapp.so`。公開發佈時，請在中性的目錄
或 CI 上建置（GitHub Actions 的流程就是如此），避免本機使用者名稱出現在 APK 裡。

背景運行使用前台服務（麥克風 + 媒體播放類型）。在小米、華為、OPPO、vivo、三星等機型上，
請同時在 amakawa 的「設定 → 背景運行」允許忽略電池最佳化。

## GitHub Actions

`.github/workflows/build.yml` 可在雲端同時編出 macOS、Windows 和 Android。把專案推到 GitHub，
進入 *Actions → build → Run workflow*，即可在該次執行的 Artifacts 下載 dmg、zip 和 apk。

## 常見問題

| 現象 | 處理 |
|---|---|
| 顯示「無法開啟音訊裝置」 | 確認系統有輸入和輸出裝置；在「設定 → 音訊裝置」手動選擇 |
| 監聽時嘯叫 | 戴上耳機，或關閉監聽 |
| Windows 找不到 `amakawa_core.dll` | 不要只複製 exe，請複製整個 `Release` 資料夾 |
| Windows 編譯報符號連結錯誤 | 開啟開發人員模式 |
| macOS 報 `Pods` 相關錯誤 | `cd macos && pod install --repo-update` |
