# Voice_lab

[English](README.md) · [繁體中文](README.zh-TW.md)

戴著耳機使用的聲音工具：即時聽見自己的聲音，說話或唱歌時同時看到音高、頻譜和語圖。
可以錄音、回放並分析錄音。支援 Android、Windows 和 macOS。

## 功能

- **即時分析**（三個可展開的區塊）
  - **音高 F0**：顯示頻率和音名（含音分偏差）、音量條，以及最近幾秒的音高曲線
  - **即時頻譜**：點住或移動滑鼠可讀出任意位置的頻率與強度
  - **語圖（Heatmap）**：以顏色顯示頻率隨時間的變化，並疊加 F0 軌跡
- **耳機監聽**：低延遲地把麥克風的聲音送進耳機，音量可調（0–300%）。
  還可以設定**監聽延遲**（1、2、3、5 或 8 秒），讓你聽到幾秒前的自己。
- **說完即回放**：按「開始」說話，按「結束並回放」立刻播放剛才的聲音；預設不存檔，由你決定是否保留。
- **錄音與回放**：16 位元 WAV 錄音，可重新命名、刪除、分享。回放時顯示波形、整段語圖和音高軌跡，
  以及播放位置的頻譜與音高（點擊或拖動可跳轉）。
- **背景運行（Android）**：螢幕關閉或切換到其他應用時繼續監聽與錄音（以前台服務和常駐通知實現）。
- **多語言**：English、日本語、简体中文、繁體中文，或跟隨系統；在「設定」中切換。
- 在「設定」中可選擇輸入／輸出裝置、頻譜顯示上限和動態範圍。

## 使用建議

- 請使用**有線耳機**。不戴耳機時喇叭的聲音會被麥克風收回而嘯叫；藍牙耳機通常有 100 ms 以上的延遲。
- 要得到穩定的 F0，請持續穩定地發聲，麥克風不要離嘴太近，以免爆音。

## 編譯

Android、Windows 和 macOS 的詳細步驟見 [BUILD.zh-TW.md](BUILD.zh-TW.md)
（英文版：[BUILD.md](BUILD.md)）。已安裝 Flutter 的話：

```bash
flutter pub get
flutter run            # 在已連接的裝置 / 桌面上執行
make test              # Dart 測試 + C++ DSP 測試
make android           # release APK
```

## 結構

```
lib/                       Flutter 介面（Dart）：畫面、繪圖、狀態、多語言
packages/amakawa_core/     FFI 插件：原生音訊與分析核心
  src/amakawa_core.cpp       全雙工引擎：監聽、延遲線、錄音、回放
  src/dsp.cpp                FFT 頻譜、YIN 音高偵測、音量
  src/miniaudio*             miniaudio（各平台的音訊輸入輸出與解碼）
  lib/amakawa_core.dart      dart:ffi 綁定
  test_native/               DSP 的 C++ 單元測試（不需要音訊硬體）
```

## 新增語言

1. 把 `lib/l10n/app_en.arb` 複製為 `lib/l10n/app_<code>.arb`，翻譯其中的文字。
2. 在 `lib/locale_utils.dart` 的 `kLanguages` 和 `localeFromCode` 中加入該語言。
3. 執行 `make l10n`，再執行 `make test`。

## 已知限制

- 音高只針對單一人聲，範圍 60–1000 Hz。
- Release 版本使用 debug 簽名；正式發佈請設定自己的簽名。
- 尚未嘗試過 Linux 桌面版（原生核心在 Linux 上可編譯並通過測試）。

## 授權

[MIT](LICENSE)。內含的 [miniaudio](https://miniaud.io) 為公有領域 / MIT-0。
