import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserProvider extends ChangeNotifier {
  InAppWebViewController? _activeController;
  FindInteractionController? _findInteractionController;
  double _progress = 0.0;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isSecure = false;
  bool _isDesktopSite = false;

  // Find in page state
  bool _isFindInPageActive = false;
  String _findQuery = '';
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  // Hide/Show controls on scroll
  bool _isControlsVisible = true;

  InAppWebViewController? get activeController => _activeController;
  FindInteractionController? get findInteractionController => _findInteractionController;
  double get progress => _progress;
  bool get isLoading => _isLoading;
  bool get canGoBack => _canGoBack;
  bool get canGoForward => _canGoForward;
  bool get isSecure => _isSecure;
  bool get isDesktopSite => _isDesktopSite;

  bool get isFindInPageActive => _isFindInPageActive;
  String get findQuery => _findQuery;
  int get currentMatchIndex => _currentMatchIndex;
  int get totalMatches => _totalMatches;
  bool get isControlsVisible => _isControlsVisible;

  void setActiveController(InAppWebViewController? controller) {
    _activeController = controller;
    if (controller == null) {
      _canGoBack = false;
      _canGoForward = false;
      _isSecure = false;
      _isLoading = false;
      _progress = 0.0;
      notifyListeners();
    } else {
      updateNavigationState();
    }
  }

  void setFindInteractionController(FindInteractionController? controller) {
    _findInteractionController = controller;
  }

  void setControlsVisible(bool visible) {
    if (_isControlsVisible != visible) {
      _isControlsVisible = visible;
      notifyListeners();
    }
  }

  void setProgress(double p) {
    _progress = p;
    _isLoading = p < 1.0;
    notifyListeners();
  }

  Future<void> updateNavigationState() async {
    if (_activeController != null) {
      try {
        _canGoBack = await _activeController!.canGoBack();
        _canGoForward = await _activeController!.canGoForward();
        final url = await _activeController!.getUrl();
        _isSecure = url?.scheme == 'https';
        notifyListeners();
      } catch (e) {
        debugPrint('Safe caught updateNavigationState error: $e');
      }
    }
  }

  void toggleDesktopSite() {
    _isDesktopSite = !_isDesktopSite;
    if (_activeController != null) {
      try {
        _activeController!.setSettings(
          settings: InAppWebViewSettings(
            preferredContentMode: _isDesktopSite
                ? UserPreferredContentMode.DESKTOP
                : UserPreferredContentMode.MOBILE,
          ),
        );
        _activeController!.reload();
      } catch (e) {
        debugPrint('Safe caught toggleDesktopSite error: $e');
      }
    }
    notifyListeners();
  }

  // Find in page
  void openFindInPage() {
    _isFindInPageActive = true;
    _findQuery = '';
    _currentMatchIndex = 0;
    _totalMatches = 0;
    notifyListeners();
  }

  void closeFindInPage() {
    _isFindInPageActive = false;
    _findQuery = '';
    _currentMatchIndex = 0;
    _totalMatches = 0;
    try {
      _findInteractionController?.clearMatches();
    } catch (_) {}
    notifyListeners();
  }

  void setFindQuery(String query) {
    _findQuery = query;
    if (query.trim().isEmpty) {
      _totalMatches = 0;
      _currentMatchIndex = 0;
      try {
        _findInteractionController?.clearMatches();
      } catch (_) {}
      notifyListeners();
      return;
    }
    try {
      _findInteractionController?.findAll(find: query);
    } catch (_) {}
  }

  void onFindResultReceived(int activeMatchOrdinal, int numberOfMatches, bool isDoneCounting) {
    _currentMatchIndex = activeMatchOrdinal + 1;
    _totalMatches = numberOfMatches;
    notifyListeners();
  }

  void findNextMatch(bool forward) {
    try {
      _findInteractionController?.findNext(forward: forward);
    } catch (_) {}
  }

  // Navigation actions
  Future<void> goBack() async {
    try {
      if (await _activeController?.canGoBack() ?? false) {
        await _activeController?.goBack();
        await updateNavigationState();
      }
    } catch (e) {
      debugPrint('Safe caught goBack error: $e');
    }
  }

  Future<void> goForward() async {
    try {
      if (await _activeController?.canGoForward() ?? false) {
        await _activeController?.goForward();
        await updateNavigationState();
      }
    } catch (e) {
      debugPrint('Safe caught goForward error: $e');
    }
  }

  Future<void> reload() async {
    try {
      await _activeController?.reload();
    } catch (e) {
      debugPrint('Safe caught reload error: $e');
    }
  }

  Future<void> stopLoading() async {
    try {
      await _activeController?.stopLoading();
    } catch (e) {
      debugPrint('Safe caught stopLoading error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUrl(String url) async {
    if (_activeController != null) {
      try {
        await _activeController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
      } catch (e) {
        debugPrint('Safe caught loadUrl error: $e');
      }
    }
  }
}
