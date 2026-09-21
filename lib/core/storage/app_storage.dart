import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';
import '../../models/chat_session.dart';

class AppStorage {
  static const String _keySettings = 'explainer_settings';
  static const String _keySessions = 'explainer_chat_sessions';
  static const String _keyActiveSessionId = 'explainer_active_session_id';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  static Future<AppStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  // --- Settings Persistence ---
  AppSettings loadSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw == null || raw.isEmpty) {
      return AppSettings();
    }
    try {
      return AppSettings.fromJson(raw);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_keySettings, settings.toJson());
  }

  // --- Chat Sessions Persistence ---
  List<ChatSession> loadSessions() {
    final raw = _prefs.getString(_keySessions);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => ChatSession.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
      return [];
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final encoded = jsonEncode(sessions.map((s) => s.toMap()).toList());
    await _prefs.setString(_keySessions, encoded);
  }

  String? loadActiveSessionId() {
    return _prefs.getString(_keyActiveSessionId);
  }

  Future<void> saveActiveSessionId(String? id) async {
    if (id == null) {
      await _prefs.remove(_keyActiveSessionId);
    } else {
      await _prefs.setString(_keyActiveSessionId, id);
    }
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  /// Cleans up cached audio files that are no longer referenced in chat sessions
  Future<void> cleanOrphanedAudioFiles(List<ChatSession> activeSessions) async {
    try {
      final Set<String> activePaths = {};
      for (final session in activeSessions) {
        for (final msg in session.messages) {
          if (msg.audioPath != null) {
            activePaths.add(msg.audioPath!);
          }
        }
      }

      // Check audio cache directory
      final samplePath = activePaths.firstOrNull;
      if (samplePath != null) {
        final dir = File(samplePath).parent;
        if (await dir.exists()) {
          final files = dir.listSync();
          for (final f in files) {
            if (f is File && !activePaths.contains(f.path)) {
              await f.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning audio cache: $e');
    }
  }
}
