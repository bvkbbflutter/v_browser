import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../bookmarks/providers/bookmark_provider.dart';
import '../../bookmarks/screens/bookmarks_screen.dart';
import '../../downloads/screens/downloads_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../tabs/providers/tab_provider.dart';
import '../providers/browser_provider.dart';

class OptionsBottomSheet extends StatelessWidget {
  const OptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabProvider = context.watch<TabProvider>();
    final browser = context.watch<BrowserProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final tab = tabProvider.activeTab;

    final isHome = tab.url == 'home' || tab.url == 'about:blank';
    final isBookmarked = bookmarkProvider.isBookmarked(tab.url);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Quick action toolbar (Share, Bookmark, Reload, Desktop Mode)
              if (!isHome) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Reload',
                        onTap: () {
                          Navigator.pop(context);
                          browser.reload();
                        },
                      ),
                      _QuickActionButton(
                        icon: isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                        label: 'Bookmark',
                        isActive: isBookmarked,
                        onTap: () {
                          bookmarkProvider.toggleBookmark(tab.url, tab.title, favicon: tab.favicon);
                          Navigator.pop(context);
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onTap: () {
                          Navigator.pop(context);
                          Share.share(tab.url, subject: tab.title);
                        },
                      ),
                      _QuickActionButton(
                        icon: Icons.desktop_windows_rounded,
                        label: 'Desktop',
                        isActive: browser.isDesktopSite,
                        onTap: () {
                          browser.toggleDesktopSite();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
              ],

              // 1. New Tab
              ListTile(
                dense: true,
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('New Tab', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  tabProvider.addNewTab(isPrivate: false);
                },
              ),

              // 2. New Private Tab
              ListTile(
                dense: true,
                leading: const Icon(Icons.shield_outlined, color: Colors.purpleAccent),
                title: const Text('New Private Tab', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  tabProvider.addNewTab(isPrivate: true);
                },
              ),

              // 3. Add Tab to New Group
              ListTile(
                dense: true,
                leading: const Icon(Icons.folder_open_rounded),
                title: const Text('Add Tab to New Group', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog(context, tabProvider, tab.id);
                },
              ),

              const Divider(height: 12),

              // Find In Page (if on a website)
              if (!isHome) ...[
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.find_in_page_outlined),
                  title: const Text('Find in Page', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    browser.openFindInPage();
                  },
                ),
              ],

              // 4. History
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_rounded),
                title: const Text('History', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),

              // 5. Downloads
              ListTile(
                dense: true,
                leading: const Icon(Icons.download_rounded),
                title: const Text('Downloads', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                  );
                },
              ),

              // Bookmarks Screen
              ListTile(
                dense: true,
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: const Text('Bookmarks', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                  );
                },
              ),

              // 6. Settings
              ListTile(
                dense: true,
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              const Divider(height: 12),

              // Recently closed tabs quick access
              if (tabProvider.recentlyClosed.isNotEmpty) ...[
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.restore_page_outlined),
                  title: Text('Recently Closed Tabs (${tabProvider.recentlyClosed.length})'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRecentlyClosedModal(context, tabProvider);
                  },
                ),
              ],

              // Close Current Tab
              ListTile(
                dense: true,
                leading: const Icon(Icons.close_rounded, color: Colors.redAccent),
                title: const Text('Close Current Tab', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  tabProvider.closeTab(tab.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, TabProvider tabProvider, String tabId) {
    final controller = TextEditingController(text: 'Group 1');
    int selectedColor = 0xFF2196F3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final colors = [
            0xFF2196F3, // Blue
            0xFF4CAF50, // Green
            0xFFFF9800, // Orange
            0xFFE91E63, // Pink
            0xFF9C27B0, // Purple
            0xFF009688, // Teal
          ];

          return AlertDialog(
            title: const Text('Create Tab Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colors.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSel
                              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    await tabProvider.createTabGroup(controller.text, selectedColor);
                    final group = tabProvider.tabGroups.last;
                    await tabProvider.assignTabToGroup(tabId, group.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Create & Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecentlyClosedModal(BuildContext context, TabProvider tabProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recently Closed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: tabProvider.recentlyClosed.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = tabProvider.recentlyClosed[index];
                    return ListTile(
                      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.restore, size: 20),
                      onTap: () {
                        Navigator.pop(ctx);
                        tabProvider.restoreRecentlyClosed(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
