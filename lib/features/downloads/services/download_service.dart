import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/download_model.dart';
import '../../../core/services/media_detector.dart';
import '../../../services/local_notification_service.dart';
import 'download_storage_service.dart';

class DownloadTask {
  final DownloadModel model;
  HttpClientRequest? request;
  IOSink? fileSink;
  bool isPaused = false;
  bool isCancelled = false;

  DownloadTask({required this.model});
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, DownloadTask> _activeTasks = {};

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(d >= 10 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  static String formatErrorMessage(dynamic error) {
    if (error is SocketException) {
      if (error.osError?.errorCode == 7 || error.message.contains('Failed host lookup')) {
        return 'Server address not found. The download domain is dead or removed by the website.';
      }
      return 'Network connection failed: ${error.message}';
    } else if (error is TimeoutException) {
      return 'Connection timed out while reaching the download server.';
    } else if (error is HttpException) {
      if (error.message.contains('404')) {
        return 'File not found on server (404). The download link has expired.';
      } else if (error.message.contains('403')) {
        return 'Access forbidden by server (403). Hotlink protection or login required.';
      }
      return error.message;
    }
    return error.toString();
  }

  Future<void> runDownload({
    required DownloadModel model,
    required void Function(DownloadModel updatedModel) onProgress,
    required void Function(DownloadModel completedModel) onComplete,
    required void Function(DownloadModel failedModel, String error) onError,
  }) async {
    final task = DownloadTask(model: model);
    _activeTasks[model.id] = task;

    model.status = DownloadStatus.downloading;
    onProgress(model);

    // Initial notification immediately upon starting
    LocalNotificationServiceV().showDownloadNotificationProgress(
      notificationId: model.id.hashCode,
      id: model.id,
      fileName: model.fileName,
      progress: model.progress,
      speed: 'Connecting...',
      downloadedFormatted: formatBytes(model.downloadedBytes),
      totalFormatted: model.fileSize > 0 ? formatBytes(model.fileSize) : '...',
    );

    final file = File(model.filePath);
    await file.parent.create(recursive: true);

    int existingBytes = 0;
    if (await file.exists()) {
      existingBytes = await file.length();
    }
    model.downloadedBytes = existingBytes;

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 25);
      client.badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse(model.url);
      final req = await client.getUrl(uri);
      task.request = req;

      req.followRedirects = true;
      req.maxRedirects = 5;
      req.headers.set(HttpHeaders.userAgentHeader, model.userAgent ?? AppConstants.desktopUserAgent);
      req.headers.set(HttpHeaders.acceptHeader, '*/*');
      if (model.referer != null && model.referer!.isNotEmpty) {
        req.headers.set(HttpHeaders.refererHeader, model.referer!);
      }
      if (model.cookie != null && model.cookie!.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, model.cookie!);
      }

      // Add Range header if resuming from existing bytes
      if (existingBytes > 0) {
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }

      final response = await req.close();

      // Check status code
      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.partialContent) {
        throw HttpException('HTTP Status ${response.statusCode}: ${response.reasonPhrase}');
      }

      // Check if server supports range request
      final isPartial = response.statusCode == HttpStatus.partialContent;
      if (!isPartial && existingBytes > 0) {
        // Server did not accept range; reset to 0
        existingBytes = 0;
        model.downloadedBytes = 0;
      }

      int totalLength = response.contentLength;
      if (totalLength > 0) {
        model.fileSize = isPartial ? (existingBytes + totalLength) : totalLength;
      }

      // Check Content-Disposition for more accurate filename if available
      final cd = response.headers.value('content-disposition');
      if (cd != null && cd.isNotEmpty) {
        final serverName = MediaDetector.getFileName(model.url, contentDisposition: cd);
        if (serverName.isNotEmpty && serverName != model.fileName) {
          final newPath = DownloadStorageService.resolveSafeFilePath(file.parent, serverName);
          model.filePath = newPath;
          model.fileName = newPath.split(Platform.pathSeparator).last;
        }
      }

      final targetFile = File(model.filePath);
      final sink = targetFile.openWrite(mode: isPartial ? FileMode.append : FileMode.write);
      task.fileSink = sink;

      int receivedSinceStart = 0;
      var lastSpeedCheck = DateTime.now();
      int bytesAtLastCheck = 0;

      await for (final chunk in response) {
        if (task.isCancelled) {
          await sink.close();
          model.status = DownloadStatus.cancelled;
          await LocalNotificationServiceV().cancelNotification(model.id.hashCode);
          onProgress(model);
          return;
        }

        if (task.isPaused) {
          await sink.close();
          model.status = DownloadStatus.paused;
          await LocalNotificationServiceV().showDownloadPausedNotification(
            notificationId: model.id.hashCode,
            id: model.id,
            fileName: model.fileName,
            progress: model.progress,
            downloadedFormatted: formatBytes(model.downloadedBytes),
            totalFormatted: model.fileSize > 0 ? formatBytes(model.fileSize) : 'Unknown size',
          );
          onProgress(model);
          return;
        }

        sink.add(chunk);
        receivedSinceStart += chunk.length;
        model.downloadedBytes = existingBytes + receivedSinceStart;

        // Calculate progress & speed
        if (model.fileSize > 0) {
          model.progress = (model.downloadedBytes / model.fileSize).clamp(0.0, 1.0);
        }

        final now = DateTime.now();
        final diffMs = now.difference(lastSpeedCheck).inMilliseconds;
        if (diffMs >= 300) {
          final bytesDelta = receivedSinceStart - bytesAtLastCheck;
          final speedBytesPerSec = (bytesDelta / (diffMs / 1000.0)).toInt();
          model.speed = '${formatBytes(speedBytesPerSec)}/s';

          lastSpeedCheck = now;
          bytesAtLastCheck = receivedSinceStart;

          // Update local notification with live progress and action buttons
          LocalNotificationServiceV().showDownloadNotificationProgress(
            notificationId: model.id.hashCode,
            id: model.id,
            fileName: model.fileName,
            progress: model.progress,
            speed: model.speed,
            downloadedFormatted: formatBytes(model.downloadedBytes),
            totalFormatted: model.fileSize > 0 ? formatBytes(model.fileSize) : 'Unknown size',
          );

          onProgress(model);
        }
      }

      await sink.close();
      task.fileSink = null;

      if (!task.isPaused && !task.isCancelled) {
        model.status = DownloadStatus.completed;
        model.progress = 1.0;
        model.speed = '0 KB/s';

        // Notify Android MediaScanner so file is immediately indexed in native Files & Gallery
        await DownloadStorageService.notifyMediaScanner(model.filePath);

        await LocalNotificationServiceV().showDownloadCompleteNotification(
          notificationId: model.id.hashCode,
          fileName: model.fileName,
          filePath: model.filePath,
        );

        onComplete(model);
      }
    } catch (e) {
      if (!task.isCancelled && !task.isPaused) {
        model.status = DownloadStatus.failed;
        model.speed = '0 KB/s';
        final friendlyReason = formatErrorMessage(e);
        model.errorReason = friendlyReason;
        debugPrint('Download error for ${model.fileName}: $e ($friendlyReason)');

        await LocalNotificationServiceV().showDownloadFailedNotification(
          notificationId: model.id.hashCode,
          id: model.id,
          fileName: model.fileName,
          reason: friendlyReason,
        );

        onError(model, friendlyReason);
      }
    } finally {
      client?.close();
      _activeTasks.remove(model.id);
    }
  }

  void pauseDownload(String id) {
    final task = _activeTasks[id];
    if (task != null) {
      task.isPaused = true;
      task.request?.abort();
    }
  }

  void cancelDownload(String id) {
    final task = _activeTasks[id];
    if (task != null) {
      task.isCancelled = true;
      task.request?.abort();
    }
  }
}
