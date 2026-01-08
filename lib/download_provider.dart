import 'package:flutter/material.dart';

class DownloadProvider extends ChangeNotifier {
  Map<String, double> _downloadProgress = {};

  void updateProgress(String url, double progress) {
    _downloadProgress[url] = progress;
    notifyListeners();
  }

  double getProgress(String url) {
    return _downloadProgress[url] ?? 0.0;
  }
}

