import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../history/providers/history_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // APPEARANCE SECTION
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(
              settings.themeMode[0].toUpperCase() + settings.themeMode.substring(1),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showThemeDialog(context, settingsProvider),
          ),
          ListTile(
            title: const Text('Accent Color'),
            trailing: CircleAvatar(
              backgroundColor: Color(settings.accentColor),
              radius: 12,
            ),
            onTap: () => _showColorPicker(context, settingsProvider),
          ),
          SwitchListTile(
            title: const Text('Compact Controls Mode'),
            subtitle: const Text('Minimizes URL and bottom nav to maximize webpage space'),
            value: settings.compactMode,
            onChanged: (val) => settingsProvider.toggleCompactMode(),
          ),

          const Divider(),

          // GENERAL SECTION
          const _SectionHeader(title: 'General & Search'),
          ListTile(
            title: const Text('Default Search Engine'),
            subtitle: Text(AppConstants.searchEngineNames[settings.searchEngine] ?? 'Google'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showSearchEngineDialog(context, settingsProvider),
          ),
          SwitchListTile(
            title: const Text('Default to Desktop Site'),
            subtitle: const Text('Always request desktop versions of websites'),
            value: settings.defaultDesktopMode,
            onChanged: (val) => settingsProvider.toggleDesktopMode(),
          ),

          const Divider(),

          // PRIVACY & SECURITY
          const _SectionHeader(title: 'Privacy & Security'),
          SwitchListTile(
            title: const Text('Block Pop-up Windows'),
            value: settings.blockPopups,
            onChanged: (val) => settingsProvider.toggleBlockPopups(),
          ),
          SwitchListTile(
            title: const Text('Enable JavaScript'),
            subtitle: const Text('Required for interactive websites'),
            value: settings.javascriptEnabled,
            onChanged: (val) => settingsProvider.toggleJavascript(),
          ),
          ListTile(
            title: const Text('Clear Browsing Data', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Clear history, cookies, and cache'),
            onTap: () => _showClearDataDialog(context),
          ),

          const Divider(),

          // ABOUT SECTION
          const _SectionHeader(title: 'About'),
          const ListTile(
            title: Text(AppConstants.appName),
            subtitle: Text('Version 1.0.0 · Fast, Secure & Minimal Flutter Browser'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            subtitle: const Text('No tracking, offline-first local Hive storage'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'V-Browser is built with privacy as a foundational principle. '
                    'All bookmarks, history, and settings are stored locally on your device using Hive. '
                    'In Incognito mode, no browsing history, caches, or searches are saved.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          RadioListTile<String>(
            title: const Text('System Default'),
            value: 'system',
            groupValue: provider.settings.themeMode,
            onChanged: (val) {
              provider.setThemeMode(val!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<String>(
            title: const Text('Light'),
            value: 'light',
            groupValue: provider.settings.themeMode,
            onChanged: (val) {
              provider.setThemeMode(val!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<String>(
            title: const Text('Dark'),
            value: 'dark',
            groupValue: provider.settings.themeMode,
            onChanged: (val) {
              provider.setThemeMode(val!);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Accent Color'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppTheme.availableAccents.map((c) {
            final isSel = provider.settings.accentColor == c;
            return GestureDetector(
              onTap: () {
                provider.setAccentColor(c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: isSel ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSearchEngineDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Default Search Engine'),
        children: AppConstants.searchEngines.keys.map((engine) {
          return RadioListTile<String>(
            title: Text(AppConstants.searchEngineNames[engine] ?? engine),
            value: engine,
            groupValue: provider.settings.searchEngine,
            onChanged: (val) {
              provider.setSearchEngine(val!);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Browsing Data?'),
        content: const Text(
          'This will clear all browsing history, recently closed tabs, and WebView web storage.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveDatabase.instance.clearAllBrowsingData();
              if (context.mounted) {
                context.read<HistoryProvider>().clearAll();
              }
              // Clear InAppWebView cookies and cache if available
              try {
                final cookieManager = CookieManager.instance();
                await cookieManager.deleteAllCookies();
              } catch (_) {}
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Browsing data cleared.')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
