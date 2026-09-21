import 'dart:convert';
import 'package:flutter/material.dart';

class SarvamSpeaker {
  final String id;
  final String name;
  final String gender;
  final String description;
  final List<String> supportedLanguages;

  const SarvamSpeaker({
    required this.id,
    required this.name,
    required this.gender,
    required this.description,
    required this.supportedLanguages,
  });
}

class SarvamLanguage {
  final String code;
  final String name;
  final String nativeName;

  const SarvamLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

class AppSettings {
  String apiKey;
  String defaultChatModel;
  String defaultTtsModel;
  String defaultSpeaker;
  String defaultLanguageCode;
  double defaultPace;
  int speechSampleRate;
  bool isAudioAutoGenerate;
  String explanationStyle;
  ThemeMode themeMode;
  bool backgroundAudioEnabled;
  String customSystemPrompt;

  AppSettings({
    this.apiKey = '',
    this.defaultChatModel = 'sarvam-105b-conversations',
    this.defaultTtsModel = 'bulbul:v3',
    this.defaultSpeaker = 'shubh',
    this.defaultLanguageCode = 'hi-IN',
    this.defaultPace = 1.0,
    this.speechSampleRate = 22050,
    this.isAudioAutoGenerate = true,
    this.explanationStyle = 'conversational', // 'conversational', 'simplified', 'storyteller', 'executive'
    this.themeMode = ThemeMode.dark,
    this.backgroundAudioEnabled = true,
    this.customSystemPrompt = '',
  });

  static const List<SarvamSpeaker> availableSpeakers = [
    SarvamSpeaker(
      id: 'shubh',
      name: 'Shubh',
      gender: 'Male',
      description: 'Warm, clear, natural conversational Indian voice',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'rohan',
      name: 'Rohan',
      gender: 'Male',
      description: 'Energetic, modern, relatable tone for explainers',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'priya',
      name: 'Priya',
      gender: 'Female',
      description: 'Crisp, articulate and professional voice',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'pooja',
      name: 'Pooja',
      gender: 'Female',
      description: 'Gentle, friendly, and expressive narration',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'arvind',
      name: 'Arvind',
      gender: 'Male',
      description: 'Deep, authoritative and informative tone',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'amartya',
      name: 'Amartya',
      gender: 'Male',
      description: 'Smooth, polished presentation style',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'shruti',
      name: 'Shruti',
      gender: 'Female',
      description: 'Soft, polite and engaging delivery',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
    SarvamSpeaker(
      id: 'kavya',
      name: 'Kavya',
      gender: 'Female',
      description: 'Bright, lively voice with great pacing',
      supportedLanguages: ['hi-IN', 'en-IN'],
    ),
  ];

  static const List<SarvamLanguage> supportedLanguages = [
    SarvamLanguage(code: 'hi-IN', name: 'Hindi (Hinglish)', nativeName: 'हिन्दी / Hinglish'),
    SarvamLanguage(code: 'en-IN', name: 'Indian English', nativeName: 'English (India)'),
    SarvamLanguage(code: 'bn-IN', name: 'Bengali', nativeName: 'বাংলা'),
    SarvamLanguage(code: 'ta-IN', name: 'Tamil', nativeName: 'தமிழ்'),
    SarvamLanguage(code: 'te-IN', name: 'Telugu', nativeName: 'తెలుగు'),
    SarvamLanguage(code: 'kn-IN', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    SarvamLanguage(code: 'gu-IN', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    SarvamLanguage(code: 'mr-IN', name: 'Marathi', nativeName: 'मराठी'),
    SarvamLanguage(code: 'ml-IN', name: 'Malayalam', nativeName: 'മലയാളം'),
    SarvamLanguage(code: 'pa-IN', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    SarvamLanguage(code: 'od-IN', name: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
  ];

  static const List<String> availableChatModels = [
    'sarvam-105b-conversations',
    'sarvam-2b-conversations',
  ];

  static const List<String> availableTtsModels = [
    'bulbul:v3',
    'bulbul:v2',
  ];

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'defaultChatModel': defaultChatModel,
      'defaultTtsModel': defaultTtsModel,
      'defaultSpeaker': defaultSpeaker,
      'defaultLanguageCode': defaultLanguageCode,
      'defaultPace': defaultPace,
      'speechSampleRate': speechSampleRate,
      'isAudioAutoGenerate': isAudioAutoGenerate,
      'explanationStyle': explanationStyle,
      'themeMode': themeMode.name,
      'backgroundAudioEnabled': backgroundAudioEnabled,
      'customSystemPrompt': customSystemPrompt,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      apiKey: map['apiKey'] ?? '',
      defaultChatModel: map['defaultChatModel'] ?? 'sarvam-105b-conversations',
      defaultTtsModel: map['defaultTtsModel'] ?? 'bulbul:v3',
      defaultSpeaker: map['defaultSpeaker'] ?? 'shubh',
      defaultLanguageCode: map['defaultLanguageCode'] ?? 'hi-IN',
      defaultPace: (map['defaultPace'] as num?)?.toDouble() ?? 1.0,
      speechSampleRate: (map['speechSampleRate'] as num?)?.toInt() ?? 22050,
      isAudioAutoGenerate: map['isAudioAutoGenerate'] ?? true,
      explanationStyle: map['explanationStyle'] ?? 'conversational',
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeMode.dark,
      ),
      backgroundAudioEnabled: map['backgroundAudioEnabled'] ?? true,
      customSystemPrompt: map['customSystemPrompt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source));
}
