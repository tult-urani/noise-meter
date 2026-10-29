import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Used when none of the device's languages is supported.
const fallbackLocale = Locale('en');

/// Each language named in itself, in menu order.
const languageNames = {
  'vi': 'Tiếng Việt',
  'en': 'English',
  'ja': '日本語',
};

/// Persists the language the user picked; `null` means follow the device.
abstract interface class LanguageStore {
  Future<String?> loadLanguageCode();

  Future<void> saveLanguageCode(String code);
}

class PrefsLanguageStore implements LanguageStore {
  PrefsLanguageStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'language_code';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> loadLanguageCode() => _prefs.getString(_key);

  @override
  Future<void> saveLanguageCode(String code) => _prefs.setString(_key, code);
}

class LanguageController extends ChangeNotifier {
  LanguageController({required this._store});

  final LanguageStore _store;
  Locale? _locale;

  /// The user's choice, or null to follow the device languages.
  Locale? get locale => _locale;

  Future<void> load() async {
    final code = await _store.loadLanguageCode();
    _locale = _isSupported(code) ? Locale(code!) : null;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!_isSupported(code)) throw ArgumentError.value(code, 'code', 'unsupported language');
    await _store.saveLanguageCode(code);
    _locale = Locale(code);
    notifyListeners();
  }

  static bool _isSupported(String? code) => AppLocalizations.supportedLocales
      .any((locale) => locale.languageCode == code);
}

/// First device language the app supports, else [fallbackLocale].
Locale resolveDeviceLocale(List<Locale>? deviceLocales, Iterable<Locale> supported) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) return locale;
    }
  }
  return fallbackLocale;
}
