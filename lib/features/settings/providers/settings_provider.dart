import 'package:flutter/material.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/browser_settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  late BrowserSettingsModel _settings;
  static const String _settingsKey = 'current_settings';

  SettingsProvider() {
    _loadSettings();
  }

  BrowserSettingsModel get settings => _settings;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _loadSettings() {
    final box = HiveDatabase.instance.settingsBox;
    final map = box.get(_settingsKey);
    if (map != null && map is Map) {
      _settings = BrowserSettingsModel.fromMap(map);
    } else {
      _settings = BrowserSettingsModel();
    }
  }

  Future<void> _saveSettings() async {
    final box = HiveDatabase.instance.settingsBox;
    await box.put(_settingsKey, _settings.toMap());
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _settings.themeMode = mode;
    await _saveSettings();
  }

  Future<void> setAccentColor(int color) async {
    _settings.accentColor = color;
    await _saveSettings();
  }

  Future<void> setSearchEngine(String engine) async {
    _settings.searchEngine = engine;
    await _saveSettings();
  }

  Future<void> toggleDesktopMode() async {
    _settings.defaultDesktopMode = !_settings.defaultDesktopMode;
    await _saveSettings();
  }

  Future<void> toggleBlockPopups() async {
    _settings.blockPopups = !_settings.blockPopups;
    await _saveSettings();
  }

  Future<void> toggleJavascript() async {
    _settings.javascriptEnabled = !_settings.javascriptEnabled;
    await _saveSettings();
  }

  Future<void> toggleCompactMode() async {
    _settings.compactMode = !_settings.compactMode;
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    _settings = BrowserSettingsModel();
    await _saveSettings();
  }
}
