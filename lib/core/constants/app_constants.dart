class AppConstants {
  static const String appName = 'Vortex Browser';
  static const String appTagline = 'Fast · Private · Secure';

  // Hive Box Names
  static const String settingsBox = 'app_settings';
  static const String bookmarksBox = 'bookmarks';
  static const String historyBox = 'browsing_history';
  static const String tabsBox = 'tabs';
  static const String tabGroupsBox = 'tab_groups';
  static const String downloadsBox = 'downloads';
  static const String shortcutsBox = 'dashboard_shortcuts';
  static const String recentlyClosedBox = 'recently_closed_tabs';

  // Search Engine Base URLs
  static const Map<String, String> searchEngines = {
    'google': 'https://www.google.com/search?q=',
    'duckduckgo': 'https://duckduckgo.com/?q=',
    'bing': 'https://www.bing.com/search?q=',
    'yahoo': 'https://search.yahoo.com/search?p=',
  };

  static const Map<String, String> searchEngineNames = {
    'google': 'Google',
    'duckduckgo': 'DuckDuckGo',
    'bing': 'Bing',
    'yahoo': 'Yahoo',
  };

  // User Agents
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static String buildSearchUrl(String engineKey, String query) {
    final base = searchEngines[engineKey] ?? searchEngines['google']!;
    return '$base${Uri.encodeComponent(query)}';
  }

  static bool isLikelyUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return true;
    }
    // Check if it has a valid domain-like structure without spaces
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+(:\d+)?(/.*)?$',
    );
    return !trimmed.contains(' ') && domainRegex.hasMatch(trimmed);
  }

  static String normalizeUrl(String input, {String searchEngine = 'google'}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'about:blank';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('about:')) {
      return trimmed;
    }
    if (isLikelyUrl(trimmed)) {
      return 'https://$trimmed';
    }
    return buildSearchUrl(searchEngine, trimmed);
  }

  static String getDisplayHost(String url) {
    if (url.isEmpty || url == 'about:blank' || url == 'home') return 'Home';
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  static String getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return '';
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }
}
