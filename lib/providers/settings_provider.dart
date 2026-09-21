import 'package:flutter/material.dart';
import '../core/api/sarvam_client.dart';
import '../core/storage/app_storage.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final AppStorage _storage;
  final SarvamClient _client;
  late AppSettings _settings;
  bool _isValidatingKey = false;
  bool? _isKeyValid;

  SettingsProvider({
    required this._storage,
    SarvamClient? client,
  })  : _client = client ?? SarvamClient() {
    _settings = _storage.loadSettings();
  }

  AppSettings get settings => _settings;
  String get apiKey => _settings.apiKey;
  String get defaultChatModel => _settings.defaultChatModel;
  String get defaultTtsModel => _settings.defaultTtsModel;
  String get defaultSpeaker => _settings.defaultSpeaker;
  String get defaultLanguageCode => _settings.defaultLanguageCode;
  double get defaultPace => _settings.defaultPace;
  bool get isAudioAutoGenerate => _settings.isAudioAutoGenerate;
  String get explanationStyle => _settings.explanationStyle;
  ThemeMode get themeMode => _settings.themeMode;
  bool get backgroundAudioEnabled => _settings.backgroundAudioEnabled;
  String get customSystemPrompt => _settings.customSystemPrompt;
  bool get isValidatingKey => _isValidatingKey;
  bool? get isKeyValid => _isKeyValid;
  bool get hasApiKey => _settings.apiKey.trim().isNotEmpty;

  Future<void> updateApiKey(String key) async {
    _settings.apiKey = key.trim();
    _isKeyValid = null;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<bool> testApiKey([String? keyToTest]) async {
    final key = keyToTest ?? _settings.apiKey;
    if (key.trim().isEmpty) {
      _isKeyValid = false;
      notifyListeners();
      return false;
    }

    _isValidatingKey = true;
    notifyListeners();

    try {
      final valid = await _client.validateApiKey(key);
      _isKeyValid = valid;
      _isValidatingKey = false;
      notifyListeners();
      return valid;
    } catch (_) {
      _isKeyValid = false;
      _isValidatingKey = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateChatModel(String model) async {
    _settings.defaultChatModel = model;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateTtsModel(String model) async {
    _settings.defaultTtsModel = model;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateSpeaker(String speakerId) async {
    _settings.defaultSpeaker = speakerId;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateLanguageCode(String code) async {
    _settings.defaultLanguageCode = code;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updatePace(double pace) async {
    _settings.defaultPace = pace;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateAudioAutoGenerate(bool enable) async {
    _settings.isAudioAutoGenerate = enable;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateExplanationStyle(String style) async {
    _settings.explanationStyle = style;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings.themeMode = mode;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateBackgroundAudio(bool enable) async {
    _settings.backgroundAudioEnabled = enable;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateCustomSystemPrompt(String prompt) async {
    _settings.customSystemPrompt = prompt;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> resetToDefaults() async {
    _settings = AppSettings(apiKey: _settings.apiKey);
    notifyListeners();
    await _storage.saveSettings(_settings);
  }
}
