/// Which theme is in force, and how it changes.
///
/// Two things have to happen together when the theme changes, in this order:
///
///  1. [AppColors] is pointed at the new palette.
///  2. The whole tree rebuilds.
///
/// The order is the whole trick. Every token in `app_theme.dart` is a getter
/// over one active palette rather than a per-widget lookup, which is what let
/// dark mode arrive without rewriting three hundred call sites — but it also
/// means a widget that rebuilt *before* the swap would paint in the old
/// palette. So the swap happens synchronously inside the same notification
/// that triggers the rebuild, and never anywhere else.
///
/// Following the system is the default, and it is not a one-time read: the OS
/// can flip at sunset while the app is open, and `WidgetsBindingObserver`
/// catches that.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

import 'app_theme.dart';

/// How the app decides between light and dark.
enum AppThemeMode {
  /// Follow the phone. The default, and what most people want.
  system(label: 'Match my phone', icon: Icons.brightness_auto_rounded),

  light(label: 'Always light', icon: Icons.light_mode_rounded),

  dark(label: 'Always dark', icon: Icons.dark_mode_rounded);

  const AppThemeMode({required this.label, required this.icon});

  final String label;
  final IconData icon;

  ThemeMode get materialMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  static AppThemeMode fromName(String? name) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return AppThemeMode.system;
  }
}

/// Owns the theme choice and keeps [AppColors] in step with it.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
    _syncPalette();
  }

  /// Stored as a small JSON file in the app support directory, the same way
  /// `FCMService` persists its reminder state. `shared_preferences` would do
  /// this too, but it is not already a dependency and one preference is not
  /// worth a package.
  static const String _fileName = 'avahanaa_theme_v1.json';

  Future<File> _prefsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  /// The brightness actually being rendered, which is what the UI should
  /// describe. In [AppThemeMode.system] this is the platform's answer, not the
  /// user's choice — "Match my phone" is not a brightness.
  Brightness get effectiveBrightness => switch (_mode) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.system => _platformBrightness,
  };

  bool get isDark => effectiveBrightness == Brightness.dark;

  Brightness get _platformBrightness =>
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  /// Reads the saved choice. Safe to call before `runApp`.
  Future<void> load() async {
    try {
      final file = await _prefsFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        _mode = AppThemeMode.fromName(
          data is Map<String, dynamic> ? data['mode'] as String? : null,
        );
      }
    } catch (e) {
      // A theme preference is not worth failing a launch over. System is a
      // reasonable answer to every question this could have asked.
      debugPrint('Could not read the saved theme: $e');
      _mode = AppThemeMode.system;
    }
    _syncPalette();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;

    // Palette first, then listeners. See the note at the top of this file.
    _syncPalette();
    notifyListeners();

    try {
      final file = await _prefsFile();
      await file.writeAsString(jsonEncode({'mode': mode.name}));
    } catch (e) {
      debugPrint('Could not save the theme choice: $e');
    }
  }

  /// Steps light → dark → system → light.
  ///
  /// For the one-tap control in the app bar. System sits last because it is
  /// the destination people return to, not one they pass through.
  Future<void> cycle() {
    return setMode(switch (_mode) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
      AppThemeMode.system => AppThemeMode.light,
    });
  }

  /// The OS flipped while the app was open — sunset, battery saver, or the
  /// user changing it in Settings and coming back.
  @override
  void didChangePlatformBrightness() {
    if (_mode != AppThemeMode.system) return;
    _syncPalette();
    notifyListeners();
  }

  void _syncPalette() {
    AppColors.usePalette(
      isDark ? AvahanaaPalette.dark : AvahanaaPalette.light,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
