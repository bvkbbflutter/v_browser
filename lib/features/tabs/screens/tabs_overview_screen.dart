import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/browser_tab_model.dart';
import '../providers/tab_provider.dart';

class TabsOverviewScreen extends StatefulWidget {
  const TabsOverviewScreen({super.key});

  @override
  State<TabsOverviewScreen> createState() => _TabsOverviewScreenState();
}

class _TabsOverviewScreenState extends State<TabsOverviewScreen> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabProvider = context.watch<TabProvider>();

    final isShowingPrivate = tabProvider.showingIncognitoInOverview;
    final displayedTabs = isShowingPrivate
        ? tabProvider.incognitoTabs
        : (_selectedGroupId == null
            ? tabProvider.normalTabs
            : tabProvider.normalTabs.where((t) => t.groupId == _selectedGroupId).toList());

    return Scaffold(
      backgroundColor: isShowingPrivate ? const Color(0xFF100C1A) : null,
      appBar: AppBar(
        backgroundColor: isShowingPrivate ? const Color(0xFF181524) : null,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentButton(
                  icon: Icons.tab_rounded,
                  label: '${tabProvider.normalTabs.length}',
                  isSelected: !isShowingPrivate,
                  onTap: () => tabProvider.setShowingIncognitoInOverview(false),
                ),
                _SegmentButton(
                  icon: Icons.shield_outlined,
                  label: '${tabProvider.incognitoTabs.length}',
                  isSelected: isShowingPrivate,
                  selectedColor: Colors.purpleAccent,
                  onTap: () => tabProvider.setShowingIncognitoInOverview(true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Close All Tabs',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: displayedTabs.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Close all tabs?'),
                        content: Text(
                          isShowingPrivate
                              ? 'This will close all private tabs and erase private session data.'
                              : 'This will close all open tabs.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              Navigator.pop(ctx);
                              tabProvider.closeAllTabs(incognitoOnly: isShowingPrivate);
                            },
                            child: const Text('Close All'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab Group Filters (only in normal mode)
          if (!isShowingPrivate && tabProvider.tabGroups.isNotEmpty) ...[
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All Tabs'),
                    selected: _selectedGroupId == null,
                    onSelected: (val) => setState(() => _selectedGroupId = null),
                  ),
                  const SizedBox(width: 8),
                  ...tabProvider.tabGroups.map((g) {
                    final isSel = _selectedGroupId == g.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: Color(g.colorValue),
                          radius: 5,
                        ),
                        label: Text(g.name),
                        selected: isSel,
                        onSelected: (val) => setState(() => _selectedGroupId = isSel ? null : g.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Grid of Tab Cards
          Expanded(
            child: displayedTabs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isShowingPrivate ? Icons.shield_outlined : Icons.tab_unselected_rounded,
                          size: 54,
                          color: isShowingPrivate ? Colors.purpleAccent : theme.disabledColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isShowingPrivate ? 'No Private Tabs' : 'No Tabs Open',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            tabProvider.addNewTab(isPrivate: isShowingPrivate);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(isShowingPrivate ? 'New Private Tab' : 'New Tab'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedTabs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final tab = displayedTabs[index];
                      final isActive = tab.id == tabProvider.activeTabId;

                      return _TabCard(
                        tab: tab,
                        isActive: isActive,
                        onTap: () {
                          tabProvider.switchToTab(tab.id);
                          Navigator.pop(context);
                        },
                        onClose: () => tabProvider.closeTab(tab.id),
                        onDuplicate: () => tabProvider.duplicateTab(tab.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isShowingPrivate ? const Color(0xFF181524) : null,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${displayedTabs.length} ${displayedTabs.length == 1 ? 'tab' : 'tabs'}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  tabProvider.addNewTab(isPrivate: isShowingPrivate);
                  Navigator.pop(context);
                },
                style: isShowingPrivate
                    ? FilledButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF))
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Tab'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selectedColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 1.2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  final BrowserTabModel tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onDuplicate;

  const _TabCard({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHome = tab.url == 'home' || tab.url == 'about:blank';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23232C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? (tab.isPrivate ? Colors.purpleAccent : theme.colorScheme.primary)
                : (isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
            width: isActive ? 2.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C36) : const Color(0xFFF1F3F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  tab.favicon != null && tab.favicon!.isNotEmpty
                      ? Image.network(
                          tab.favicon!,
                          width: 14,
                          height: 14,
                          errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 14),
                        )
                      : Icon(
                          tab.isPrivate ? Icons.shield_outlined : Icons.public,
                          size: 14,
                          color: tab.isPrivate ? Colors.purpleAccent : null,
                        ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tab.title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Card Body (Preview)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isHome
                            ? (tab.isPrivate ? Icons.vpn_lock_rounded : Icons.explore_rounded)
                            : Icons.language_rounded,
                        size: 32,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHome ? 'Start Page' : AppConstants.getDisplayHost(tab.url),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
