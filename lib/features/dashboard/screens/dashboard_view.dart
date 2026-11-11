import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../tabs/providers/tab_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/shortcut_dialog.dart';

class DashboardView extends StatelessWidget {
  final Function(String url) onOpenUrl;

  const DashboardView({super.key, required this.onOpenUrl});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabProvider = context.watch<TabProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    final isIncognito = tabProvider.isIncognitoMode;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Incognito Warning Card (if private tab)
          if (isIncognito) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1B3D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFB388FF), size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private Browsing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your searches, visits, and cookies will not be saved locally.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // App Logo and Greeting
          isIncognito
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.12),
                  ),
                  child: Icon(
                    Icons.vpn_lock_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.explore_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Text(
            _getGreeting(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 24),

          // Central Quick Search Bar
          GestureDetector(
            onTap: () => _showSearchModal(context, onOpenUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF23232C) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search with ${AppConstants.searchEngineNames[settingsProvider.settings.searchEngine] ?? 'Google'} or type URL',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Speed Dial Shortcuts
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Access',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ShortcutDialog(
                        onSave: (title, url) => dashboardProvider.addShortcut(title, url),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dashboardProvider.shortcuts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final shortcut = dashboardProvider.shortcuts[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpenUrl(shortcut.url),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ShortcutDialog(
                      shortcut: shortcut,
                      onSave: (t, u) => dashboardProvider.editShortcut(shortcut.id, t, u),
                      onDelete: () => dashboardProvider.removeShortcut(shortcut.id),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262630) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Center(
                        child: shortcut.favicon != null && shortcut.favicon!.isNotEmpty
                            ? Image.network(
                                shortcut.favicon!,
                                width: 26,
                                height: 26,
                                errorBuilder: (_, __, ___) => Text(
                                  shortcut.title.isNotEmpty ? shortcut.title[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Text(
                                shortcut.title.isNotEmpty ? shortcut.title[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recently Closed Tabs (if any)
          if (!isIncognito && tabProvider.recentlyClosed.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recently Closed Tabs',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabProvider.recentlyClosed.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = tabProvider.recentlyClosed[index];
                  return ActionChip(
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => tabProvider.restoreRecentlyClosed(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Quick Bookmarks row (if non-empty)
          if (bookmarkProvider.bookmarks.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bookmarks',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookmarkProvider.bookmarks.length.clamp(0, 3),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = bookmarkProvider.bookmarks[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: b.favicon != null && b.favicon!.isNotEmpty
                        ? Image.network(
                            b.favicon!,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.bookmark, size: 16),
                          )
                        : const Icon(Icons.bookmark, size: 16),
                  ),
                  title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(b.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  onTap: () => onOpenUrl(b.url),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Recent History row (if not incognito and non-empty)
          if (!isIncognito && historyProvider.history.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Visits',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyProvider.history.length.clamp(0, 4),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final h = historyProvider.history[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    child: const Icon(Icons.public, size: 16),
                  ),
                  title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(h.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    DateFormat('h:mm a').format(h.visitedAt),
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                  ),
                  onTap: () => onOpenUrl(h.url),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showSearchModal(BuildContext context, Function(String) onOpenUrl) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  hintText: 'Enter URL or search keyword...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.clear(),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
                onSubmitted: (value) {
                  Navigator.pop(ctx);
                  if (value.trim().isNotEmpty) {
                    final settings = context.read<SettingsProvider>().settings;
                    final target = AppConstants.normalizeUrl(value, searchEngine: settings.searchEngine);
                    onOpenUrl(target);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
