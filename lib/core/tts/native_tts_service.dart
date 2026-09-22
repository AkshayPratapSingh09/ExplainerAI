import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum NativeTtsState { playing, stopped, paused, continued }

class NativeVoiceInfo {
  final String name;
  final String locale;
  final int quality;
  final int latency;
  final bool isNetworkRequired;
  final Map<dynamic, dynamic> raw;

  NativeVoiceInfo({
    required this.name,
    required this.locale,
    this.quality = 300,
    this.latency = 300,
    this.isNetworkRequired = false,
    required this.raw,
  });

  String get displayName {
    final cleanLocale = locale.replaceAll('_', '-').toUpperCase();
    return '$cleanLocale - $name';
  }

  bool get isIndianEnglish => locale.toLowerCase().contains('en-in') || locale.toLowerCase().contains('en_in');
  bool get isHindi => locale.toLowerCase().contains('hi-in') || locale.toLowerCase().contains('hi_in');
}

class NativeTtsService extends ChangeNotifier {
  static final NativeTtsService _instance = NativeTtsService._internal();
  factory NativeTtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();

  NativeTtsState _state = NativeTtsState.stopped;
  List<dynamic> _availableEngines = [];
  List<NativeVoiceInfo> _allVoices = [];
  List<NativeVoiceInfo> _indianVoices = [];
  NativeVoiceInfo? _selectedVoice;
  String? _selectedEngine;
  double _speechRate = 0.5; // FlutterTts normal rate is ~0.5
  double _pitch = 1.0;
  String? _currentSpeakingMessageId;

  NativeTtsState get state => _state;
  bool get isPlaying => _state == NativeTtsState.playing;
  List<dynamic> get availableEngines => _availableEngines;
  List<NativeVoiceInfo> get allVoices => _allVoices;
  List<NativeVoiceInfo> get indianVoices => _indianVoices;
  NativeVoiceInfo? get selectedVoice => _selectedVoice;
  String? get selectedEngine => _selectedEngine;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String? get currentSpeakingMessageId => _currentSpeakingMessageId;

  NativeTtsService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts.setStartHandler(() {
        _state = NativeTtsState.playing;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _state = NativeTtsState.stopped;
        _currentSpeakingMessageId = null;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        _state = NativeTtsState.stopped;
        _currentSpeakingMessageId = null;
        notifyListeners();
      });

      _flutterTts.setPauseHandler(() {
        _state = NativeTtsState.paused;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        _state = NativeTtsState.continued;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('FlutterTts Error: $msg');
        _state = NativeTtsState.stopped;
        _currentSpeakingMessageId = null;
        notifyListeners();
      });

      // Fetch engines
      final engines = await _flutterTts.getEngines;
      if (engines is List) {
        _availableEngines = engines;
      }

      // Fetch default engine
      final defaultEngine = await _flutterTts.getDefaultEngine;
      if (defaultEngine != null) {
        _selectedEngine = defaultEngine.toString();
      }

      // Discover voices
      await refreshVoices();
    } catch (e) {
      debugPrint('Error initializing NativeTtsService: $e');
    }
  }

  Future<void> refreshVoices() async {
    try {
      final rawVoices = await _flutterTts.getVoices;
      if (rawVoices is List) {
        _allVoices = rawVoices.map((v) {
          final map = v is Map ? v : {};
          final name = map['name']?.toString() ?? 'Default';
          final locale = map['locale']?.toString() ?? '';
          final quality = int.tryParse(map['quality']?.toString() ?? '300') ?? 300;
          final latency = int.tryParse(map['latency']?.toString() ?? '300') ?? 300;
          final networkRequired = map['network_required'] == true || map['network_required']?.toString() == 'true';

          return NativeVoiceInfo(
            name: name,
            locale: locale,
            quality: quality,
            latency: latency,
            isNetworkRequired: networkRequired,
            raw: Map.from(map),
          );
        }).toList();

        // Filter and Rank Indian voices:
        // Priority 1: en-IN (English India)
        // Priority 2: hi-IN (Hindi India)
        // Priority 3: Quality >= 400, network_required == false
        _indianVoices = _allVoices.where((v) => v.isIndianEnglish || v.isHindi).toList();

        _indianVoices.sort((a, b) {
          // Put en-IN before hi-IN (Sweet spot for finance + Hinglish terms)
          if (a.isIndianEnglish && !b.isIndianEnglish) return -1;
          if (!a.isIndianEnglish && b.isIndianEnglish) return 1;
          // Prefer higher quality
          if (a.quality != b.quality) return b.quality.compareTo(a.quality);
          // Prefer offline (network_required == false)
          if (!a.isNetworkRequired && b.isNetworkRequired) return -1;
          if (a.isNetworkRequired && !b.isNetworkRequired) return 1;
          return 0;
        });

        // Set default selected voice (en-IN first if available)
        if (_indianVoices.isNotEmpty) {
          _selectedVoice = _indianVoices.first;
          await setVoice(_selectedVoice!);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching voices: $e');
    }
  }

  Future<void> setEngine(String engineName) async {
    try {
      await _flutterTts.setEngine(engineName);
      _selectedEngine = engineName;
      await refreshVoices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting engine: $e');
    }
  }

  Future<void> setVoice(NativeVoiceInfo voice) async {
    try {
      _selectedVoice = voice;
      if (voice.raw.isNotEmpty) {
        await _flutterTts.setVoice(Map<String, String>.from(
          voice.raw.map((key, value) => MapEntry(key.toString(), value.toString())),
        ));
      }
      if (voice.locale.isNotEmpty) {
        await _flutterTts.setLanguage(voice.locale);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
    notifyListeners();
  }

  Future<void> speak({
    required String text,
    String? messageId,
  }) async {
    if (text.trim().isEmpty) return;

    if (_state == NativeTtsState.playing && _currentSpeakingMessageId == messageId) {
      await stop();
      return;
    }

    await stop();
    _currentSpeakingMessageId = messageId;
    _state = NativeTtsState.playing;
    notifyListeners();

    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _state = NativeTtsState.paused;
    notifyListeners();
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _state = NativeTtsState.stopped;
    _currentSpeakingMessageId = null;
    notifyListeners();
  }
}
