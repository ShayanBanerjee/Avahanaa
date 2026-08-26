/// Which language the app speaks.
///
/// Avahanaa ships in Bangalore. The printed sticker has been bilingual since
/// the beginning — English and Kannada, because the person standing at the car
/// may not read English — while the app itself was English-only. So an owner
/// could read the sticker on their own windscreen and not the alert it
/// produced.
///
/// Following the phone is the default. The explicit override exists because a
/// phone set to English by whoever sold it is common here, and it says nothing
/// about what its owner reads most comfortably.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// The languages the app is translated into.
enum AppLanguage {
  /// Follow the phone, falling back to English for anything unsupported.
  system(code: null, label: 'Match my phone', endonym: 'Match my phone'),

  english(code: 'en', label: 'English', endonym: 'English'),

  /// Labelled in Kannada, because someone looking for it will be reading
  /// Kannada, not English.
  kannada(code: 'kn', label: 'Kannada', endonym: 'ಕನ್ನಡ');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.endonym,
  });

  /// The locale code, or null to follow the platform.
  final String? code;

  /// The English name, for logs and settings subtitles.
  final String label;

  /// The name in its own language, which is what the picker shows.
  final String endonym;

  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromName(String? name) {
    for (final language in AppLanguage.values) {
      if (language.name == name) return language;
    }
    return AppLanguage.system;
  }
}

/// Owns the language choice and persists it.
class LocaleController extends ChangeNotifier {
  static const String _fileName = 'avahanaa_locale_v1.json';

  AppLanguage _language = AppLanguage.system;
  AppLanguage get language => _language;

  /// Null means "let MaterialApp resolve it from the platform".
  Locale? get locale => _language.locale;

  Future<File> _prefsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> load() async {
    try {
      final file = await _prefsFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        _language = AppLanguage.fromName(
          data is Map<String, dynamic> ? data['language'] as String? : null,
        );
      }
    } catch (e) {
      // Never worth failing a launch over. English is a safe answer, and the
      // platform default is a better one.
      debugPrint('Could not read the saved language: $e');
      _language = AppLanguage.system;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();

    try {
      final file = await _prefsFile();
      await file.writeAsString(jsonEncode({'language': language.name}));
    } catch (e) {
      debugPrint('Could not save the language choice: $e');
    }
  }
}
