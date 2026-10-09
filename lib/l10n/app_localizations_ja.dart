// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tabLive => 'ライブ';

  @override
  String get tabRecordings => '録音';

  @override
  String get sectionPitch => 'ピッチ（F0）';

  @override
  String get sectionSpectrum => 'リアルタイムスペクトル';

  @override
  String get sectionSpectrogram => 'スペクトログラム';

  @override
  String levelDb(int db) {
    return 'レベル $db dB';
  }

  @override
  String get monitorOn => 'ヘッドホンモニターをオンにする';

  @override
  String get monitorOff => 'ヘッドホンモニターをオフにする';

  @override
  String get monitorWarning => 'ヘッドホンを着用してください。スピーカーの音をマイクが拾うとハウリングします。';

  @override
  String get delayTooltip => 'モニターの遅延';

  @override
  String get delayRealtime => '遅延：なし';

  @override
  String delaySeconds(int seconds) {
    return '遅延：$seconds 秒';
  }

  @override
  String get delayMenuRealtime => 'リアルタイム（遅延なし）';

  @override
  String delayMenuSeconds(int seconds) {
    return '$seconds 秒遅延';
  }

  @override
  String bufferLatency(int ms) {
    return '（バッファ ≈ $ms ms）';
  }

  @override
  String get record => '録音';

  @override
  String get stop => '停止';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get retry => '再試行';

  @override
  String get settingsTitle => '設定';

  @override
  String get recordingSaved => '録音を保存しました。「録音」タブで確認できます。';

  @override
  String get takeHint => '話してすぐ再生（保存しません）';

  @override
  String get takeStart => '開始';

  @override
  String takeSpeaking(String time) {
    return '録音中 $time';
  }

  @override
  String get takeStopAndReplay => '停止して再生';

  @override
  String get takePlaying => '再生中';

  @override
  String get takeFinished => '再生終了';

  @override
  String get takeReplay => 'もう一度再生';

  @override
  String get takeSave => 'この録音を保存';

  @override
  String get takeDiscard => '破棄';

  @override
  String get takeRecordAgain => '録り直す';

  @override
  String get takeSaved => '「録音」タブに保存しました。';

  @override
  String get errMicPermission =>
      'マイクの許可が必要です。システム設定で amakawa にマイクの使用を許可してください。';

  @override
  String errOpenDevice(int code) {
    return 'オーディオデバイスを開けませんでした（エラー $code）。マイクとヘッドホンが接続されているか確認してください。';
  }

  @override
  String errRecordStart(int code) {
    return '録音を開始できませんでした（エラー $code）';
  }

  @override
  String get recordingsEmpty => '録音はまだありません。「ライブ」タブの録音ボタンで始めましょう。';

  @override
  String savedIn(String path) {
    return '保存先：$path';
  }

  @override
  String get menuRename => '名前を変更';

  @override
  String get menuShare => '書き出し / 共有';

  @override
  String get menuDelete => '削除';

  @override
  String get renameTitle => '名前を変更';

  @override
  String get deleteTitle => '録音を削除しますか？';

  @override
  String get delete => '削除';

  @override
  String get cannotOpenRecording => 'この録音を開けません';

  @override
  String get playbackHint => 'スペクトログラムをタップまたはドラッグで移動。スペクトルとピッチは再生位置の解析を表示します。';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムに従う';

  @override
  String get spectrumRange => 'スペクトル範囲';

  @override
  String get dynamicRange => 'ダイナミックレンジ';

  @override
  String get audioDevices => 'オーディオデバイス';

  @override
  String get inputDevice => '入力（マイク）';

  @override
  String get outputDevice => '出力（ヘッドホン）';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get applyDevices => 'デバイスを適用';

  @override
  String latencyTip(int ms) {
    return 'ヒント：有線ヘッドホンが最も低遅延です。Bluetooth ヘッドホンは通常 100 ms 以上の遅延があります。現在のバッファ遅延は約 $ms ms です。';
  }

  @override
  String get backgroundTitle => 'バックグラウンド';

  @override
  String get backgroundKeepRunning => '画面オフや他のアプリ使用中も動作を続ける';

  @override
  String get backgroundKeepRunningHint => '常駐通知が表示されます（Android の要件）';

  @override
  String get serviceRunning => 'バックグラウンドサービス：動作中';

  @override
  String get serviceStopped => 'バックグラウンドサービス：停止中';

  @override
  String serviceReason(String reason) {
    return '理由：$reason';
  }

  @override
  String backgroundStartFailed(String reason) {
    return 'バックグラウンド動作を開始できませんでした：$reason（設定 → バックグラウンド）';
  }

  @override
  String get notificationsAllowed => '通知：許可済み';

  @override
  String get notificationsDenied => '通知：未許可';

  @override
  String get notificationsHint => 'バックグラウンド動作中の通知を表示するために必要です';

  @override
  String get allow => '許可';

  @override
  String get batteryOk => 'このアプリはバッテリー最適化の対象外です';

  @override
  String get batteryWarn => 'バッテリー最適化によりバックグラウンド音声が止まる場合があります';

  @override
  String get batteryHint =>
      'バックグラウンドアプリを強く制限する機種（Xiaomi、Huawei、OPPO、vivo、Samsung など）で推奨';

  @override
  String get notifChannelName => 'amakawa バックグラウンド動作';

  @override
  String get notifChannelDescription => 'モニターや録音中に amakawa をバックグラウンドで動作させ続けます';

  @override
  String get notifIdle => '解析中 — タップで戻る';

  @override
  String get notifRecording => '録音中';

  @override
  String get notifMonitoring => 'モニター中';

  @override
  String get notifPlayback => '再生中';

  @override
  String get notifTake => '録音中（停止後に再生）';

  @override
  String notifBusy(String parts) {
    return '$parts — タップで戻る';
  }

  @override
  String get listSeparator => '、';
}
