import 'dart:ui' show Locale;

/// Languages the user can pick, keyed by the value stored in settings.
/// Names are shown in their own language on purpose.
const Map<String, String> kLanguages = {
  'en': 'English',
  'ja': '日本語',
  'zh_Hans': '简体中文',
  'zh_Hant': '繁體中文',
};

/// Maps a settings key to a [Locale]; '' (or anything unknown) means "follow the system".
Locale? localeFromCode(String code) {
  switch (code) {
    case 'en':
      return const Locale('en');
    case 'ja':
      return const Locale('ja');
    case 'zh_Hans':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    case 'zh_Hant':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  return null;
}

/// Picks the best supported locale for a device locale. Chinese is split by
/// script (Traditional for zh-Hant / TW / HK / MO, Simplified otherwise);
/// anything unsupported falls back to English.
Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  const fallback = Locale('en');
  if (device == null) return fallback;
  if (device.languageCode == 'zh') {
    final traditional =
        device.scriptCode == 'Hant' ||
        (device.scriptCode == null &&
            const {'TW', 'HK', 'MO'}.contains(device.countryCode));
    return Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: traditional ? 'Hant' : 'Hans',
    );
  }
  for (final l in supported) {
    if (l.languageCode == device.languageCode) return l;
  }
  return fallback;
}
