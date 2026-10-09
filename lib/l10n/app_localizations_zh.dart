// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tabLive => '实时';

  @override
  String get tabRecordings => '录音';

  @override
  String get sectionPitch => '音高 (F0)';

  @override
  String get sectionSpectrum => '实时频谱';

  @override
  String get sectionSpectrogram => '语图';

  @override
  String levelDb(int db) {
    return '音量 $db dB';
  }

  @override
  String get monitorOn => '开启耳机监听';

  @override
  String get monitorOff => '关闭耳机监听';

  @override
  String get monitorWarning => '请佩戴耳机，否则扬声器的声音会被麦克风收回而啸叫。';

  @override
  String get delayTooltip => '监听延迟';

  @override
  String get delayRealtime => '延迟：实时';

  @override
  String delaySeconds(int seconds) {
    return '延迟：$seconds 秒';
  }

  @override
  String get delayMenuRealtime => '实时（无延迟）';

  @override
  String delayMenuSeconds(int seconds) {
    return '延迟 $seconds 秒';
  }

  @override
  String bufferLatency(int ms) {
    return '（缓冲 ≈ $ms ms）';
  }

  @override
  String get record => '录音';

  @override
  String get stop => '停止';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get retry => '重试';

  @override
  String get settingsTitle => '设置';

  @override
  String get recordingSaved => '录音已保存，可在“录音”标签页查看。';

  @override
  String get takeHint => '说完即回放（不保存）';

  @override
  String get takeStart => '开始';

  @override
  String takeSpeaking(String time) {
    return '录制中 $time';
  }

  @override
  String get takeStopAndReplay => '结束并回放';

  @override
  String get takePlaying => '回放中';

  @override
  String get takeFinished => '回放结束';

  @override
  String get takeReplay => '再播一次';

  @override
  String get takeSave => '保存这一段';

  @override
  String get takeDiscard => '丢弃';

  @override
  String get takeRecordAgain => '再录一次';

  @override
  String get takeSaved => '已保存到“录音”标签页。';

  @override
  String get errMicPermission => '需要麦克风权限才能使用。请在系统设置中允许 amakawa 使用麦克风。';

  @override
  String errOpenDevice(int code) {
    return '无法打开音频设备（错误码 $code）。请检查麦克风和耳机是否已连接。';
  }

  @override
  String errRecordStart(int code) {
    return '无法开始录音（错误码 $code）';
  }

  @override
  String get recordingsEmpty => '还没有录音。回到“实时”页按下录音键开始。';

  @override
  String savedIn(String path) {
    return '保存位置：$path';
  }

  @override
  String get menuRename => '重命名';

  @override
  String get menuShare => '导出 / 分享';

  @override
  String get menuDelete => '删除';

  @override
  String get renameTitle => '重命名';

  @override
  String get deleteTitle => '删除录音？';

  @override
  String get delete => '删除';

  @override
  String get cannotOpenRecording => '无法打开此录音文件';

  @override
  String get playbackHint => '点击或拖动语图可跳转；频谱和音高显示播放位置的分析';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get spectrumRange => '频谱显示上限';

  @override
  String get dynamicRange => '动态范围';

  @override
  String get audioDevices => '音频设备';

  @override
  String get inputDevice => '输入（麦克风）';

  @override
  String get outputDevice => '输出（耳机）';

  @override
  String get systemDefault => '系统默认';

  @override
  String get applyDevices => '应用设备';

  @override
  String latencyTip(int ms) {
    return '提示：有线耳机延迟最低；蓝牙耳机通常有 100 ms 以上的延迟。当前缓冲延迟约 $ms ms。';
  }

  @override
  String get backgroundTitle => '后台运行';

  @override
  String get backgroundKeepRunning => '息屏或切换到其他应用时继续运行';

  @override
  String get backgroundKeepRunningHint => '会显示常驻通知（Android 的要求）';

  @override
  String get serviceRunning => '后台服务：已启动';

  @override
  String get serviceStopped => '后台服务：未启动';

  @override
  String serviceReason(String reason) {
    return '原因：$reason';
  }

  @override
  String backgroundStartFailed(String reason) {
    return '后台运行未能启动：$reason（设置 → 后台运行）';
  }

  @override
  String get notificationsAllowed => '通知权限：已允许';

  @override
  String get notificationsDenied => '通知权限：未允许';

  @override
  String get notificationsHint => '后台运行时需要用它来显示运行通知';

  @override
  String get allow => '允许';

  @override
  String get batteryOk => '已允许忽略电池优化';

  @override
  String get batteryWarn => '电池优化可能会中断后台运行';

  @override
  String get batteryHint => '小米、华为、OPPO、vivo、三星等会严格限制后台的机型建议开启';

  @override
  String get notifChannelName => 'amakawa 后台运行';

  @override
  String get notifChannelDescription => '监听或录音时保持 amakawa 在后台运行';

  @override
  String get notifIdle => '分析运行中 — 点击返回应用';

  @override
  String get notifRecording => '录音中';

  @override
  String get notifMonitoring => '耳机监听中';

  @override
  String get notifPlayback => '回放中';

  @override
  String get notifTake => '录制中（结束后回放）';

  @override
  String notifBusy(String parts) {
    return '$parts — 点击返回应用';
  }

  @override
  String get listSeparator => '、';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get tabLive => '即時';

  @override
  String get tabRecordings => '錄音';

  @override
  String get sectionPitch => '音高 (F0)';

  @override
  String get sectionSpectrum => '即時頻譜';

  @override
  String get sectionSpectrogram => '語圖';

  @override
  String levelDb(int db) {
    return '音量 $db dB';
  }

  @override
  String get monitorOn => '開啟耳機監聽';

  @override
  String get monitorOff => '關閉耳機監聽';

  @override
  String get monitorWarning => '請佩戴耳機，否則喇叭的聲音會被麥克風收回而嘯叫。';

  @override
  String get delayTooltip => '監聽延遲';

  @override
  String get delayRealtime => '延遲：即時';

  @override
  String delaySeconds(int seconds) {
    return '延遲：$seconds 秒';
  }

  @override
  String get delayMenuRealtime => '即時（無延遲）';

  @override
  String delayMenuSeconds(int seconds) {
    return '延遲 $seconds 秒';
  }

  @override
  String bufferLatency(int ms) {
    return '（緩衝 ≈ $ms ms）';
  }

  @override
  String get record => '錄音';

  @override
  String get stop => '停止';

  @override
  String get cancel => '取消';

  @override
  String get ok => '確定';

  @override
  String get retry => '重試';

  @override
  String get settingsTitle => '設定';

  @override
  String get recordingSaved => '錄音已儲存，可在「錄音」頁籤查看。';

  @override
  String get takeHint => '說完即回放（不存檔）';

  @override
  String get takeStart => '開始';

  @override
  String takeSpeaking(String time) {
    return '錄製中 $time';
  }

  @override
  String get takeStopAndReplay => '結束並回放';

  @override
  String get takePlaying => '回放中';

  @override
  String get takeFinished => '回放結束';

  @override
  String get takeReplay => '再播一次';

  @override
  String get takeSave => '儲存這一段';

  @override
  String get takeDiscard => '丟棄';

  @override
  String get takeRecordAgain => '再錄一次';

  @override
  String get takeSaved => '已儲存到「錄音」頁籤。';

  @override
  String get errMicPermission => '需要麥克風權限才能使用。請在系統設定中允許 amakawa 使用麥克風。';

  @override
  String errOpenDevice(int code) {
    return '無法開啟音訊裝置（錯誤碼 $code）。請檢查麥克風與耳機是否已連接。';
  }

  @override
  String errRecordStart(int code) {
    return '無法開始錄音（錯誤碼 $code）';
  }

  @override
  String get recordingsEmpty => '還沒有錄音。回到「即時」頁按下錄音鍵開始。';

  @override
  String savedIn(String path) {
    return '儲存位置：$path';
  }

  @override
  String get menuRename => '重新命名';

  @override
  String get menuShare => '匯出 / 分享';

  @override
  String get menuDelete => '刪除';

  @override
  String get renameTitle => '重新命名';

  @override
  String get deleteTitle => '刪除錄音？';

  @override
  String get delete => '刪除';

  @override
  String get cannotOpenRecording => '無法開啟此錄音檔';

  @override
  String get playbackHint => '點擊或拖動語圖可跳轉；頻譜與音高顯示播放位置的分析';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get spectrumRange => '頻譜顯示上限';

  @override
  String get dynamicRange => '動態範圍';

  @override
  String get audioDevices => '音訊裝置';

  @override
  String get inputDevice => '輸入（麥克風）';

  @override
  String get outputDevice => '輸出（耳機）';

  @override
  String get systemDefault => '系統預設';

  @override
  String get applyDevices => '套用裝置';

  @override
  String latencyTip(int ms) {
    return '提示：有線耳機延遲最低；藍牙耳機通常有 100 ms 以上的延遲。目前緩衝延遲約 $ms ms。';
  }

  @override
  String get backgroundTitle => '背景運行';

  @override
  String get backgroundKeepRunning => '螢幕關閉或切換到其他應用時繼續運行';

  @override
  String get backgroundKeepRunningHint => '會顯示常駐通知（Android 的要求）';

  @override
  String get serviceRunning => '背景服務：已啟動';

  @override
  String get serviceStopped => '背景服務：未啟動';

  @override
  String serviceReason(String reason) {
    return '原因：$reason';
  }

  @override
  String backgroundStartFailed(String reason) {
    return '背景運行未能啟動：$reason（設定 → 背景運行）';
  }

  @override
  String get notificationsAllowed => '通知權限：已允許';

  @override
  String get notificationsDenied => '通知權限：未允許';

  @override
  String get notificationsHint => '背景運行時需要用它來顯示運行通知';

  @override
  String get allow => '允許';

  @override
  String get batteryOk => '已允許忽略電池最佳化';

  @override
  String get batteryWarn => '電池最佳化可能會中斷背景運行';

  @override
  String get batteryHint => '小米、華為、OPPO、vivo、三星等會嚴格限制背景的機型建議開啟';

  @override
  String get notifChannelName => 'amakawa 背景運行';

  @override
  String get notifChannelDescription => '監聽或錄音時保持 amakawa 在背景運行';

  @override
  String get notifIdle => '分析運行中 — 點擊返回應用';

  @override
  String get notifRecording => '錄音中';

  @override
  String get notifMonitoring => '耳機監聽中';

  @override
  String get notifPlayback => '回放中';

  @override
  String get notifTake => '錄製中（結束後回放）';

  @override
  String notifBusy(String parts) {
    return '$parts — 點擊返回應用';
  }

  @override
  String get listSeparator => '、';
}
