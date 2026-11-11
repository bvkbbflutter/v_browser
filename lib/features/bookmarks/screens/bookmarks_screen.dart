import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/bookmark_model.dart';
import '../../browser/providers/browser_provider.dart';
import '../../tabs/providers/tab_provider.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final tabProvider = context.read<TabProvider>();
    final browser = context.read<BrowserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Bookmark',
            onPressed: () => _showAddEditDialog(context, bookmarkProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => bookmarkProvider.setSearchQuery(val),
            ),
          ),

          // Folders horizontal list
          if (bookmarkProvider.folders.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: bookmarkProvider.folders.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final folder = bookmarkProvider.folders[index];
                  final isSel = bookmarkProvider.selectedFolder == folder;
                  return ChoiceChip(
                    label: Text(folder),
                    selected: isSel,
                    onSelected: (val) => bookmarkProvider.selectFolder(folder),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bookmarks List
          Expanded(
            child: bookmarkProvider.bookmarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 54, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          'No Bookmarks Found',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: bookmarkProvider.bookmarks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bookmark = bookmarkProvider.bookmarks[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? const Color(0xFF282834) : const Color(0xFFE9ECEF),
                          child: bookmark.favicon != null && bookmark.favicon!.isNotEmpty
                              ? Image.network(
                                  bookmark.favicon!,
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 18),
                                )
                              : const Icon(Icons.bookmark, size: 18),
                        ),
                        title: Text(
                          bookmark.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          bookmark.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'open_new') {
                              tabProvider.addNewTab(url: bookmark.url, title: bookmark.title);
                              Navigator.pop(context);
                            } else if (action == 'edit') {
                              _showAddEditDialog(context, bookmarkProvider, bookmark: bookmark);
                            } else if (action == 'delete') {
                              bookmarkProvider.removeBookmark(bookmark.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'open_new',
                              child: Text('Open in New Tab'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () {
                          final wasHome = tabProvider.activeTab.url == 'home' || tabProvider.activeTab.url == 'about:blank';
                          tabProvider.updateTabUrl(tabProvider.activeTabId, bookmark.url, title: bookmark.title);
                          if (!wasHome) {
                            browser.loadUrl(bookmark.url);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    BookmarkProvider provider, {
    BookmarkModel? bookmark,
  }) {
    final titleCtrl = TextEditingController(text: bookmark?.title ?? '');
    final urlCtrl = TextEditingController(text: bookmark?.url ?? '');
    String folder = bookmark?.folder ?? 'Default';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bookmark == null ? 'Add Bookmark' : 'Edit Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                if (bookmark == null) {
                  provider.addBookmark(titleCtrl.text, urlCtrl.text, folder: folder);
                } else {
                  provider.updateBookmark(bookmark.id, titleCtrl.text, urlCtrl.text, folder);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
