import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../browser/providers/browser_provider.dart';
import '../../tabs/providers/tab_provider.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyProvider = context.watch<HistoryProvider>();
    final tabProvider = context.read<TabProvider>();
    final browser = context.read<BrowserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browsing History'),
        elevation: 0,
        actions: [
          if (historyProvider.history.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'clear_today') {
                  historyProvider.clearToday();
                } else if (action == 'clear_all') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Browsing History?'),
                      content: const Text('This will delete all history records from this device.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(ctx);
                            historyProvider.clearAll();
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'clear_today',
                  child: Text('Clear Today'),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Clear All History', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => historyProvider.setSearchQuery(val),
            ),
          ),
          Expanded(
            child: historyProvider.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 54, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        Text(
                          'No Browsing History',
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
                    itemCount: historyProvider.history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = historyProvider.history[index];
                      final timeStr = DateFormat('MMM d, h:mm a').format(item.visitedAt);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? const Color(0xFF282834) : const Color(0xFFE9ECEF),
                          child: item.favicon != null && item.favicon!.isNotEmpty
                              ? Image.network(
                                  item.favicon!,
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 18),
                                )
                              : const Icon(Icons.public, size: 18),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => historyProvider.deleteEntry(item.id),
                        ),
                        onTap: () {
                          final wasHome = tabProvider.activeTab.url == 'home' || tabProvider.activeTab.url == 'about:blank';
                          tabProvider.updateTabUrl(tabProvider.activeTabId, item.url, title: item.title);
                          if (!wasHome) {
                            browser.loadUrl(item.url);
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
}
