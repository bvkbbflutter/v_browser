import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/models/download_model.dart';
import '../../../core/services/media_detector.dart';
import '../../audio/models/audio_track_model.dart';
import '../../audio/providers/audio_provider.dart';
import '../../video/screens/video_player_screen.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final allDownloads = downloadProvider.downloads;

    final activeDownloads = allDownloads.where(
      (d) => d.status == DownloadStatus.downloading || d.status == DownloadStatus.paused || d.status == DownloadStatus.pending,
    ).toList();

    final completedDownloads = allDownloads.where((d) => d.status == DownloadStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${allDownloads.length})'),
            Tab(text: 'Active (${activeDownloads.length})'),
            Tab(text: 'Completed (${completedDownloads.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadList(context, allDownloads),
          _buildDownloadList(context, activeDownloads),
          _buildDownloadList(context, completedDownloads),
        ],
      ),
    );
  }

  Widget _buildDownloadList(BuildContext context, List<DownloadModel> list) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_off_rounded, size: 54, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              'No downloads in this section',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final downloadProvider = context.read<DownloadProvider>();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        final isDownloading = item.status == DownloadStatus.downloading;
        final isPaused = item.status == DownloadStatus.paused;
        final isCompleted = item.status == DownloadStatus.completed;
        final isFailed = item.status == DownloadStatus.failed;
        final isCancelled = item.status == DownloadStatus.cancelled;

        final dateStr = DateFormat('MMM d, h:mm a').format(item.createdAt);

        return Card(
          elevation: 0.5,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDownloading
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getStatusColor(item.status).withOpacity(0.12),
                      child: Icon(
                        _getFileIcon(item.fileName),
                        size: 20,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildStatusBadge(item.status),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCompleted
                                      ? '${DownloadService.formatBytes(item.fileSize)} · $dateStr'
                                      : (isDownloading
                                          ? '${DownloadService.formatBytes(item.downloadedBytes)} of ${item.fileSize > 0 ? DownloadService.formatBytes(item.fileSize) : '?'} (${item.speed})'
                                          : DownloadService.formatBytes(item.downloadedBytes)),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons (Open, Share, Delete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted) ...[
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 20),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Share',
                            onPressed: () => downloadProvider.shareDownload(item.filePath),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete',
                          onPressed: () => downloadProvider.deleteDownload(item.id),
                        ),
                      ],
                    ),
                  ],
                ),

                // Progress Bar if not completed
                if (!isCompleted) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress > 0 ? item.progress : null,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(item.status)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(item.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(item.status),
                        ),
                      ),
                      Row(
                        children: [
                          if (isDownloading) ...[
                            TextButton.icon(
                              onPressed: () => downloadProvider.pauseDownload(item.id),
                              icon: const Icon(Icons.pause, size: 16),
                              label: const Text('Pause'),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            ),
                            TextButton.icon(
                              onPressed: () => downloadProvider.cancelDownload(item.id),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ] else if (isPaused) ...[
                            TextButton.icon(
                              onPressed: () => downloadProvider.resumeDownload(item.id),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Resume'),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            ),
                            TextButton.icon(
                              onPressed: () => downloadProvider.cancelDownload(item.id),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ] else if (isFailed || isCancelled) ...[
                            TextButton.icon(
                              onPressed: () => downloadProvider.retryDownload(item.id),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],

                if (isFailed && item.errorReason != null && item.errorReason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.errorReason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (ctx) {
                      final isAudio = MediaDetector.isAudio(item.filePath, mimeType: item.mimeType);
                      final isVideo = MediaDetector.isVideo(item.filePath, mimeType: item.mimeType);

                      return InkWell(
                        onTap: () {
                          if (isAudio) {
                            ctx.read<AudioProvider>().playTrack(
                              AudioTrackModel(
                                id: item.filePath,
                                title: item.fileName,
                                url: item.filePath,
                              ),
                            );
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Playing: ${item.fileName}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else if (isVideo) {
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(url: item.filePath, title: item.fileName),
                              ),
                            );
                          } else {
                            downloadProvider.openDownload(item.filePath);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAudio
                                    ? Icons.play_circle_filled_rounded
                                    : (isVideo ? Icons.play_arrow_rounded : Icons.open_in_new_rounded),
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAudio
                                    ? 'Play in Audio Player'
                                    : (isVideo ? 'Play in Video Player' : 'Tap to open file'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(DownloadStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return const Color(0xFF1976D2);
      case DownloadStatus.completed:
        return const Color(0xFF2E7D32);
      case DownloadStatus.paused:
        return const Color(0xFFEF6C00);
      case DownloadStatus.failed:
        return const Color(0xFFC62828);
      case DownloadStatus.cancelled:
        return Colors.grey;
      case DownloadStatus.pending:
        return const Color(0xFF00838F);
    }
  }

  IconData _getFileIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.mp4') || lower.endsWith('.mkv') || lower.endsWith('.webm') || lower.endsWith('.mov')) {
      return Icons.video_file_rounded;
    }
    if (lower.endsWith('.mp3') || lower.endsWith('.wav') || lower.endsWith('.aac') || lower.endsWith('.m4a') || lower.endsWith('.flac')) {
      return Icons.audio_file_rounded;
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar') || lower.endsWith('.7z')) {
      return Icons.folder_zip_rounded;
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description_rounded;
    if (lower.endsWith('.apk')) return Icons.android_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
