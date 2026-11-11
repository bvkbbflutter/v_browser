import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/dashboard_shortcut_model.dart';

class DashboardProvider extends ChangeNotifier {
  List<DashboardShortcutModel> _shortcuts = [];

  List<DashboardShortcutModel> get shortcuts => _shortcuts;

  DashboardProvider() {
    _loadShortcuts();
  }

  void _loadShortcuts() {
    final box = HiveDatabase.instance.shortcutsBox;
    if (box.isEmpty) {
      _shortcuts = [
        DashboardShortcutModel(
          id: '1',
          title: 'Google',
          url: 'https://google.com',
          favicon: AppConstants.getFaviconUrl('https://google.com'),
          position: 0,
        ),
        DashboardShortcutModel(
          id: '2',
          title: 'YouTube',
          url: 'https://youtube.com',
          favicon: AppConstants.getFaviconUrl('https://youtube.com'),
          position: 1,
        ),
        DashboardShortcutModel(
          id: '3',
          title: 'GitHub',
          url: 'https://github.com',
          favicon: AppConstants.getFaviconUrl('https://github.com'),
          position: 2,
        ),
        DashboardShortcutModel(
          id: '4',
          title: 'Wikipedia',
          url: 'https://wikipedia.org',
          favicon: AppConstants.getFaviconUrl('https://wikipedia.org'),
          position: 3,
        ),
        DashboardShortcutModel(
          id: '5',
          title: 'Reddit',
          url: 'https://reddit.com',
          favicon: AppConstants.getFaviconUrl('https://reddit.com'),
          position: 4,
        ),
        DashboardShortcutModel(
          id: '6',
          title: 'X / Twitter',
          url: 'https://x.com',
          favicon: AppConstants.getFaviconUrl('https://x.com'),
          position: 5,
        ),
      ];
      _saveAll();
    } else {
      _shortcuts = box.values
          .map((item) => DashboardShortcutModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    }
  }

  Future<void> _saveAll() async {
    final box = HiveDatabase.instance.shortcutsBox;
    await box.clear();
    for (final s in _shortcuts) {
      await box.put(s.id, s.toMap());
    }
    notifyListeners();
  }

  Future<void> addShortcut(String title, String url) async {
    String normalized = url.trim();
    if (!normalized.startsWith('http')) {
      normalized = 'https://$normalized';
    }
    final shortcut = DashboardShortcutModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? AppConstants.getDisplayHost(normalized) : title.trim(),
      url: normalized,
      favicon: AppConstants.getFaviconUrl(normalized),
      position: _shortcuts.length,
    );
    _shortcuts.add(shortcut);
    await HiveDatabase.instance.shortcutsBox.put(shortcut.id, shortcut.toMap());
    notifyListeners();
  }

  Future<void> editShortcut(String id, String newTitle, String newUrl) async {
    final index = _shortcuts.indexWhere((s) => s.id == id);
    if (index != -1) {
      String normalized = newUrl.trim();
      if (!normalized.startsWith('http')) {
        normalized = 'https://$normalized';
      }
      _shortcuts[index].title = newTitle.trim().isEmpty ? AppConstants.getDisplayHost(normalized) : newTitle.trim();
      _shortcuts[index].url = normalized;
      _shortcuts[index].favicon = AppConstants.getFaviconUrl(normalized);
      await HiveDatabase.instance.shortcutsBox.put(id, _shortcuts[index].toMap());
      notifyListeners();
    }
  }

  Future<void> removeShortcut(String id) async {
    _shortcuts.removeWhere((s) => s.id == id);
    await HiveDatabase.instance.shortcutsBox.delete(id);
    notifyListeners();
  }
}
