import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/hive_database.dart';
import '../../../core/models/download_model.dart';
import '../../../core/services/media_detector.dart';
import '../../../services/local_notification_service.dart';
import '../services/download_service.dart';
import '../services/download_storage_service.dart';

class DownloadProvider extends ChangeNotifier {
  List<DownloadModel> _downloads = [];
  final DownloadService _service = DownloadService();

  List<DownloadModel> get downloads => _downloads;

  DownloadProvider() {
    _loadDownloads();
    _initNotificationActions();
  }

  void _initNotificationActions() {
    LocalNotificationServiceV.addActionListener((actionId) {
      if (actionId.startsWith('action_dl_pause_')) {
        final id = actionId.replaceFirst('action_dl_pause_', '');
        pauseDownload(id);
      } else if (actionId.startsWith('action_dl_resume_')) {
        final id = actionId.replaceFirst('action_dl_resume_', '');
        resumeDownload(id);
      } else if (actionId.startsWith('action_dl_cancel_')) {
        final id = actionId.replaceFirst('action_dl_cancel_', '');
        cancelDownload(id);
      } else if (actionId.startsWith('action_dl_retry_')) {
        final id = actionId.replaceFirst('action_dl_retry_', '');
        retryDownload(id);
      }
    });
  }

  void _loadDownloads() {
    final box = HiveDatabase.instance.downloadsBox;
    _downloads = box.values
        .map((item) => DownloadModel.fromMap(Map<dynamic, dynamic>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Reset any hanging 'downloading' status to 'paused' on launch
    for (final d in _downloads) {
      if (d.status == DownloadStatus.downloading) {
        d.status = DownloadStatus.paused;
        box.put(d.id, d.toMap());
      }
    }
  }

  double getProgress(String urlOrPath) {
    final item = _downloads.firstWhere(
      (d) => d.url == urlOrPath || d.filePath == urlOrPath,
      orElse: () => DownloadModel(
        id: '',
        fileName: '',
        url: '',
        filePath: '',
        progress: 1.0,
      ),
    );
    return item.progress;
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // 1. Explicitly request Notification Permission (Android 13+)
      await LocalNotificationServiceV().requestPermission();

      // 2. Storage and Media permissions
      try {
        await Permission.storage.request();
      } catch (_) {}
      try {
        await Permission.photos.request();
        await Permission.videos.request();
      } catch (_) {}
      return true;
    }
    return true;
  }

  Future<void> startDownload(
    BuildContext context,
    String url, {
    String? customFileName,
    String? mimeType,
    String? cookie,
    String? referer,
    String? userAgent,
  }) async {
    await _requestPermissions();

    try {
      final directory = await DownloadStorageService.getAppDownloadsDirectory();

      String fileName = customFileName ?? MediaDetector.getFileName(url);
      if (!fileName.contains('.')) {
        final ext = MediaDetector.getExtension(url);
        fileName = ext.isNotEmpty ? '$fileName.$ext' : '$fileName.bin';
      }

      final filePath = DownloadStorageService.resolveSafeFilePath(directory, fileName);

      final downloadItem = DownloadModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: filePath.split(Platform.pathSeparator).last,
        url: url,
        filePath: filePath,
        mimeType: mimeType,
        status: DownloadStatus.pending,
        cookie: cookie,
        referer: referer,
        userAgent: userAgent,
      );

      _downloads.insert(0, downloadItem);
      await HiveDatabase.instance.downloadsBox.put(downloadItem.id, downloadItem.toMap());
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download: ${downloadItem.fileName}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {},
            ),
          ),
        );
      }

      _runTask(downloadItem);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Download Failed to start: $e')),
        );
      }
    }
  }

  void _runTask(DownloadModel item) {
    _service.runDownload(
      model: item,
      onProgress: (updated) {
        HiveDatabase.instance.downloadsBox.put(updated.id, updated.toMap());
        notifyListeners();
      },
      onComplete: (completed) {
        HiveDatabase.instance.downloadsBox.put(completed.id, completed.toMap());
        notifyListeners();
      },
      onError: (failed, error) {
        HiveDatabase.instance.downloadsBox.put(failed.id, failed.toMap());
        notifyListeners();
      },
    );
  }

  void pauseDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _service.pauseDownload(id);
      _downloads[index].status = DownloadStatus.paused;
      _downloads[index].speed = '0 KB/s';
      HiveDatabase.instance.downloadsBox.put(id, _downloads[index].toMap());
      LocalNotificationServiceV().showDownloadPausedNotification(
        notificationId: id.hashCode,
        id: id,
        fileName: _downloads[index].fileName,
        progress: _downloads[index].progress,
        downloadedFormatted: DownloadService.formatBytes(_downloads[index].downloadedBytes),
        totalFormatted: _downloads[index].fileSize > 0
            ? DownloadService.formatBytes(_downloads[index].fileSize)
            : 'Unknown size',
      );
      notifyListeners();
    }
  }

  void resumeDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _runTask(_downloads[index]);
    }
  }

  void cancelDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _service.cancelDownload(id);
      _downloads[index].status = DownloadStatus.cancelled;
      _downloads[index].speed = '0 KB/s';
      HiveDatabase.instance.downloadsBox.put(id, _downloads[index].toMap());
      LocalNotificationServiceV().cancelNotification(id.hashCode);
      notifyListeners();
    }
  }

  void retryDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _runTask(_downloads[index]);
    }
  }

  Future<void> openDownload(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await OpenFile.open(filePath);
    }
  }

  Future<void> shareDownload(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  Future<void> deleteDownload(String id) async {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = _downloads[index];
      _service.cancelDownload(id);
      try {
        final f = File(item.filePath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
      _downloads.removeAt(index);
      await HiveDatabase.instance.downloadsBox.delete(id);
      notifyListeners();
    }
  }
}
