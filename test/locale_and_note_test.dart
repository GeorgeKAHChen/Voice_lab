import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:amakawa/l10n/app_localizations.dart';
import 'package:amakawa/locale_utils.dart';
import 'package:amakawa/widgets/pitch_readout.dart';

void main() {
  group('noteName', () {
    test('A4 is exactly in tune', () => expect(noteName(440), 'A4 +0¢'));
    test('middle C', () => expect(noteName(261.63), 'C4 +0¢'));
    test('reports the deviation in cents', () {
      expect(noteName(440 * math.pow(2, 25 / 1200).toDouble()), 'A4 +25¢');
      expect(noteName(440 * math.pow(2, -30 / 1200).toDouble()), 'A4 -30¢');
    });
    test('sharps use the ♯ sign', () => expect(noteName(466.16), 'A♯4 +0¢'));
    test('non-positive input has no note', () => expect(noteName(0), ''));
  });

  group('resolveLocale', () {
    final supported = AppLocalizations.supportedLocales;

    test('English, Japanese and Chinese are matched by language', () {
      expect(
        resolveLocale(const Locale('en', 'US'), supported).languageCode,
        'en',
      );
      expect(
        resolveLocale(const Locale('ja', 'JP'), supported).languageCode,
        'ja',
      );
    });

    test('Traditional Chinese for Hant, TW, HK and MO', () {
      for (final l in [
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        const Locale('zh', 'TW'),
        const Locale('zh', 'HK'),
        const Locale('zh', 'MO'),
      ]) {
        expect(resolveLocale(l, supported).scriptCode, 'Hant', reason: '$l');
      }
    });

    test('Simplified Chinese otherwise', () {
      expect(
        resolveLocale(const Locale('zh', 'CN'), supported).scriptCode,
        'Hans',
      );
      expect(resolveLocale(const Locale('zh'), supported).scriptCode, 'Hans');
    });

    test('unsupported languages fall back to English', () {
      expect(resolveLocale(const Locale('fr'), supported), const Locale('en'));
      expect(resolveLocale(null, supported), const Locale('en'));
    });
  });

  group('localizations', () {
    test('every language option is provided by the generated delegate', () {
      for (final code in kLanguages.keys) {
        final locale = localeFromCode(code)!;
        expect(
          AppLocalizations.delegate.isSupported(locale),
          isTrue,
          reason: code,
        );
        expect(lookupAppLocalizations(locale).tabLive, isNotEmpty);
      }
    });

    test('Traditional and Simplified Chinese differ', () {
      final hans = lookupAppLocalizations(localeFromCode('zh_Hans')!);
      final hant = lookupAppLocalizations(localeFromCode('zh_Hant')!);
      expect(hans.tabRecordings, '录音');
      expect(hant.tabRecordings, '錄音');
    });

    test('placeholders are filled', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.delaySeconds(3), 'Delay: 3 s');
      expect(en.errOpenDevice(7), contains('error 7'));
    });
  });
}
