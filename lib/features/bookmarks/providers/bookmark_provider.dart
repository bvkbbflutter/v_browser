import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/hive_database.dart';
import '../../../core/models/bookmark_model.dart';

class BookmarkProvider extends ChangeNotifier {
  List<BookmarkModel> _bookmarks = [];
  String _searchQuery = '';
  String _selectedFolder = 'All';

  List<BookmarkModel> get bookmarks {
    var filtered = _bookmarks;
    if (_selectedFolder != 'All') {
      filtered = filtered.where((b) => b.folder == _selectedFolder).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((b) => b.title.toLowerCase().contains(q) || b.url.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  List<String> get folders {
    final set = {'All', 'Default', 'Favorites', 'Reading List'};
    for (final b in _bookmarks) {
      if (b.folder.isNotEmpty) set.add(b.folder);
    }
    return set.toList();
  }

  String get selectedFolder => _selectedFolder;

  BookmarkProvider() {
    _loadBookmarks();
  }

  void _loadBookmarks() {
    final box = HiveDatabase.instance.bookmarksBox;
    _bookmarks = box.values
        .map((item) => BookmarkModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool isBookmarked(String url) {
    if (url.isEmpty || url == 'about:blank' || url == 'home') return false;
    return _bookmarks.any((b) => b.url.trim().toLowerCase() == url.trim().toLowerCase());
  }

  Future<void> toggleBookmark(String url, String title, {String? favicon}) async {
    if (url.isEmpty || url == 'about:blank' || url == 'home') return;
    final index = _bookmarks.indexWhere((b) => b.url.trim().toLowerCase() == url.trim().toLowerCase());
    if (index != -1) {
      final id = _bookmarks[index].id;
      _bookmarks.removeAt(index);
      await HiveDatabase.instance.bookmarksBox.delete(id);
    } else {
      final bookmark = BookmarkModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim().isEmpty ? AppConstants.getDisplayHost(url) : title.trim(),
        url: url,
        favicon: favicon ?? AppConstants.getFaviconUrl(url),
        folder: 'Favorites',
      );
      _bookmarks.insert(0, bookmark);
      await HiveDatabase.instance.bookmarksBox.put(bookmark.id, bookmark.toMap());
    }
    notifyListeners();
  }

  Future<void> addBookmark(String title, String url, {String folder = 'Default'}) async {
    final bookmark = BookmarkModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? AppConstants.getDisplayHost(url) : title.trim(),
      url: url,
      favicon: AppConstants.getFaviconUrl(url),
      folder: folder,
    );
    _bookmarks.insert(0, bookmark);
    await HiveDatabase.instance.bookmarksBox.put(bookmark.id, bookmark.toMap());
    notifyListeners();
  }

  Future<void> updateBookmark(String id, String title, String url, String folder) async {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookmarks[index].title = title.trim();
      _bookmarks[index].url = url.trim();
      _bookmarks[index].folder = folder;
      _bookmarks[index].favicon = AppConstants.getFaviconUrl(url);
      await HiveDatabase.instance.bookmarksBox.put(id, _bookmarks[index].toMap());
      notifyListeners();
    }
  }

  Future<void> removeBookmark(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await HiveDatabase.instance.bookmarksBox.delete(id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectFolder(String folder) {
    _selectedFolder = folder;
    notifyListeners();
  }
}
