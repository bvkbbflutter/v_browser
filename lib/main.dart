import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/database/hive_database.dart';
import 'core/theme/app_theme.dart';
import 'features/audio/providers/audio_provider.dart';
import 'features/audio/services/audio_service.dart';
import 'features/bookmarks/providers/bookmark_provider.dart';
import 'features/browser/providers/browser_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/downloads/providers/download_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/tabs/providers/tab_provider.dart';
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications & prompt permissions on Android 13+
  await LocalNotificationServiceV().initNotifications();
  await LocalNotificationServiceV().requestPermission();

  // Initialize Android MediaSession Foreground Service via audio_service
  await AudioService.init();

  // Initialize Hive Persistence
  await HiveDatabase.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const VBrowserApp(),
    ),
  );
}

class VBrowserApp extends StatelessWidget {
  const VBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final tabProvider = context.watch<TabProvider>();
    final isIncognito = tabProvider.isIncognitoMode;
    final accentColor = settingsProvider.settings.accentColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: isIncognito
          ? AppTheme.incognitoTheme()
          : AppTheme.lightTheme(accentColor),
      darkTheme: isIncognito
          ? AppTheme.incognitoTheme()
          : AppTheme.darkTheme(accentColor),
      themeMode: isIncognito ? ThemeMode.dark : settingsProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
