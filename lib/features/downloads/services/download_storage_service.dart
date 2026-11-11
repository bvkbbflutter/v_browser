import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DownloadStorageService {
  static const String appFolderName = 'Vortex';
  static const MethodChannel _mediaStoreChannel = MethodChannel('com.example.v_browser/media_store');

  /// Resolves the dedicated folder inside the device's default Downloads directory.
  /// (e.g. `Downloads/Vortex/` or `/storage/emulated/0/Download/Vortex`).
  /// Automatically creates the directory if it does not exist.
  static Future<Directory> getAppDownloadsDirectory() async {
    Directory? targetDir;

    if (Platform.isAndroid) {
      // 1. Primary path: Device's default public Downloads directory
      final publicDownloads = Directory('/storage/emulated/0/Download/$appFolderName');
      try {
        if (!await publicDownloads.exists()) {
          await publicDownloads.create(recursive: true);
        }
        // Verify write permission on the folder
        final testFile = File('${publicDownloads.path}/.vortex_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        targetDir = publicDownloads;
      } catch (e) {
        debugPrint('Public /storage/emulated/0/Download/$appFolderName write check failed: $e');
      }

      // 2. Secondary path: /sdcard/Download/Vortex
      if (targetDir == null) {
        try {
          final sdcardDir = Directory('/sdcard/Download/$appFolderName');
          if (!await sdcardDir.exists()) {
            await sdcardDir.create(recursive: true);
          }
          final testFile = File('${sdcardDir.path}/.vortex_test');
          await testFile.writeAsString('test');
          await testFile.delete();
          targetDir = sdcardDir;
        } catch (_) {}
      }

      // 3. Tertiary path: Base external storage root + /Download/Vortex
      if (targetDir == null) {
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final rootParts = ext.path.split('/Android');
            if (rootParts.isNotEmpty) {
              final rootDownload = Directory('${rootParts[0]}/Download/$appFolderName');
              if (!await rootDownload.exists()) {
                await rootDownload.create(recursive: true);
              }
              targetDir = rootDownload;
            }
          }
        } catch (_) {}
      }

      // 4. Safe fallback for restricted scoped storage: app external files + /Vortex
      if (targetDir == null) {
        final ext = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final fallback = Directory('${ext.path}/$appFolderName');
        if (!await fallback.exists()) {
          await fallback.create(recursive: true);
        }
        targetDir = fallback;
      }
    } else {
      // iOS / Desktop / Other platforms
      final downloads = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final dir = Directory('${downloads.path}/$appFolderName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      targetDir = dir;
    }

    return targetDir;
  }

  /// Preserves the original filename while handling duplicates safely.
  /// If `file.ext` exists, produces `file (1).ext`, `file (2).ext`, etc.
  static String resolveSafeFilePath(Directory directory, String originalFileName) {
    // Sanitize illegal filesystem characters
    String cleanName = originalFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleanName.isEmpty) {
      cleanName = 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    final dotIndex = cleanName.lastIndexOf('.');
    String baseName = cleanName;
    String extension = '';

    if (dotIndex != -1 && dotIndex < cleanName.length - 1) {
      baseName = cleanName.substring(0, dotIndex);
      extension = cleanName.substring(dotIndex); // includes the dot
    }

    String finalPath = '${directory.path}/$cleanName';
    int counter = 1;

    while (File(finalPath).existsSync()) {
      finalPath = '${directory.path}/$baseName ($counter)$extension';
      counter++;
    }

    return finalPath;
  }

  /// Triggers Android's native MediaScannerConnection so that the newly downloaded
  /// file is immediately indexed and accessible in the device's native Files app,
  /// File Manager, Gallery, Audio players, and Downloads view.
  static Future<void> notifyMediaScanner(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaStoreChannel.invokeMethod('scanFile', {'path': filePath});
      debugPrint('MediaScanner successfully notified for: $filePath');
    } catch (e) {
      debugPrint('Error notifying MediaScanner for $filePath: $e');
    }
  }
}
