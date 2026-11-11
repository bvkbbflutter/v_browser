import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_browser/core/constants/app_constants.dart';
import 'package:v_browser/core/models/bookmark_model.dart';
import 'package:v_browser/core/models/browser_tab_model.dart';
import 'package:v_browser/core/models/download_model.dart';
import 'package:v_browser/core/models/history_model.dart';
import 'package:v_browser/core/services/media_detector.dart';
import 'package:v_browser/features/audio/models/audio_track_model.dart';
import 'package:v_browser/features/downloads/services/download_service.dart';
import 'package:v_browser/features/downloads/services/download_storage_service.dart';

void main() {
  group('URL & Search Query Helpers Tests', () {
    test('isLikelyUrl identifies web domains correctly', () {
      expect(AppConstants.isLikelyUrl('google.com'), isTrue);
      expect(AppConstants.isLikelyUrl('https://flutter.dev'), isTrue);
      expect(AppConstants.isLikelyUrl('subdomain.example.co.uk/path'), isTrue);
      expect(AppConstants.isLikelyUrl('hello world search'), isFalse);
      expect(AppConstants.isLikelyUrl('flutter tutorial'), isFalse);
    });

    test('normalizeUrl converts keywords to search engine queries', () {
      final googleQuery = AppConstants.normalizeUrl('flutter tutorial', searchEngine: 'google');
      expect(googleQuery, equals('https://www.google.com/search?q=flutter%20tutorial'));

      final ddgQuery = AppConstants.normalizeUrl('privacy browser', searchEngine: 'duckduckgo');
      expect(ddgQuery, equals('https://duckduckgo.com/?q=privacy%20browser'));

      final validUrl = AppConstants.normalizeUrl('github.com');
      expect(validUrl, equals('https://github.com'));
    });

    test('getDisplayHost extracts clean host', () {
      expect(AppConstants.getDisplayHost('https://www.youtube.com/watch?v=123'), equals('www.youtube.com'));
      expect(AppConstants.getDisplayHost('home'), equals('Home'));
      expect(AppConstants.getDisplayHost('about:blank'), equals('Home'));
    });
  });

  group('Intelligent Media Detection Tests', () {
    test('detects audio extensions and mime types', () {
      expect(MediaDetector.detect('https://example.com/song.mp3'), equals(DetectedMediaType.audio));
      expect(MediaDetector.detect('https://example.com/podcast.m4a'), equals(DetectedMediaType.audio));
      expect(MediaDetector.detect('https://example.com/audio.wav'), equals(DetectedMediaType.audio));
      expect(MediaDetector.detect('https://example.com/stream', mimeType: 'audio/mpeg'), equals(DetectedMediaType.audio));
    });

    test('detects video extensions and mime types', () {
      expect(MediaDetector.detect('https://example.com/video.mp4'), equals(DetectedMediaType.video));
      expect(MediaDetector.detect('https://example.com/stream.m3u8'), equals(DetectedMediaType.video));
      expect(MediaDetector.detect('https://example.com/clip.webm'), equals(DetectedMediaType.video));
      expect(MediaDetector.detect('https://example.com/feed', mimeType: 'video/mp4'), equals(DetectedMediaType.video));
    });

    test('detects downloadable files', () {
      expect(MediaDetector.detect('https://example.com/doc.pdf'), equals(DetectedMediaType.downloadable));
      expect(MediaDetector.detect('https://example.com/archive.zip'), equals(DetectedMediaType.downloadable));
      expect(MediaDetector.detect('https://example.com/app.apk'), equals(DetectedMediaType.downloadable));
    });

    test('leaves ordinary webpages as webpage', () {
      expect(MediaDetector.detect('https://www.youtube.com/watch?v=abc'), equals(DetectedMediaType.webpage));
      expect(MediaDetector.detect('https://github.com/flutter/flutter'), equals(DetectedMediaType.webpage));
      expect(MediaDetector.detect('https://news.ycombinator.com/'), equals(DetectedMediaType.webpage));
    });

    test('extracts clean file names', () {
      expect(MediaDetector.getFileName('https://example.com/files/document.pdf'), equals('document.pdf'));
      expect(
        MediaDetector.getFileName('https://example.com/download', contentDisposition: 'attachment; filename="my_song.mp3"'),
        equals('my_song.mp3'),
      );
    });
  });

  group('Models Serialization Tests', () {
    test('BrowserTabModel toMap and fromMap works', () {
      final tab = BrowserTabModel(
        id: 'tab_1',
        title: 'Flutter Dev',
        url: 'https://flutter.dev',
        isPrivate: true,
      );

      final map = tab.toMap();
      expect(map['id'], equals('tab_1'));
      expect(map['isPrivate'], isTrue);

      final fromMap = BrowserTabModel.fromMap(map);
      expect(fromMap.id, equals('tab_1'));
      expect(fromMap.title, equals('Flutter Dev'));
      expect(fromMap.isPrivate, isTrue);
    });

    test('AudioTrackModel toMap and fromMap works', () {
      final track = AudioTrackModel(
        id: 'track_1',
        title: 'Song Title',
        artist: 'Artist Name',
        url: 'https://example.com/song.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
      );

      final map = track.toMap();
      expect(map['title'], equals('Song Title'));
      expect(map['durationMs'], equals(225000));

      final restored = AudioTrackModel.fromMap(map);
      expect(restored.title, equals('Song Title'));
      expect(restored.artist, equals('Artist Name'));
      expect(restored.duration?.inSeconds, equals(225));
    });

    test('DownloadModel toMap and fromMap works with statuses', () {
      final download = DownloadModel(
        id: 'dl_1',
        fileName: 'sample.pdf',
        url: 'https://example.com/sample.pdf',
        filePath: '/storage/sample.pdf',
        fileSize: 1048576,
        downloadedBytes: 524288,
        progress: 0.5,
        speed: '512 KB/s',
        status: DownloadStatus.downloading,
      );

      final map = download.toMap();
      expect(map['status'], equals('downloading'));
      expect(map['speed'], equals('512 KB/s'));

      final restored = DownloadModel.fromMap(map);
      expect(restored.fileName, equals('sample.pdf'));
      expect(restored.status, equals(DownloadStatus.downloading));
      expect(restored.downloadedBytes, equals(524288));
    });

    test('BookmarkModel toMap and fromMap works', () {
      final bookmark = BookmarkModel(
        id: 'bm_1',
        title: 'Wikipedia',
        url: 'https://wikipedia.org',
        folder: 'Reference',
      );

      final map = bookmark.toMap();
      expect(map['folder'], equals('Reference'));

      final restored = BookmarkModel.fromMap(map);
      expect(restored.title, equals('Wikipedia'));
      expect(restored.folder, equals('Reference'));
    });

    test('HistoryModel toMap and fromMap works', () {
      final history = HistoryModel(
        id: 'hist_1',
        title: 'Dart Documentation',
        url: 'https://dart.dev',
      );

      final map = history.toMap();
      final restored = HistoryModel.fromMap(map);
      expect(restored.url, equals('https://dart.dev'));
    });
  });

  group('Download Service & Formatting Tests', () {
    test('formatBytes handles zero and edge sizes correctly', () {
      expect(DownloadService.formatBytes(0), equals('0 B'));
      expect(DownloadService.formatBytes(500), equals('500 B'));
      expect(DownloadService.formatBytes(1024), equals('1.0 KB'));
      expect(DownloadService.formatBytes(1048576), equals('1.0 MB'));
      expect(DownloadService.formatBytes(1073741824), equals('1.0 GB'));
    });

    test('DownloadStatus enum contains all required states', () {
      expect(DownloadStatus.values, contains(DownloadStatus.pending));
      expect(DownloadStatus.values, contains(DownloadStatus.downloading));
      expect(DownloadStatus.values, contains(DownloadStatus.paused));
      expect(DownloadStatus.values, contains(DownloadStatus.completed));
      expect(DownloadStatus.values, contains(DownloadStatus.failed));
      expect(DownloadStatus.values, contains(DownloadStatus.cancelled));
    });

    test('resolveSafeFilePath preserves original name when file does not exist', () {
      final tempDir = Directory.systemTemp.createTempSync('vortex_dl_test_');
      try {
        final path = DownloadStorageService.resolveSafeFilePath(tempDir, 'presentation.pdf');
        expect(path.endsWith('presentation.pdf'), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveSafeFilePath handles duplicate filenames safely', () {
      final tempDir = Directory.systemTemp.createTempSync('vortex_dl_test_');
      try {
        final file1 = File('${tempDir.path}/report.pdf');
        file1.writeAsStringSync('sample content');

        final resolvedPath = DownloadStorageService.resolveSafeFilePath(tempDir, 'report.pdf');
        expect(resolvedPath.endsWith('report (1).pdf'), isTrue);

        final file2 = File(resolvedPath);
        file2.writeAsStringSync('sample content 2');

        final resolvedPath2 = DownloadStorageService.resolveSafeFilePath(tempDir, 'report.pdf');
        expect(resolvedPath2.endsWith('report (2).pdf'), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolveSafeFilePath handles files without extension', () {
      final tempDir = Directory.systemTemp.createTempSync('vortex_dl_test_');
      try {
        final file1 = File('${tempDir.path}/archive');
        file1.writeAsStringSync('sample content');

        final resolvedPath = DownloadStorageService.resolveSafeFilePath(tempDir, 'archive');
        expect(resolvedPath.endsWith('archive (1)'), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
