import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/media_detector.dart';
import '../../audio/models/audio_track_model.dart';
import '../../audio/providers/audio_provider.dart';
import '../../audio/widgets/floating_audio_player.dart';
import '../../bookmarks/screens/bookmarks_screen.dart';
import '../../dashboard/screens/dashboard_view.dart';
import '../../downloads/providers/download_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../tabs/providers/tab_provider.dart';
import '../../tabs/screens/tabs_overview_screen.dart';
import '../../video/screens/video_player_screen.dart';
import '../providers/browser_provider.dart';
import '../widgets/compact_bottom_nav.dart';
import '../widgets/compact_url_bar.dart';
import '../widgets/find_in_page_bar.dart';
import '../widgets/options_bottom_sheet.dart';

class MainBrowserScreen extends StatefulWidget {
  const MainBrowserScreen({super.key});

  @override
  State<MainBrowserScreen> createState() => _MainBrowserScreenState();
}

class _MainBrowserScreenState extends State<MainBrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};
  late final FindInteractionController _findInteractionController = FindInteractionController(
    onFindResultReceived: (controller, activeMatchOrdinal, numberOfMatches, isDoneCounting) {
      if (mounted) {
        context.read<BrowserProvider>().onFindResultReceived(activeMatchOrdinal, numberOfMatches, isDoneCounting);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabProvider = context.watch<TabProvider>();
    final browser = context.watch<BrowserProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final activeTab = tabProvider.activeTab;

    final isHome = activeTab.url == 'home' || activeTab.url == 'about:blank';
    final isIncognito = activeTab.isPrivate;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (browser.isFindInPageActive) {
          browser.closeFindInPage();
          return;
        }

        if (browser.canGoBack) {
          await browser.goBack();
          return;
        }

        if (!isHome) {
          browser.setActiveController(null);
          tabProvider.updateTabUrl(activeTab.id, 'home', title: 'Home');
          return;
        }

        // Close app or minimize
        final shouldClose = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit V-Browser?'),
            content: const Text('Do you want to close the browser?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit')),
            ],
          ),
        );
        if (shouldClose == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isIncognito
            ? const Color(0xFF0F0D17)
            : theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. Minimized URL Bar
                  CompactUrlBar(
                    onSearchTapped: () => _showSearchDialog(context),
                  ),

                  // 2. Find in Page Bar (if active)
                  if (browser.isFindInPageActive) const FindInPageBar(),

                  // 3. Web Content Area (Maximized screen space)
                  Expanded(
                    child: isHome
                        ? DashboardView(
                            onOpenUrl: (url) => _navigateToUrl(context, url),
                          )
                        : InAppWebView(
                            key: ValueKey('${activeTab.id}_$isIncognito'),
                            initialUrlRequest: URLRequest(url: WebUri(activeTab.url)),
                            initialSettings: InAppWebViewSettings(
                              useShouldOverrideUrlLoading: true,
                              mediaPlaybackRequiresUserGesture: false,
                              javaScriptEnabled: settingsProvider.settings.javascriptEnabled,
                              supportZoom: true,
                              builtInZoomControls: true,
                              displayZoomControls: false,
                              transparentBackground: false,
                              preferredContentMode: (settingsProvider.settings.defaultDesktopMode || browser.isDesktopSite)
                                  ? UserPreferredContentMode.DESKTOP
                                  : UserPreferredContentMode.MOBILE,
                              clearCache: isIncognito,
                              incognito: isIncognito,
                              cacheEnabled: !isIncognito,
                              allowsInlineMediaPlayback: true,
                            ),
                            findInteractionController: _findInteractionController,
                            onWebViewCreated: (controller) {
                              _controllers[activeTab.id] = controller;
                              browser.setActiveController(controller);
                              browser.setFindInteractionController(_findInteractionController);
                            },
                            shouldOverrideUrlLoading: (controller, navigationAction) async {
                              final uri = navigationAction.request.url;
                              if (uri != null) {
                                final urlStr = uri.toString();
                                final mediaType = MediaDetector.detect(urlStr);

                                // Downloadable auto-detection (pdf, zip, apk, etc.)
                                if (mediaType == DetectedMediaType.downloadable) {
                                  await context.read<DownloadProvider>().startDownload(context, urlStr);
                                  return NavigationActionPolicy.CANCEL;
                                }

                                // Audio or Video media link: ask user to Download or Play (never auto-play or auto-download)
                                if (mediaType == DetectedMediaType.audio || mediaType == DetectedMediaType.video) {
                                  _showMediaPrompt(context, urlStr, mediaType);
                                  return NavigationActionPolicy.CANCEL;
                                }

                                final scheme = uri.scheme.toLowerCase();
                                if (scheme == 'http' || scheme == 'https' || scheme == 'about' || scheme == 'data') {
                                  return NavigationActionPolicy.ALLOW;
                                }
                              }
                              return NavigationActionPolicy.ALLOW;
                            },
                            onLoadStart: (controller, url) {
                              browser.setProgress(0.1);
                              browser.updateNavigationState();
                            },
                            onProgressChanged: (controller, progress) {
                              browser.setProgress(progress / 100.0);
                            },
                            onLoadStop: (controller, url) async {
                              browser.setProgress(1.0);
                              await browser.updateNavigationState();

                              if (url != null) {
                                final title = await controller.getTitle();
                                final favicons = await controller.getFavicons();
                                final fav = favicons.isNotEmpty ? favicons.first.url.toString() : null;

                                tabProvider.updateTabUrl(
                                  activeTab.id,
                                  url.toString(),
                                  title: title,
                                  favicon: fav,
                                );

                                // Record history if NOT incognito
                                if (context.mounted) {
                                  context.read<HistoryProvider>().addVisit(
                                    title: title ?? '',
                                    url: url.toString(),
                                    favicon: fav,
                                    isPrivate: activeTab.isPrivate,
                                  );
                                }
                              }
                            },
                            onTitleChanged: (controller, title) {
                              if (title != null && title.isNotEmpty) {
                                tabProvider.updateTabTitle(activeTab.id, title);
                              }
                            },
                            onUpdateVisitedHistory: (controller, url, isReload) async {
                              if (url != null) {
                                tabProvider.updateTabUrl(activeTab.id, url.toString());
                                await browser.updateNavigationState();
                              }
                            },
                            onDownloadStartRequest: (controller, downloadStartRequest) async {
                              // Always trigger download directly and reliably without hijacking to playback
                              final downloadUrl = downloadStartRequest.url.toString();

                              // Forward cookies and referer from the active web session to support protected/anti-hotlink downloads
                              String? cookieHeader;
                              try {
                                final cookies = await CookieManager.instance().getCookies(url: downloadStartRequest.url);
                                if (cookies.isNotEmpty) {
                                  cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
                                }
                              } catch (_) {}

                              final currentUrl = (await controller.getUrl())?.toString();
                              if (!context.mounted) return;

                              await context.read<DownloadProvider>().startDownload(
                                context,
                                downloadUrl,
                                customFileName: downloadStartRequest.suggestedFilename,
                                mimeType: downloadStartRequest.mimeType,
                                cookie: cookieHeader,
                                referer: currentUrl,
                                userAgent: downloadStartRequest.userAgent,
                              );
                            },
                          ),
                  ),

                  // 4. Minimized Bottom Navigation Bar
                  CompactBottomNav(
                    onHome: () {
                      browser.setActiveController(null);
                      tabProvider.updateTabUrl(activeTab.id, 'home', title: 'Home');
                    },
                    onBookmarks: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                      );
                    },
                    onSearch: () {
                      _showSearchDialog(context);
                    },
                    onTabsOverview: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TabsOverviewScreen()),
                      );
                    },
                    onOptions: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const OptionsBottomSheet(),
                      );
                    },
                  ),
                ],
              ),

              // 5. Draggable Floating Audio Player Overlay
              const FloatingAudioPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUrl(BuildContext context, String url) {
    final mediaType = MediaDetector.detect(url);
    if (mediaType == DetectedMediaType.downloadable) {
      context.read<DownloadProvider>().startDownload(context, url);
      return;
    }
    if (mediaType == DetectedMediaType.audio || mediaType == DetectedMediaType.video) {
      _showMediaPrompt(context, url, mediaType);
      return;
    }

    final tabProvider = context.read<TabProvider>();
    final browser = context.read<BrowserProvider>();
    final activeTab = tabProvider.activeTab;
    final wasHome = activeTab.url == 'home' || activeTab.url == 'about:blank';

    tabProvider.updateTabUrl(activeTab.id, url);

    // If webview is already mounted on a site, ask controller to load the new URL
    if (!wasHome && browser.activeController != null) {
      browser.loadUrl(url);
    }
  }

  void _showMediaPrompt(BuildContext context, String url, DetectedMediaType mediaType) {
    final fileName = MediaDetector.getFileName(url);
    final isAudio = mediaType == DetectedMediaType.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                    child: Icon(
                      isAudio ? Icons.audiotrack_rounded : Icons.videocam_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isAudio ? 'Audio file detected' : 'Video file detected',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<DownloadProvider>().startDownload(context, url);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (isAudio) {
                          context.read<AudioProvider>().playTrack(
                            AudioTrackModel(id: url, title: fileName, url: url),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(url: url, title: fileName),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    final tabProvider = context.read<TabProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final activeTab = tabProvider.activeTab;

    final initialText = (activeTab.url == 'home' || activeTab.url == 'about:blank') ? '' : activeTab.url;
    final controller = TextEditingController(text: initialText);
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                  hintText: 'Search or type URL...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => controller.clear(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  isDense: true,
                ),
                onSubmitted: (value) {
                  Navigator.pop(ctx);
                  if (value.trim().isNotEmpty) {
                    final normalized = AppConstants.normalizeUrl(
                      value,
                      searchEngine: settingsProvider.settings.searchEngine,
                    );
                    _navigateToUrl(context, normalized);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (controller.text.trim().isNotEmpty) {
                        final normalized = AppConstants.normalizeUrl(
                          controller.text,
                          searchEngine: settingsProvider.settings.searchEngine,
                        );
                        _navigateToUrl(context, normalized);
                      }
                    },
                    child: const Text('Go'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
