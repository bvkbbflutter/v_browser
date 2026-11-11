import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audio Player')),
        body: const Center(child: Text('No audio currently loaded.')),
      );
    }

    final totalSeconds = audio.duration.inSeconds.toDouble();
    final currentSeconds = audio.position.inSeconds.toDouble().clamp(0.0, totalSeconds > 0 ? totalSeconds : 1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131A) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          tooltip: 'Minimize to Floating Player',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              audio.loopMode == LoopMode.off
                  ? Icons.repeat
                  : (audio.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat_on_rounded),
              color: audio.loopMode != LoopMode.off ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Repeat mode',
            onPressed: () => audio.toggleLoopMode(),
          ),
          PopupMenuButton<double>(
            tooltip: 'Playback Speed',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${audio.speed}x',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
            onSelected: (speed) => audio.setSpeed(speed),
            itemBuilder: (ctx) => [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text('${s}x${s == audio.speed ? ' ✓' : ''}'),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(),

              // Album Art / Audio Icon
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.secondary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          track.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, size: 90, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.music_note_rounded, size: 90, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // Title & Artist
              Text(
                track.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                track.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

              const Spacer(),

              // Progress Scrubber Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: currentSeconds,
                  min: 0.0,
                  max: totalSeconds > 0 ? totalSeconds : 1.0,
                  onChanged: (val) {
                    audio.seek(Duration(seconds: val.toInt()));
                  },
                ),
              ),

              // Elapsed & Total Time Labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(audio.position),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    Text(
                      _formatDuration(audio.duration),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 32),
                    tooltip: 'Rewind 10s',
                    onPressed: () => audio.seekRelative(-10),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: audio.isBuffering
                        ? const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                            onPressed: () => audio.togglePlayPause(),
                          ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 32),
                    tooltip: 'Forward 10s',
                    onPressed: () => audio.seekRelative(10),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Volume Slider
              Row(
                children: [
                  Icon(Icons.volume_down_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  Expanded(
                    child: Slider(
                      value: audio.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => audio.setVolume(val),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
