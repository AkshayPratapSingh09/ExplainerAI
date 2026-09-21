import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/api/sarvam_client.dart';
import '../core/storage/app_storage.dart';
import '../core/utils/text_sanitizer.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatProvider extends ChangeNotifier {
  final AppStorage _storage;
  final SarvamClient _client;

  List<ChatSession> _sessions = [];
  ChatSession? _activeSession;
  bool _isGenerating = false;

  // Active Input State Controls (can be adjusted per prompt directly from the floating dock)
  ProcessingMode _currentMode = ProcessingMode.explain;
  String _selectedChatModel = 'sarvam-105b-conversations';
  String _selectedTtsModel = 'bulbul:v3';
  String _selectedSpeaker = 'shubh';
  String _selectedLanguageCode = 'hi-IN';
  double _selectedPace = 1.0;
  bool _audioEnabled = true;

  ChatProvider({
    required this._storage,
    SarvamClient? client,
  })  : _client = client ?? SarvamClient() {
    _init();
  }

  List<ChatSession> get sessions => _sessions;
  ChatSession? get activeSession => _activeSession;
  List<ChatMessage> get messages => _activeSession?.messages ?? [];
  bool get isGenerating => _isGenerating;

  ProcessingMode get currentMode => _currentMode;
  String get selectedChatModel => _selectedChatModel;
  String get selectedTtsModel => _selectedTtsModel;
  String get selectedSpeaker => _selectedSpeaker;
  String get selectedLanguageCode => _selectedLanguageCode;
  double get selectedPace => _selectedPace;
  bool get audioEnabled => _audioEnabled;

  void syncDefaultsWithSettings(AppSettings settings) {
    _selectedChatModel = settings.defaultChatModel;
    _selectedTtsModel = settings.defaultTtsModel;
    _selectedSpeaker = settings.defaultSpeaker;
    _selectedLanguageCode = settings.defaultLanguageCode;
    _selectedPace = settings.defaultPace;
    _audioEnabled = settings.isAudioAutoGenerate;
    notifyListeners();
  }

  void _init() {
    _sessions = _storage.loadSessions();
    final activeId = _storage.loadActiveSessionId();

    if (_sessions.isNotEmpty) {
      _activeSession = _sessions.firstWhere(
        (s) => s.id == activeId,
        orElse: () => _sessions.first,
      );
    } else {
      createNewSession();
    }
  }

  void setMode(ProcessingMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void setSpeaker(String speaker) {
    _selectedSpeaker = speaker;
    notifyListeners();
  }

  void setPace(double pace) {
    _selectedPace = pace;
    notifyListeners();
  }

  void setAudioEnabled(bool enabled) {
    _audioEnabled = enabled;
    notifyListeners();
  }

  void setChatModel(String model) {
    _selectedChatModel = model;
    notifyListeners();
  }

  void setTtsModel(String model) {
    _selectedTtsModel = model;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _selectedLanguageCode = code;
    notifyListeners();
  }

  void createNewSession({String? title}) {
    final newSession = ChatSession(
      id: const Uuid().v4(),
      title: title ?? 'New Explanation',
      messages: [],
    );

    _sessions.insert(0, newSession);
    _activeSession = newSession;
    _storage.saveActiveSessionId(newSession.id);
    _storage.saveSessions(_sessions);
    notifyListeners();
  }

  void selectSession(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _activeSession = _sessions[index];
      _storage.saveActiveSessionId(sessionId);
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_activeSession?.id == sessionId) {
      _activeSession = _sessions.isNotEmpty ? _sessions.first : null;
      if (_activeSession == null) {
        createNewSession();
      }
      await _storage.saveActiveSessionId(_activeSession?.id);
    }
    await _storage.saveSessions(_sessions);
    await _storage.cleanOrphanedAudioFiles(_sessions);
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index].title = newTitle;
      _sessions[index].updatedAt = DateTime.now();
      await _storage.saveSessions(_sessions);
      notifyListeners();
    }
  }

  Future<void> clearActiveSessionMessages() async {
    if (_activeSession == null) return;
    _activeSession!.messages.clear();
    _activeSession!.updatedAt = DateTime.now();
    await _storage.saveSessions(_sessions);
    await _storage.cleanOrphanedAudioFiles(_sessions);
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    if (_activeSession == null) return;
    _activeSession!.messages.removeWhere((m) => m.id == messageId);
    _activeSession!.updatedAt = DateTime.now();
    await _storage.saveSessions(_sessions);
    await _storage.cleanOrphanedAudioFiles(_sessions);
    notifyListeners();
  }

  /// Sends a prompt/text to be processed and spoken
  Future<void> sendMessage({
    required String text,
    required String apiKey,
    String? customSystemPrompt,
  }) async {
    final prompt = text.trim();
    if (prompt.isEmpty) return;

    if (_activeSession == null) {
      createNewSession();
    }

    final currentSession = _activeSession!;

    // Auto-title session based on first message
    if (currentSession.messages.isEmpty && currentSession.title == 'New Explanation') {
      final summary = prompt.length > 35 ? '${prompt.substring(0, 32)}...' : prompt;
      currentSession.title = summary.replaceAll('\n', ' ');
    }

    // 1. Add User Message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: prompt,
      role: MessageRole.user,
      mode: _currentMode,
    );
    currentSession.messages.add(userMessage);

    // 2. Add Assistant Message Placeholder
    final assistantMessageId = const Uuid().v4();
    final assistantMessage = ChatMessage(
      id: assistantMessageId,
      text: '',
      role: MessageRole.assistant,
      mode: _currentMode,
      modelUsed: _selectedChatModel,
      speakerUsed: _selectedSpeaker,
      paceUsed: _selectedPace,
      isTextLoading: true,
      isAudioLoading: _audioEnabled,
    );
    currentSession.messages.add(assistantMessage);

    _isGenerating = true;
    notifyListeners();
    await _storage.saveSessions(_sessions);

    try {
      if (_currentMode == ProcessingMode.ttsOnly) {
        // Direct TTS Mode: No LLM call needed, synthesize audio directly
        final spokenText = TextSanitizer.sanitizeForAudioSpeech(prompt);
        _updateAssistantMessage(
          assistantMessageId,
          (msg) => msg.copyWith(
            text: '🔊 Audio explanation synthesized from input text.',
            spokenScript: spokenText,
            isTextLoading: false,
          ),
        );

        if (_audioEnabled) {
          final audioPath = await _client.convertTextToSpeech(
            apiKey: apiKey,
            text: spokenText,
            targetLanguageCode: _selectedLanguageCode,
            speaker: _selectedSpeaker,
            model: _selectedTtsModel,
            pace: _selectedPace,
          );

          _updateAssistantMessage(
            assistantMessageId,
            (msg) => msg.copyWith(
              audioPath: audioPath,
              isAudioLoading: false,
            ),
          );
        } else {
          _updateAssistantMessage(
            assistantMessageId,
            (msg) => msg.copyWith(isAudioLoading: false),
          );
        }
      } else {
        // Conversational Explainer or Direct Chat Mode
        final systemPrompt = _currentMode == ProcessingMode.explain
            ? TextSanitizer.buildExplainerSystemPrompt(customPrompt: customSystemPrompt)
            : TextSanitizer.buildChatSystemPrompt();

        // Build conversation history for LLM
        final List<Map<String, String>> history = [
          {'role': 'system', 'content': systemPrompt},
        ];

        // Include past 4 turns for context
        final recentMessages = currentSession.messages
            .where((m) => m.id != assistantMessageId && m.text.isNotEmpty)
            .toList();
        final contextWindow = recentMessages.length > 8
            ? recentMessages.sublist(recentMessages.length - 8)
            : recentMessages;

        for (final m in contextWindow) {
          history.add({
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          });
        }

        // Call Sarvam AI Chat completions
        final rawResponse = await _client.generateHinglishExplanation(
          apiKey: apiKey,
          messages: history,
          model: _selectedChatModel,
        );

        final displayText = TextSanitizer.cleanDisplayText(rawResponse);
        final spokenScript = TextSanitizer.extractSpokenScript(rawResponse);

        _updateAssistantMessage(
          assistantMessageId,
          (msg) => msg.copyWith(
            text: displayText.isNotEmpty ? displayText : rawResponse,
            spokenScript: spokenScript,
            isTextLoading: false,
          ),
        );

        // Call Sarvam TTS if audio is enabled
        if (_audioEnabled) {
          try {
            final audioPath = await _client.convertTextToSpeech(
              apiKey: apiKey,
              text: spokenScript.isNotEmpty ? spokenScript : displayText,
              targetLanguageCode: _selectedLanguageCode,
              speaker: _selectedSpeaker,
              model: _selectedTtsModel,
              pace: _selectedPace,
            );

            _updateAssistantMessage(
              assistantMessageId,
              (msg) => msg.copyWith(
                audioPath: audioPath,
                isAudioLoading: false,
              ),
            );
          } catch (audioError) {
            _updateAssistantMessage(
              assistantMessageId,
              (msg) => msg.copyWith(
                isAudioLoading: false,
                errorMessage: 'Text generated, but audio failed: $audioError',
              ),
            );
          }
        } else {
          _updateAssistantMessage(
            assistantMessageId,
            (msg) => msg.copyWith(isAudioLoading: false),
          );
        }
      }
    } catch (e) {
      _updateAssistantMessage(
        assistantMessageId,
        (msg) => msg.copyWith(
          isTextLoading: false,
          isAudioLoading: false,
          errorMessage: e.toString(),
        ),
      );
    } finally {
      _isGenerating = false;
      currentSession.updatedAt = DateTime.now();
      await _storage.saveSessions(_sessions);
      notifyListeners();
    }
  }

  /// Regenerates audio for a given message with new speaker/pace
  Future<void> regenerateAudioForMessage({
    required String messageId,
    required String apiKey,
    String? speaker,
    double? pace,
  }) async {
    if (_activeSession == null) return;
    final index = _activeSession!.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final msg = _activeSession!.messages[index];
    final textToSpeak = (msg.spokenScript != null && msg.spokenScript!.isNotEmpty)
        ? msg.spokenScript!
        : msg.text;

    final targetSpeaker = speaker ?? _selectedSpeaker;
    final targetPace = pace ?? _selectedPace;

    _updateAssistantMessage(
      messageId,
      (m) => m.copyWith(
        isAudioLoading: true,
        speakerUsed: targetSpeaker,
        paceUsed: targetPace,
      ),
    );

    try {
      final audioPath = await _client.convertTextToSpeech(
        apiKey: apiKey,
        text: textToSpeak,
        targetLanguageCode: _selectedLanguageCode,
        speaker: targetSpeaker,
        model: _selectedTtsModel,
        pace: targetPace,
      );

      _updateAssistantMessage(
        messageId,
        (m) => m.copyWith(
          audioPath: audioPath,
          isAudioLoading: false,
        ),
      );
    } catch (e) {
      _updateAssistantMessage(
        messageId,
        (m) => m.copyWith(
          isAudioLoading: false,
          errorMessage: 'Audio generation failed: $e',
        ),
      );
    } finally {
      await _storage.saveSessions(_sessions);
      notifyListeners();
    }
  }

  void _updateAssistantMessage(
    String id,
    ChatMessage Function(ChatMessage) update,
  ) {
    if (_activeSession == null) return;
    final index = _activeSession!.messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _activeSession!.messages[index] = update(_activeSession!.messages[index]);
      notifyListeners();
    }
  }
}
