import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isLocked = false;
  bool _isLandscape = false;
  double _playbackSpeed = 1.0;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
    });

    try {
      final uri = Uri.parse(widget.url);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      _controller.addListener(_videoListener);
      await _controller.play();

      setState(() {
        _isInitialized = true;
      });
      _startHideTimer();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying && !_isLocked) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isLandscape,
        bottom: !_isLandscape,
        child: _hasError
            ? _buildErrorView()
            : (!_isInitialized
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video Surface
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio > 0
                                ? _controller.value.aspectRatio
                                : 16 / 9,
                            child: VideoPlayer(_controller),
                          ),
                        ),

                        // Buffering indicator
                        if (_controller.value.isBuffering)
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),

                        // Controls Overlay
                        if (_showControls) _buildControlsOverlay(),
                      ],
                    ),
                  )),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final totalSeconds = duration.inSeconds.toDouble();
    final currentSeconds = position.inSeconds.toDouble().clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0);

    return Container(
      color: Colors.black38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(_isLocked ? Icons.lock : Icons.lock_open_rounded, color: Colors.white),
                  tooltip: _isLocked ? 'Unlock controls' : 'Lock controls',
                  onPressed: () {
                    setState(() {
                      _isLocked = !_isLocked;
                    });
                  },
                ),
                PopupMenuButton<double>(
                  tooltip: 'Speed',
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onSelected: (speed) {
                    setState(() {
                      _playbackSpeed = speed;
                    });
                    _controller.setPlaybackSpeed(speed);
                  },
                  itemBuilder: (ctx) => [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Text('${s}x${s == _playbackSpeed ? ' ✓' : ''}'),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Center Play / Rewind / Forward Controls
          if (!_isLocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 40),
                  onPressed: () {
                    final target = position - const Duration(seconds: 10);
                    _controller.seekTo(target > Duration.zero ? target : Duration.zero);
                    _startHideTimer();
                  },
                ),
                const SizedBox(width: 32),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                    onPressed: () {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        _hideControlsTimer?.cancel();
                      } else {
                        _controller.play();
                        _startHideTimer();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 40),
                  onPressed: () {
                    final target = position + const Duration(seconds: 10);
                    _controller.seekTo(target < duration ? target : duration);
                    _startHideTimer();
                  },
                ),
              ],
            )
          else
            const SizedBox.shrink(),

          // Bottom Timeline & Orientation Bar
          if (!_isLocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            trackHeight: 3,
                            activeTrackColor: Colors.redAccent,
                            thumbColor: Colors.redAccent,
                            inactiveTrackColor: Colors.white30,
                          ),
                          child: Slider(
                            value: currentSeconds,
                            min: 0.0,
                            max: totalSeconds > 0 ? totalSeconds : 1.0,
                            onChanged: (val) {
                              _controller.seekTo(Duration(seconds: val.toInt()));
                              _startHideTimer();
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: _isLandscape ? 'Exit Fullscreen' : 'Fullscreen',
                        onPressed: _toggleOrientation,
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Cannot Play Video',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializePlayer,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Browser', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
