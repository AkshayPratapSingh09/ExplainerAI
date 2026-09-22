import 'package:flutter/material.dart';
import '../core/api/google_cloud_tts_client.dart';
import '../core/api/sarvam_client.dart';
import '../core/storage/app_storage.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  final AppStorage _storage;
  final SarvamClient _sarvamClient;
  final GoogleCloudTtsClient _gcloudClient;
  late AppSettings _settings;

  bool _isValidatingKey = false;
  bool? _isKeyValid;
  bool _isValidatingGcloudKey = false;
  bool? _isGcloudKeyValid;

  SettingsProvider({
    required this._storage,
    SarvamClient? sarvamClient,
    GoogleCloudTtsClient? gcloudClient,
  })  : _sarvamClient = sarvamClient ?? SarvamClient(),
        _gcloudClient = gcloudClient ?? GoogleCloudTtsClient() {
    _settings = _storage.loadSettings();
  }

  AppSettings get settings => _settings;
  String get apiKey => _settings.apiKey;
  String get googleCloudApiKey => _settings.googleCloudApiKey;
  TtsTierType get defaultTtsTier => _settings.defaultTtsTier;
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

  String get googleCloudVoiceName => _settings.googleCloudVoiceName;
  double get googleCloudRate => _settings.googleCloudRate;
  double get googleCloudPitch => _settings.googleCloudPitch;

  String get nativeLocale => _settings.nativeLocale;
  double get nativeSpeechRate => _settings.nativeSpeechRate;
  double get nativePitch => _settings.nativePitch;

  bool get isValidatingKey => _isValidatingKey;
  bool? get isKeyValid => _isKeyValid;
  bool get isValidatingGcloudKey => _isValidatingGcloudKey;
  bool? get isGcloudKeyValid => _isGcloudKeyValid;

  bool get hasApiKey => _settings.apiKey.trim().isNotEmpty;
  bool get hasGcloudApiKey => _settings.googleCloudApiKey.trim().isNotEmpty;

  // Sarvam Key
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
      final valid = await _sarvamClient.validateApiKey(key);
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

  // Google Cloud Key
  Future<void> updateGoogleCloudApiKey(String key) async {
    _settings.googleCloudApiKey = key.trim();
    _isGcloudKeyValid = null;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<bool> testGoogleCloudApiKey([String? keyToTest]) async {
    final key = keyToTest ?? _settings.googleCloudApiKey;
    if (key.trim().isEmpty) {
      _isGcloudKeyValid = false;
      notifyListeners();
      return false;
    }

    _isValidatingGcloudKey = true;
    notifyListeners();

    try {
      final valid = await _gcloudClient.validateApiKey(key);
      _isGcloudKeyValid = valid;
      _isValidatingGcloudKey = false;
      notifyListeners();
      return valid;
    } catch (_) {
      _isGcloudKeyValid = false;
      _isValidatingGcloudKey = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateTtsTier(TtsTierType tier) async {
    _settings.defaultTtsTier = tier;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateGoogleCloudVoiceName(String name) async {
    _settings.googleCloudVoiceName = name;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateGoogleCloudRate(double rate) async {
    _settings.googleCloudRate = rate;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateGoogleCloudPitch(double pitch) async {
    _settings.googleCloudPitch = pitch;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateNativeLocale(String locale) async {
    _settings.nativeLocale = locale;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateNativeSpeechRate(double rate) async {
    _settings.nativeSpeechRate = rate;
    notifyListeners();
    await _storage.saveSettings(_settings);
  }

  Future<void> updateNativePitch(double pitch) async {
    _settings.nativePitch = pitch;
    notifyListeners();
    await _storage.saveSettings(_settings);
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
    _settings = AppSettings(
      apiKey: _settings.apiKey,
      googleCloudApiKey: _settings.googleCloudApiKey,
    );
    notifyListeners();
    await _storage.saveSettings(_settings);
  }
}
