import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../services/local_notification_service.dart';
import '../models/audio_track_model.dart';
import '../services/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _service = AudioService();

  AudioTrackModel? _currentTrack;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  double _volume = 1.0;
  LoopMode _loopMode = LoopMode.off;

  // Floating Player coordinates, visibility, and collapsed state
  bool _isFloatingVisible = false;
  bool _isCollapsed = false;
  Offset _floatingPosition = const Offset(16, 500);

  // Subscriptions
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _speedSub;

  AudioTrackModel? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  bool get isFloatingVisible => _isFloatingVisible && _currentTrack != null;
  bool get isCollapsed => _isCollapsed;
  Offset get floatingPosition => _floatingPosition;

  AudioProvider() {
    _initListeners();
    AudioService.onStopRequested = () {
      _isFloatingVisible = false;
      _currentTrack = null;
      notifyListeners();
    };
  }

  void _initListeners() {
    _playerStateSub = _service.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        _position = Duration.zero;
      }

      notifyListeners();
    });

    _positionSub = _service.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _service.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _speedSub = _service.speedStream.listen((s) {
      _speed = s;
      notifyListeners();
    });
  }

  Future<void> playTrack(AudioTrackModel track) async {
    _currentTrack = track;
    _isFloatingVisible = true;
    _isCollapsed = false;
    notifyListeners();

    // Ensure notification permission is requested on Android 13+
    await LocalNotificationServiceV().requestPermission();

    await _service.playTrack(track);
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _service.pause();
    } else {
      await _service.play();
    }
  }

  Future<void> seek(Duration target) async {
    await _service.seek(target);
  }

  Future<void> seekRelative(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await _service.seek(clamped);
  }

  Future<void> setSpeed(double s) async {
    _speed = s;
    await _service.setSpeed(s);
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v;
    await _service.setVolume(v);
    notifyListeners();
  }

  Future<void> toggleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    await _service.setLoopMode(_loopMode);
    notifyListeners();
  }

  void toggleCollapse(Size screenSize, EdgeInsets insets) {
    _isCollapsed = !_isCollapsed;
    if (_isCollapsed) {
      // Snap to nearest edge (left or right)
      snapToNearestEdge(screenSize, insets);
    } else {
      // Ensure expanded width fits
      const expandedWidth = 264.0;
      final maxX = screenSize.width - expandedWidth - insets.right - 8.0;
      if (_floatingPosition.dx > maxX) {
        _floatingPosition = Offset(maxX, _floatingPosition.dy);
      }
    }
    notifyListeners();
  }

  void updateFloatingPosition(Offset delta, Size screenSize, EdgeInsets insets) {
    final playerWidth = _isCollapsed ? 54.0 : 264.0;
    const playerHeight = 54.0;

    final minX = insets.left + 4.0;
    final maxX = screenSize.width - playerWidth - insets.right - 4.0;
    final minY = insets.top + 50.0; // below URL bar
    final maxY = screenSize.height - playerHeight - insets.bottom - 52.0; // above bottom nav

    final newX = (_floatingPosition.dx + delta.dx).clamp(minX, maxX);
    final newY = (_floatingPosition.dy + delta.dy).clamp(minY, maxY);

    _floatingPosition = Offset(newX, newY);
    notifyListeners();
  }

  void snapToNearestEdge(Size screenSize, EdgeInsets insets) {
    const collapsedWidth = 54.0;
    final midX = screenSize.width / 2.0;
    final targetX = _floatingPosition.dx + (collapsedWidth / 2.0) < midX
        ? (insets.left + 8.0)
        : (screenSize.width - collapsedWidth - insets.right - 8.0);

    _floatingPosition = Offset(targetX, _floatingPosition.dy);
    notifyListeners();
  }

  Future<void> closeFloatingPlayer() async {
    _isFloatingVisible = false;
    await _service.stop();
    _currentTrack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _speedSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
