class BrowserSettingsModel {
  String themeMode; // 'system', 'light', 'dark'
  int accentColor;
  String searchEngine; // 'google', 'duckduckgo', 'bing', 'yahoo'
  String homepage;
  bool restoreSession;
  bool blockPopups;
  bool compactMode;
  bool defaultDesktopMode;
  bool javascriptEnabled;

  BrowserSettingsModel({
    this.themeMode = 'system',
    this.accentColor = 0xFF1976D2,
    this.searchEngine = 'google',
    this.homepage = 'home',
    this.restoreSession = true,
    this.blockPopups = true,
    this.compactMode = true,
    this.defaultDesktopMode = false,
    this.javascriptEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'accentColor': accentColor,
      'searchEngine': searchEngine,
      'homepage': homepage,
      'restoreSession': restoreSession,
      'blockPopups': blockPopups,
      'compactMode': compactMode,
      'defaultDesktopMode': defaultDesktopMode,
      'javascriptEnabled': javascriptEnabled,
    };
  }

  factory BrowserSettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return BrowserSettingsModel(
      themeMode: map['themeMode'] as String? ?? 'system',
      accentColor: map['accentColor'] as int? ?? 0xFF1976D2,
      searchEngine: map['searchEngine'] as String? ?? 'google',
      homepage: map['homepage'] as String? ?? 'home',
      restoreSession: map['restoreSession'] as bool? ?? true,
      blockPopups: map['blockPopups'] as bool? ?? true,
      compactMode: map['compactMode'] as bool? ?? true,
      defaultDesktopMode: map['defaultDesktopMode'] as bool? ?? false,
      javascriptEnabled: map['javascriptEnabled'] as bool? ?? true,
    );
  }
}
