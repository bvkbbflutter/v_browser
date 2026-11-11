import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/history_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<HistoryModel> _history = [];
  String _searchQuery = '';

  List<HistoryModel> get history {
    if (_searchQuery.trim().isEmpty) return _history;
    final q = _searchQuery.toLowerCase();
    return _history
        .where((h) => h.title.toLowerCase().contains(q) || h.url.toLowerCase().contains(q))
        .toList();
  }

  HistoryProvider() {
    _loadHistory();
  }

  void _loadHistory() {
    final box = HiveDatabase.instance.historyBox;
    _history = box.values
        .map((item) => HistoryModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
  }

  Future<void> addVisit({
    required String title,
    required String url,
    String? favicon,
    bool isPrivate = false,
  }) async {
    // Never record private / incognito browsing or empty / internal pages
    if (isPrivate || url.isEmpty || url == 'about:blank' || url == 'home' || url.startsWith('chrome://')) {
      return;
    }

    // Avoid duplicate immediate repeat within 10 seconds
    if (_history.isNotEmpty && _history.first.url == url) {
      final diff = DateTime.now().difference(_history.first.visitedAt).inSeconds;
      if (diff < 10) return;
    }

    final entry = HistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? AppConstants.getDisplayHost(url) : title.trim(),
      url: url,
      favicon: favicon ?? AppConstants.getFaviconUrl(url),
      visitedAt: DateTime.now(),
    );

    _history.insert(0, entry);
    await HiveDatabase.instance.historyBox.put(entry.id, entry.toMap());
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _history.removeWhere((h) => h.id == id);
    await HiveDatabase.instance.historyBox.delete(id);
    notifyListeners();
  }

  Future<void> clearToday() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final box = HiveDatabase.instance.historyBox;

    final toRemove = _history.where((h) => h.visitedAt.isAfter(todayStart)).toList();
    for (final h in toRemove) {
      await box.delete(h.id);
      _history.remove(h);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _history.clear();
    await HiveDatabase.instance.clearHistory();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
