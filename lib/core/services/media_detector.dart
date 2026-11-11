enum DetectedMediaType {
  audio,
  video,
  downloadable,
  webpage,
}

class MediaDetector {
  static const Set<String> audioExtensions = {
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'oga',
    'flac',
    'opus',
    'weba',
    'wma',
    'mid',
    'midi',
  };

  static const Set<String> videoExtensions = {
    'mp4',
    'webm',
    'mkv',
    'mov',
    'm4v',
    '3gp',
    'm3u8',
    'ts',
    'avi',
    'flv',
    'wmv',
  };

  static const Set<String> downloadableExtensions = {
    'pdf',
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'apk',
    'exe',
    'dmg',
    'iso',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'epub',
    'csv',
    'txt',
    'bin',
  };

  static String getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastSlash = path.lastIndexOf('/');
      final filename = lastSlash != -1 ? path.substring(lastSlash + 1) : path;
      final dot = filename.lastIndexOf('.');
      if (dot != -1 && dot < filename.length - 1) {
        return filename.substring(dot + 1).toLowerCase();
      }
    } catch (_) {}
    return '';
  }

  static String getFileName(String url, {String? contentDisposition}) {
    if (contentDisposition != null && contentDisposition.isNotEmpty) {
      final match = RegExp(r'filename[^;=\n]*=(([\x27\x22]).*?\2|[^;\n]*)').firstMatch(contentDisposition);
      if (match != null && match.group(1) != null) {
        var fn = match.group(1)!.trim();
        if ((fn.startsWith('"') && fn.endsWith('"')) || (fn.startsWith("'") && fn.endsWith("'"))) {
          fn = fn.substring(1, fn.length - 1);
        }
        if (fn.isNotEmpty) return fn;
      }
    }

    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.trim().isNotEmpty) {
          return Uri.decodeComponent(last);
        }
      }
    } catch (_) {}

    return 'file_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool isAudio(String url, {String? mimeType}) {
    if (mimeType != null && mimeType.toLowerCase().startsWith('audio/')) {
      return true;
    }
    final ext = getExtension(url);
    return audioExtensions.contains(ext);
  }

  static bool isVideo(String url, {String? mimeType}) {
    if (mimeType != null) {
      final m = mimeType.toLowerCase();
      if (m.startsWith('video/') || m == 'application/x-mpegurl' || m == 'application/vnd.apple.mpegurl') {
        return true;
      }
    }
    final ext = getExtension(url);
    return videoExtensions.contains(ext);
  }

  static bool isDownloadable(String url, {String? mimeType}) {
    if (mimeType != null) {
      final m = mimeType.toLowerCase();
      if (m == 'application/pdf' ||
          m == 'application/zip' ||
          m == 'application/octet-stream' ||
          m.startsWith('application/vnd.')) {
        return true;
      }
    }
    final ext = getExtension(url);
    return downloadableExtensions.contains(ext);
  }

  static DetectedMediaType detect(String url, {String? mimeType, String? contentDisposition}) {
    // If it's a known web service page (e.g. youtube.com, vimeo.com), do not treat as raw media
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com/watch') ||
        lower.contains('youtu.be/') ||
        lower.contains('vimeo.com/') ||
        lower.contains('soundcloud.com/') ||
        lower.contains('open.spotify.com/')) {
      return DetectedMediaType.webpage;
    }

    if (isAudio(url, mimeType: mimeType)) {
      return DetectedMediaType.audio;
    }
    if (isVideo(url, mimeType: mimeType)) {
      return DetectedMediaType.video;
    }
    if (isDownloadable(url, mimeType: mimeType)) {
      return DetectedMediaType.downloadable;
    }
    return DetectedMediaType.webpage;
  }
}
