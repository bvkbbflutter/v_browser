enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadModel {
  final String id;
  String fileName;
  final String url;
  String filePath;
  int fileSize;
  int downloadedBytes;
  double progress;
  String speed; // e.g. "1.2 MB/s"
  DownloadStatus status;
  final DateTime createdAt;
  String? mimeType;
  bool canResume;
  String? cookie;
  String? referer;
  String? userAgent;
  String? errorReason;

  DownloadModel({
    required this.id,
    required this.fileName,
    required this.url,
    required this.filePath,
    this.fileSize = 0,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.speed = '0 KB/s',
    this.status = DownloadStatus.downloading,
    DateTime? createdAt,
    this.mimeType,
    this.canResume = true,
    this.cookie,
    this.referer,
    this.userAgent,
    this.errorReason,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'url': url,
      'filePath': filePath,
      'fileSize': fileSize,
      'downloadedBytes': downloadedBytes,
      'progress': progress,
      'speed': speed,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'mimeType': mimeType,
      'canResume': canResume,
      'cookie': cookie,
      'referer': referer,
      'userAgent': userAgent,
      'errorReason': errorReason,
    };
  }

  factory DownloadModel.fromMap(Map<dynamic, dynamic> map) {
    return DownloadModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: map['fileName'] as String? ?? 'file',
      url: map['url'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      fileSize: map['fileSize'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      speed: map['speed'] as String? ?? '0 KB/s',
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.completed,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      mimeType: map['mimeType'] as String?,
      canResume: map['canResume'] as bool? ?? true,
      cookie: map['cookie'] as String?,
      referer: map['referer'] as String?,
      userAgent: map['userAgent'] as String?,
      errorReason: map['errorReason'] as String?,
    );
  }
}
