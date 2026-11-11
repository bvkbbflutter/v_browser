import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tabs/providers/tab_provider.dart';

class CompactBottomNav extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onBookmarks;
  final VoidCallback onSearch;
  final VoidCallback onTabsOverview;
  final VoidCallback onOptions;

  const CompactBottomNav({
    super.key,
    required this.onHome,
    required this.onBookmarks,
    required this.onSearch,
    required this.onTabsOverview,
    required this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabProvider = context.watch<TabProvider>();
    final isIncognito = tabProvider.isIncognitoMode;
    final tabCount = isIncognito ? tabProvider.incognitoTabs.length : tabProvider.normalTabs.length;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isIncognito
            ? const Color(0xFF1E1730)
            : (isDark ? const Color(0xFF1E1E24) : Colors.white),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined, size: 22),
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            visualDensity: VisualDensity.compact,
            onPressed: onHome,
          ),

          // 2. Bookmarks
          IconButton(
            tooltip: 'Bookmarks',
            icon: const Icon(Icons.bookmarks_outlined, size: 21),
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            visualDensity: VisualDensity.compact,
            onPressed: onBookmarks,
          ),

          // 3. Search
          IconButton(
            tooltip: 'Search or Type URL',
            icon: const Icon(Icons.search_rounded, size: 22),
            color: isIncognito ? Colors.purpleAccent : theme.colorScheme.primary,
            visualDensity: VisualDensity.compact,
            onPressed: onSearch,
          ),

          // 4. Tabs Overview (with count badge)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTabsOverview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Container(
                width: 23,
                height: 23,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isIncognito
                        ? Colors.purpleAccent
                        : theme.colorScheme.onSurface.withOpacity(0.8),
                    width: 1.8,
                  ),
                ),
                child: Text(
                  '$tabCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isIncognito
                        ? Colors.purpleAccent
                        : theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ),
          ),

          // 5. Options
          IconButton(
            tooltip: 'Options',
            icon: const Icon(Icons.more_horiz_rounded, size: 24),
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            visualDensity: VisualDensity.compact,
            onPressed: onOptions,
          ),
        ],
      ),
    );
  }
}
