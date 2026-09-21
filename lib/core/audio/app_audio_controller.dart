import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioPlaybackState {
  final String? currentMessageId;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? currentAudioPath;

  const AudioPlaybackState({
    this.currentMessageId,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.currentAudioPath,
  });

  AudioPlaybackState copyWith({
    String? currentMessageId,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    String? currentAudioPath,
  }) {
    return AudioPlaybackState(
      currentMessageId: currentMessageId ?? this.currentMessageId,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      currentAudioPath: currentAudioPath ?? this.currentAudioPath,
    );
  }
}

class AppAudioController extends ChangeNotifier {
  static final AppAudioController _instance = AppAudioController._internal();
  factory AppAudioController() => _instance;

  late final AudioPlayer _player;
  AudioPlaybackState _state = const AudioPlaybackState();

  AudioPlaybackState get state => _state;
  AudioPlayer get player => _player;
  String? get currentMessageId => _state.currentMessageId;
  bool get isPlaying => _state.isPlaying;
  Duration get position => _state.position;
  Duration get duration => _state.duration;
  double get speed => _state.speed;

  AppAudioController._internal() {
    _player = AudioPlayer();
    _initStreams();
  }

  void _initStreams() {
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      if (processingState == ProcessingState.completed) {
        _state = _state.copyWith(
          isPlaying: false,
          position: _state.duration,
        );
        notifyListeners();
      } else {
        _state = _state.copyWith(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        );
        notifyListeners();
      }
    });

    _player.positionStream.listen((pos) {
      _state = _state.copyWith(position: pos);
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _state = _state.copyWith(duration: dur);
        notifyListeners();
      }
    });

    _player.speedStream.listen((spd) {
      _state = _state.copyWith(speed: spd);
      notifyListeners();
    });
  }

  /// Plays or pauses audio for a given message
  Future<void> playOrPause({
    required String messageId,
    required String audioPath,
    String title = 'Explainer Audio',
    String subtitle = 'Sarvam AI Voice',
  }) async {
    // If clicking on the same message that's currently loaded
    if (_state.currentMessageId == messageId && _state.currentAudioPath == audioPath) {
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
      return;
    }

    // New audio file to play
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioPath');
      }

      final audioSource = AudioSource.file(
        audioPath,
        tag: MediaItem(
          id: messageId,
          album: 'Explainer AI',
          title: title,
          artist: subtitle,
        ),
      );

      _state = _state.copyWith(
        currentMessageId: messageId,
        currentAudioPath: audioPath,
        position: Duration.zero,
        duration: Duration.zero,
      );
      notifyListeners();

      await _player.setAudioSource(audioSource);
      await _player.setSpeed(_state.speed);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _state = _state.copyWith(speed: speed);
    notifyListeners();
  }

  Future<void> cycleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    int currentIndex = speeds.indexWhere((s) => (s - _state.speed).abs() < 0.05);
    if (currentIndex == -1) currentIndex = 1;
    final nextIndex = (currentIndex + 1) % speeds.length;
    await setSpeed(speeds[nextIndex]);
  }

  Future<void> seekForward10() async {
    final newPos = _state.position + const Duration(seconds: 10);
    final target = newPos > _state.duration ? _state.duration : newPos;
    await _player.seek(target);
  }

  Future<void> seekBackward10() async {
    final newPos = _state.position - const Duration(seconds: 10);
    final target = newPos < Duration.zero ? Duration.zero : newPos;
    await _player.seek(target);
  }

  Future<void> stop() async {
    await _player.stop();
    _state = _state.copyWith(
      isPlaying: false,
      position: Duration.zero,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
