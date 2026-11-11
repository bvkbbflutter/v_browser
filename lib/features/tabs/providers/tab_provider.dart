import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/browser_tab_model.dart';
import '../../../core/models/tab_group_model.dart';

class TabProvider extends ChangeNotifier {
  List<BrowserTabModel> _normalTabs = [];
  final List<BrowserTabModel> _incognitoTabs = [];
  List<TabGroupModel> _tabGroups = [];
  List<BrowserTabModel> _recentlyClosed = [];

  String _activeTabId = '';
  bool _showingIncognitoInOverview = false;

  List<BrowserTabModel> get normalTabs => _normalTabs;
  List<BrowserTabModel> get incognitoTabs => _incognitoTabs;
  List<TabGroupModel> get tabGroups => _tabGroups;
  List<BrowserTabModel> get recentlyClosed => _recentlyClosed;
  String get activeTabId => _activeTabId;
  bool get showingIncognitoInOverview => _showingIncognitoInOverview;

  BrowserTabModel get activeTab {
    final all = [..._normalTabs, ..._incognitoTabs];
    final found = all.firstWhere(
      (t) => t.id == _activeTabId,
      orElse: () => _normalTabs.isNotEmpty
          ? _normalTabs.first
          : BrowserTabModel(id: 'default', title: 'Home', url: 'home'),
    );
    return found;
  }

  bool get isIncognitoMode => activeTab.isPrivate;

  TabProvider() {
    _loadState();
  }

  void _loadState() {
    final tabsBox = HiveDatabase.instance.tabsBox;
    final groupsBox = HiveDatabase.instance.tabGroupsBox;
    final recentBox = HiveDatabase.instance.recentlyClosedBox;

    // Load tab groups
    _tabGroups = groupsBox.values
        .map((item) => TabGroupModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();

    // Load recently closed
    _recentlyClosed = recentBox.values
        .map((item) => BrowserTabModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList();

    // Load normal tabs
    if (tabsBox.isNotEmpty) {
      _normalTabs = tabsBox.values
          .map((item) => BrowserTabModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
          .toList();
    }

    if (_normalTabs.isEmpty) {
      final initialTab = BrowserTabModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Home',
        url: 'home',
        favicon: '',
      );
      _normalTabs.add(initialTab);
      _saveNormalTabs();
    }

    _activeTabId = _normalTabs.first.id;
  }

  Future<void> _saveNormalTabs() async {
    final box = HiveDatabase.instance.tabsBox;
    await box.clear();
    for (final tab in _normalTabs) {
      await box.put(tab.id, tab.toMap());
    }
  }

  Future<void> _saveGroups() async {
    final box = HiveDatabase.instance.tabGroupsBox;
    await box.clear();
    for (final group in _tabGroups) {
      await box.put(group.id, group.toMap());
    }
  }

  void setShowingIncognitoInOverview(bool value) {
    _showingIncognitoInOverview = value;
    notifyListeners();
  }

  void switchToTab(String tabId) {
    final all = [..._normalTabs, ..._incognitoTabs];
    final exists = all.any((t) => t.id == tabId);
    if (exists) {
      _activeTabId = tabId;
      final tab = all.firstWhere((t) => t.id == tabId);
      tab.lastAccessedAt = DateTime.now();
      _showingIncognitoInOverview = tab.isPrivate;
      notifyListeners();
    }
  }

  void addNewTab({
    String url = 'home',
    String title = 'Home',
    bool isPrivate = false,
    String? groupId,
  }) {
    final newTab = BrowserTabModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      url: url,
      favicon: url != 'home' && url != 'about:blank' ? AppConstants.getFaviconUrl(url) : '',
      isPrivate: isPrivate,
      groupId: groupId,
    );

    if (isPrivate) {
      _incognitoTabs.add(newTab);
      _showingIncognitoInOverview = true;
    } else {
      _normalTabs.add(newTab);
      _saveNormalTabs();
      _showingIncognitoInOverview = false;
    }

    _activeTabId = newTab.id;
    notifyListeners();
  }

  void closeTab(String tabId) {
    // Check normal tabs
    final normalIndex = _normalTabs.indexWhere((t) => t.id == tabId);
    if (normalIndex != -1) {
      final closed = _normalTabs.removeAt(normalIndex);
      // Save to recently closed (if not a blank home tab)
      if (closed.url != 'home' && closed.url != 'about:blank') {
        _recentlyClosed.insert(0, closed);
        if (_recentlyClosed.length > 20) _recentlyClosed.removeLast();
        HiveDatabase.instance.recentlyClosedBox.put(closed.id, closed.toMap());
      }

      if (_normalTabs.isEmpty) {
        final newTab = BrowserTabModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Home',
          url: 'home',
        );
        _normalTabs.add(newTab);
      }

      _saveNormalTabs();

      if (_activeTabId == tabId) {
        final nextIndex = normalIndex >= _normalTabs.length ? _normalTabs.length - 1 : normalIndex;
        _activeTabId = _normalTabs[nextIndex].id;
      }
      notifyListeners();
      return;
    }

    // Check incognito tabs
    final incognitoIndex = _incognitoTabs.indexWhere((t) => t.id == tabId);
    if (incognitoIndex != -1) {
      _incognitoTabs.removeAt(incognitoIndex);

      if (_activeTabId == tabId) {
        if (_incognitoTabs.isNotEmpty) {
          final nextIndex =
              incognitoIndex >= _incognitoTabs.length ? _incognitoTabs.length - 1 : incognitoIndex;
          _activeTabId = _incognitoTabs[nextIndex].id;
        } else {
          _showingIncognitoInOverview = false;
          _activeTabId = _normalTabs.isNotEmpty ? _normalTabs.first.id : '';
        }
      }
      notifyListeners();
    }
  }

  void closeAllTabs({bool incognitoOnly = false}) {
    if (incognitoOnly) {
      _incognitoTabs.clear();
      _showingIncognitoInOverview = false;
      if (_normalTabs.isNotEmpty) {
        _activeTabId = _normalTabs.first.id;
      }
    } else {
      _incognitoTabs.clear();
      _normalTabs.clear();
      final fresh = BrowserTabModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Home',
        url: 'home',
      );
      _normalTabs.add(fresh);
      _activeTabId = fresh.id;
      _saveNormalTabs();
    }
    notifyListeners();
  }

  void duplicateTab(String tabId) {
    final all = [..._normalTabs, ..._incognitoTabs];
    final original = all.firstWhere((t) => t.id == tabId, orElse: () => activeTab);
    addNewTab(
      url: original.url,
      title: original.title,
      isPrivate: original.isPrivate,
      groupId: original.groupId,
    );
  }

  void restoreRecentlyClosed(BrowserTabModel tab) {
    _recentlyClosed.removeWhere((t) => t.id == tab.id);
    HiveDatabase.instance.recentlyClosedBox.delete(tab.id);
    addNewTab(url: tab.url, title: tab.title, isPrivate: false);
  }

  void updateTabUrl(String tabId, String url, {String? title, String? favicon}) {
    final all = [..._normalTabs, ..._incognitoTabs];
    final index = all.indexWhere((t) => t.id == tabId);
    if (index != -1) {
      final tab = all[index];
      tab.url = url;
      if (title != null && title.isNotEmpty) tab.title = title;
      if (favicon != null) {
        tab.favicon = favicon;
      } else if (url != 'home' && url != 'about:blank') {
        tab.favicon = AppConstants.getFaviconUrl(url);
      }

      if (!tab.isPrivate) {
        HiveDatabase.instance.tabsBox.put(tab.id, tab.toMap());
      }
      notifyListeners();
    }
  }

  void updateTabTitle(String tabId, String title) {
    final all = [..._normalTabs, ..._incognitoTabs];
    final tab = all.firstWhere((t) => t.id == tabId, orElse: () => activeTab);
    tab.title = title;
    if (!tab.isPrivate) {
      HiveDatabase.instance.tabsBox.put(tab.id, tab.toMap());
    }
    notifyListeners();
  }

  void updateTabFavicon(String tabId, String favicon) {
    final all = [..._normalTabs, ..._incognitoTabs];
    final tab = all.firstWhere((t) => t.id == tabId, orElse: () => activeTab);
    tab.favicon = favicon;
    if (!tab.isPrivate) {
      HiveDatabase.instance.tabsBox.put(tab.id, tab.toMap());
    }
    notifyListeners();
  }

  // TAB GROUPS
  Future<void> createTabGroup(String name, int colorValue) async {
    final group = TabGroupModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Group' : name.trim(),
      colorValue: colorValue,
    );
    _tabGroups.add(group);
    await _saveGroups();
    notifyListeners();
  }

  Future<void> deleteTabGroup(String groupId) async {
    _tabGroups.removeWhere((g) => g.id == groupId);
    for (final tab in _normalTabs) {
      if (tab.groupId == groupId) {
        tab.groupId = null;
      }
    }
    await HiveDatabase.instance.tabGroupsBox.delete(groupId);
    await _saveNormalTabs();
    notifyListeners();
  }

  Future<void> assignTabToGroup(String tabId, String? groupId) async {
    final index = _normalTabs.indexWhere((t) => t.id == tabId);
    if (index != -1) {
      _normalTabs[index].groupId = groupId;
      await HiveDatabase.instance.tabsBox.put(tabId, _normalTabs[index].toMap());
      notifyListeners();
    }
  }
}
