import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/audio_player_screen.dart';

class FloatingAudioPlayer extends StatelessWidget {
  const FloatingAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    if (!audio.isFloatingVisible || audio.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final track = audio.currentTrack!;
    final screenSize = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).padding;
    final isCollapsed = audio.isCollapsed;

    return Positioned(
      left: audio.floatingPosition.dx,
      top: audio.floatingPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          audio.updateFloatingPosition(details.delta, screenSize, insets);
        },
        onPanEnd: (_) {
          if (isCollapsed) {
            audio.snapToNearestEdge(screenSize, insets);
          }
        },
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(isCollapsed ? 27 : 28),
          color: isDark ? const Color(0xFF1E1B2C) : Colors.white,
          shadowColor: theme.colorScheme.primary.withOpacity(0.35),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: isCollapsed ? 54 : 264,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isCollapsed ? 27 : 28),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isCollapsed
                ? _buildCollapsedView(context, audio, theme)
                : _buildExpandedView(context, audio, track, theme, screenSize, insets),
          ),
        ),
      ),
    );
  }

  // COLLAPSED BUBBLE (MINIMIZED)
  Widget _buildCollapsedView(BuildContext context, AudioProvider audio, ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Tap whole bubble to expand
        InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: () {
            final screenSize = MediaQuery.of(context).size;
            final insets = MediaQuery.of(context).padding;
            audio.toggleCollapse(screenSize, insets);
          },
          child: Center(
            child: Icon(
              audio.isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
        ),

        // Mini expand arrow badge
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.unfold_more_rounded, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // EXPANDED CONTROLS
  Widget _buildExpandedView(
    BuildContext context,
    AudioProvider audio,
    dynamic track,
    ThemeData theme,
    Size screenSize,
    EdgeInsets insets,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Album Art / Music Icon (Tap to open full player)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        track.artworkUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white, size: 20),
                      ),
                    )
                  : const Icon(Icons.music_note, color: Colors.white, size: 20),
            ),
          ),

          const SizedBox(width: 8),

          // Title & Status (Tap to open full player)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AudioPlayerScreen()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    audio.isPlaying ? 'Playing' : 'Paused',
                    style: TextStyle(
                      fontSize: 10,
                      color: audio.isPlaying ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play / Pause Button
          IconButton(
            icon: Icon(
              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => audio.togglePlayPause(),
          ),

          // Collapse Arrow Button
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            tooltip: 'Collapse',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
            onPressed: () => audio.toggleCollapse(screenSize, insets),
          ),

          // Close Button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Close audio',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
            onPressed: () => audio.closeFloatingPlayer(),
          ),
        ],
      ),
    );
  }
}
