import 'dart:async';
import 'package:audio_service/audio_service.dart' as as_pkg;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_track_model.dart';

class VAudioHandler extends as_pkg.BaseAudioHandler with as_pkg.SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  VAudioHandler() {
    _init();
  }

  AudioPlayer get player => _player;

  void _init() {
    // 1. Broadcast playback events to MediaSession & notification
    _player.playbackEventStream.listen(_broadcastState);

    // 2. Broadcast duration updates
    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // 3. Handle playback completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        pause();
        seek(Duration.zero);
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          as_pkg.MediaControl.rewind,
          if (playing) as_pkg.MediaControl.pause else as_pkg.MediaControl.play,
          as_pkg.MediaControl.fastForward,
          as_pkg.MediaControl.stop,
        ],
        systemActions: const {
          as_pkg.MediaAction.seek,
          as_pkg.MediaAction.seekForward,
          as_pkg.MediaAction.seekBackward,
          as_pkg.MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: as_pkg.AudioProcessingState.idle,
          ProcessingState.loading: as_pkg.AudioProcessingState.loading,
          ProcessingState.buffering: as_pkg.AudioProcessingState.buffering,
          ProcessingState.ready: as_pkg.AudioProcessingState.ready,
          ProcessingState.completed: as_pkg.AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  Future<void> playTrack(AudioTrackModel track) async {
    final item = as_pkg.MediaItem(
      id: track.id,
      title: track.title.isNotEmpty ? track.title : 'Audio Track',
      artist: track.artist.isNotEmpty ? track.artist : 'Vortex Browser',
      duration: track.duration,
    );
    mediaItem.add(item);

    try {
      if (track.url.startsWith('http://') || track.url.startsWith('https://')) {
        await _player.setUrl(track.url);
      } else {
        await _player.setFilePath(track.url);
      }
      await play();
    } catch (e) {
      debugPrint('Error playing track in audio handler: $e');
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: as_pkg.AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
    AudioService.onStopRequested?.call();
  }
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static VAudioHandler? _handler;
  static VoidCallback? onStopRequested;

  static VAudioHandler get handler {
    if (_handler == null) {
      throw StateError('AudioHandler not initialized. Call AudioService.init() first.');
    }
    return _handler!;
  }

  static Future<void> init() async {
    if (_handler != null) return;

    _handler = await as_pkg.AudioService.init(
      builder: () => VAudioHandler(),
      config: const as_pkg.AudioServiceConfig(
        androidNotificationChannelId: 'com.example.v_browser.channel.audio',
        androidNotificationChannelName: 'Vortex Audio Playback',
        androidNotificationChannelDescription: 'Notification for media playback and controls',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidNotificationClickStartsActivity: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF6C5CE7),
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
  }

  AudioPlayer get player => handler.player;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<double> get speedStream => player.speedStream;
  Stream<double> get volumeStream => player.volumeStream;
  Stream<LoopMode> get loopModeStream => player.loopModeStream;

  Duration get position => player.position;
  Duration? get duration => player.duration;
  bool get isPlaying => player.playing;

  Future<void> playTrack(AudioTrackModel track) async {
    await handler.playTrack(track);
  }

  Future<void> play() async => await handler.play();
  Future<void> pause() async => await handler.pause();
  Future<void> stop() async {
    await handler.stop();
    onStopRequested?.call();
  }
  Future<void> seek(Duration position) async => await handler.seek(position);
  Future<void> setSpeed(double speed) async => await handler.setSpeed(speed);
  Future<void> setVolume(double volume) async => await player.setVolume(volume);
  Future<void> setLoopMode(LoopMode mode) async => await player.setLoopMode(mode);

  void dispose() {
    // handler stops
  }
}
