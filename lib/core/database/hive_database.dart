import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class HiveDatabase {
  static final HiveDatabase instance = HiveDatabase._internal();
  HiveDatabase._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.bookmarksBox),
      Hive.openBox(AppConstants.historyBox),
      Hive.openBox(AppConstants.tabsBox),
      Hive.openBox(AppConstants.tabGroupsBox),
      Hive.openBox(AppConstants.downloadsBox),
      Hive.openBox(AppConstants.shortcutsBox),
      Hive.openBox(AppConstants.recentlyClosedBox),
    ]);

    _isInitialized = true;
    debugPrint('HiveDatabase: all boxes opened successfully.');
  }

  Box get settingsBox => Hive.box(AppConstants.settingsBox);
  Box get bookmarksBox => Hive.box(AppConstants.bookmarksBox);
  Box get historyBox => Hive.box(AppConstants.historyBox);
  Box get tabsBox => Hive.box(AppConstants.tabsBox);
  Box get tabGroupsBox => Hive.box(AppConstants.tabGroupsBox);
  Box get downloadsBox => Hive.box(AppConstants.downloadsBox);
  Box get shortcutsBox => Hive.box(AppConstants.shortcutsBox);
  Box get recentlyClosedBox => Hive.box(AppConstants.recentlyClosedBox);

  Future<void> clearHistory() async {
    await historyBox.clear();
  }

  Future<void> clearAllBrowsingData() async {
    await historyBox.clear();
    await recentlyClosedBox.clear();
  }
}
