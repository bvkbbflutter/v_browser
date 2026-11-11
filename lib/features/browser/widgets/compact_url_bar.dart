import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../../tabs/providers/tab_provider.dart';
import '../providers/browser_provider.dart';

class CompactUrlBar extends StatelessWidget {
  final VoidCallback onSearchTapped;

  const CompactUrlBar({super.key, required this.onSearchTapped});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final browser = context.watch<BrowserProvider>();
    final tabProvider = context.watch<TabProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final tab = tabProvider.activeTab;

    final isIncognito = tab.isPrivate;
    final isHome = tab.url == 'home' || tab.url == 'about:blank';
    final isBookmarked = bookmarkProvider.isBookmarked(tab.url);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isIncognito
                ? const Color(0xFF1E1730)
                : (isDark ? const Color(0xFF1E1E24) : Colors.white),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: browser.canGoBack
                    ? (isIncognito ? Colors.purpleAccent : theme.colorScheme.primary)
                    : theme.disabledColor,
                onPressed: browser.canGoBack ? () => browser.goBack() : null,
              ),

              // Forward Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: browser.canGoForward
                    ? (isIncognito ? Colors.purpleAccent : theme.colorScheme.primary)
                    : theme.disabledColor,
                onPressed: browser.canGoForward ? () => browser.goForward() : null,
              ),

              const SizedBox(width: 4),

              // Compact Domain & Search Pill
              Expanded(
                child: GestureDetector(
                  onTap: onSearchTapped,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isIncognito ? const Color(0xFF2A2040) : const Color(0xFF2B2B36))
                          : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isIncognito
                            ? Colors.purpleAccent.withOpacity(0.3)
                            : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Security Icon / Lock / Incognito icon
                        Icon(
                          isIncognito
                              ? Icons.shield_outlined
                              : (browser.isSecure
                                  ? Icons.lock_rounded
                                  : (isHome ? Icons.search : Icons.lock_open_rounded)),
                          size: 14,
                          color: isIncognito
                              ? const Color(0xFFCE93D8)
                              : (browser.isSecure
                                  ? Colors.green
                                  : theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isHome ? 'Search or type URL' : AppConstants.getDisplayHost(tab.url),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isHome ? FontWeight.normal : FontWeight.w500,
                              color: isHome
                                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isHome) ...[
                          // Bookmark Button
                          GestureDetector(
                            onTap: () {
                              bookmarkProvider.toggleBookmark(
                                tab.url,
                                tab.title,
                                favicon: tab.favicon,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 18,
                                color: isBookmarked ? Colors.amber : theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Reload or Stop Button
              IconButton(
                icon: Icon(
                  browser.isLoading ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                onPressed: () {
                  if (browser.isLoading) {
                    browser.stopLoading();
                  } else {
                    browser.reload();
                  }
                },
              ),
            ],
          ),
        ),

        // Slim Loading Progress Bar
        if (browser.isLoading)
          LinearProgressIndicator(
            value: browser.progress > 0 ? browser.progress : null,
            minHeight: 2.5,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              isIncognito ? Colors.purpleAccent : theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
