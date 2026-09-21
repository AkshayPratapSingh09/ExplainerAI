import 'dart:convert';

enum MessageRole { user, assistant, system }

enum ProcessingMode { explain, chat, ttsOnly }

class ChatMessage {
  final String id;
  final String text;
  final String? spokenScript; // Cleaned conversational Hinglish script used for TTS
  final String? audioPath; // Local file path to generated MP3
  final Duration? audioDuration;
  final MessageRole role;
  final DateTime createdAt;
  final ProcessingMode mode;
  final String? modelUsed;
  final String? speakerUsed;
  final double paceUsed;
  final bool isAudioLoading;
  final bool isTextLoading;
  final String? errorMessage;
  final String? thoughtProcess;

  ChatMessage({
    required this.id,
    required this.text,
    this.spokenScript,
    this.audioPath,
    this.audioDuration,
    required this.role,
    DateTime? createdAt,
    this.mode = ProcessingMode.explain,
    this.modelUsed,
    this.speakerUsed,
    this.paceUsed = 1.0,
    this.isAudioLoading = false,
    this.isTextLoading = false,
    this.errorMessage,
    this.thoughtProcess,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? text,
    String? spokenScript,
    String? audioPath,
    Duration? audioDuration,
    MessageRole? role,
    DateTime? createdAt,
    ProcessingMode? mode,
    String? modelUsed,
    String? speakerUsed,
    double? paceUsed,
    bool? isAudioLoading,
    bool? isTextLoading,
    String? errorMessage,
    String? thoughtProcess,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      spokenScript: spokenScript ?? this.spokenScript,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      mode: mode ?? this.mode,
      modelUsed: modelUsed ?? this.modelUsed,
      speakerUsed: speakerUsed ?? this.speakerUsed,
      paceUsed: paceUsed ?? this.paceUsed,
      isAudioLoading: isAudioLoading ?? this.isAudioLoading,
      isTextLoading: isTextLoading ?? this.isTextLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      thoughtProcess: thoughtProcess ?? this.thoughtProcess,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'spokenScript': spokenScript,
      'audioPath': audioPath,
      'audioDurationMs': audioDuration?.inMilliseconds,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'mode': mode.name,
      'modelUsed': modelUsed,
      'speakerUsed': speakerUsed,
      'paceUsed': paceUsed,
      'errorMessage': errorMessage,
      'thoughtProcess': thoughtProcess,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      spokenScript: map['spokenScript'],
      audioPath: map['audioPath'],
      audioDuration: map['audioDurationMs'] != null
          ? Duration(milliseconds: map['audioDurationMs'])
          : null,
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.assistant,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      mode: ProcessingMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => ProcessingMode.explain,
      ),
      modelUsed: map['modelUsed'],
      speakerUsed: map['speakerUsed'],
      paceUsed: (map['paceUsed'] as num?)?.toDouble() ?? 1.0,
      errorMessage: map['errorMessage'],
      thoughtProcess: map['thoughtProcess'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source));
}
