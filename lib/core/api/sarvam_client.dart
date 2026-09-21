import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../utils/text_sanitizer.dart';

class SarvamApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  SarvamApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'SarvamApiException: $message (Status: $statusCode)';
}

class SarvamClient {
  static const String baseUrl = 'https://api.sarvam.ai';
  static const String chatCompletionsUrl = '$baseUrl/v1/chat/completions';
  static const String ttsStreamUrl = '$baseUrl/text-to-speech/stream';
  static const String ttsStandardUrl = '$baseUrl/text-to-speech';

  final http.Client _httpClient;

  SarvamClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Validates if an API Key is working by making a lightweight test call
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final response = await _httpClient.post(
        Uri.parse(chatCompletionsUrl),
        headers: {
          'api-subscription-key': apiKey.trim(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
          'model': 'sarvam-105b-conversations',
          'max_tokens': 5,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 400;
    } catch (_) {
      return false;
    }
  }

  /// Sends a chat completion request to Sarvam AI (sarvam-105b-conversations)
  Future<String> generateHinglishExplanation({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = 'sarvam-105b-conversations',
    double temperature = 0.7,
    int maxTokens = 1500,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw SarvamApiException('Sarvam API Key is not set. Please add it in Settings.');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(chatCompletionsUrl),
        headers: {
          'api-subscription-key': apiKey.trim(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'top_p': 1.0,
          'max_tokens': maxTokens,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
        throw SarvamApiException('Empty response received from Sarvam Chat API');
      } else {
        String errorMsg = 'Sarvam API Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error']['message'] ?? errorData['error'].toString();
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }
        throw SarvamApiException(errorMsg, statusCode: response.statusCode);
      }
    } on SocketException {
      throw SarvamApiException('Network error. Please check your internet connection.');
    } catch (e) {
      if (e is SarvamApiException) rethrow;
      throw SarvamApiException('Failed to connect to Sarvam AI: $e');
    }
  }

  /// Converts spoken script or text into an MP3 file using Sarvam Bulbul TTS models.
  /// Handles chunking for longer scripts and saves locally.
  Future<String> convertTextToSpeech({
    required String apiKey,
    required String text,
    String targetLanguageCode = 'hi-IN',
    String speaker = 'shubh',
    String model = 'bulbul:v3',
    double pace = 1.0,
    int speechSampleRate = 22050,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw SarvamApiException('Sarvam API Key is required for audio generation.');
    }

    final cleanText = TextSanitizer.sanitizeForAudioSpeech(text);
    if (cleanText.isEmpty) {
      throw SarvamApiException('No valid text to convert to speech.');
    }

    // Split text into chunks if it's long (e.g. > 450 chars)
    final chunks = TextSanitizer.splitIntoTtsChunks(cleanText, maxChunkLength: 450);
    final List<Uint8List> audioByteSegments = [];

    for (final chunk in chunks) {
      final bytes = await _synthesizeSingleChunk(
        apiKey: apiKey,
        text: chunk,
        targetLanguageCode: targetLanguageCode,
        speaker: speaker,
        model: model,
        pace: pace,
        speechSampleRate: speechSampleRate,
      );
      if (bytes.isNotEmpty) {
        audioByteSegments.add(bytes);
      }
    }

    if (audioByteSegments.isEmpty) {
      throw SarvamApiException('Audio synthesis produced no sound.');
    }

    // Combine all audio bytes into a single MP3 file
    final totalBytes = audioByteSegments.fold<int>(0, (sum, list) => sum + list.length);
    final combinedBytes = Uint8List(totalBytes);
    int offset = 0;
    for (final segment in audioByteSegments) {
      combinedBytes.setRange(offset, offset + segment.length, segment);
      offset += segment.length;
    }

    // Save to local app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/audio_cache');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final fileName = 'speech_${const Uuid().v4().substring(0, 8)}.mp3';
    final filePath = '${audioDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(combinedBytes);

    return filePath;
  }

  /// Synthesizes a single chunk via streaming or standard REST endpoint
  Future<Uint8List> _synthesizeSingleChunk({
    required String apiKey,
    required String text,
    required String targetLanguageCode,
    required String speaker,
    required String model,
    required double pace,
    required int speechSampleRate,
  }) async {
    final payload = {
      'text': text,
      'target_language_code': targetLanguageCode,
      'speaker': speaker,
      'model': model,
      'pace': pace,
      'speech_sample_rate': speechSampleRate,
    };

    // Strategy 1: Try stream endpoint
    try {
      final response = await _httpClient.post(
        Uri.parse(ttsStreamUrl),
        headers: {
          'api-subscription-key': apiKey.trim(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Check if response is actually json error disguised as 200
        if (response.headers['content-type']?.contains('application/json') == true) {
          try {
            final jsonResp = jsonDecode(utf8.decode(response.bodyBytes));
            if (jsonResp['audios'] != null && (jsonResp['audios'] as List).isNotEmpty) {
              return base64Decode(jsonResp['audios'][0]);
            }
          } catch (_) {}
        }
        return response.bodyBytes;
      }
    } catch (_) {
      // Fallback to standard endpoint
    }

    // Strategy 2: Try standard text-to-speech endpoint with base64 audio response
    final stdResponse = await _httpClient.post(
      Uri.parse(ttsStandardUrl),
      headers: {
        'api-subscription-key': apiKey.trim(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (stdResponse.statusCode == 200) {
      if (stdResponse.headers['content-type']?.contains('audio') == true) {
        return stdResponse.bodyBytes;
      }

      final data = jsonDecode(utf8.decode(stdResponse.bodyBytes));
      if (data['audios'] != null && (data['audios'] as List).isNotEmpty) {
        final base64String = data['audios'][0] as String;
        return base64Decode(base64String);
      }
      throw SarvamApiException('No audio data received in response');
    } else {
      String errorMsg = 'Sarvam TTS Error: ${stdResponse.statusCode}';
      try {
        final errorData = jsonDecode(stdResponse.body);
        errorMsg = errorData['error']?['message'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {}
      throw SarvamApiException(errorMsg, statusCode: stdResponse.statusCode);
    }
  }
}
