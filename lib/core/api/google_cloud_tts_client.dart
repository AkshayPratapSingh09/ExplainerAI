import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class GoogleCloudVoice {
  final String name;
  final String languageCode;
  final String ssmlGender;
  final String family; // 'Chirp3-HD', 'Neural2', 'Wavenet', 'Standard'
  final String description;

  const GoogleCloudVoice({
    required this.name,
    required this.languageCode,
    required this.ssmlGender,
    required this.family,
    required this.description,
  });

  String get displayName => '$name ($ssmlGender, $family)';
}

class GoogleCloudTtsClient {
  static const String synthesizeUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  static const List<GoogleCloudVoice> availableVoices = [
    // 1. Chirp3-HD (Newest Generative HD Voices)
    GoogleCloudVoice(
      name: 'hi-IN-Chirp3-HD-Algenib',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Chirp3-HD',
      description: 'Ultra-realistic Hindi Generative HD Male Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Chirp3-HD-Achernar',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Chirp3-HD',
      description: 'Ultra-realistic Hindi Generative HD Female Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Chirp3-HD-Bellatrix',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Chirp3-HD',
      description: 'Expressive Hindi Generative HD Female Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Chirp3-HD-Canopus',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Chirp3-HD',
      description: 'Deep Hindi Generative HD Male Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Chirp3-HD-Algenib',
      languageCode: 'en-IN',
      ssmlGender: 'MALE',
      family: 'Chirp3-HD',
      description: 'Indian English Generative HD Male Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Chirp3-HD-Achernar',
      languageCode: 'en-IN',
      ssmlGender: 'FEMALE',
      family: 'Chirp3-HD',
      description: 'Indian English Generative HD Female Voice',
    ),

    // 2. Neural2 (Google DeepMind Neural Architecture)
    GoogleCloudVoice(
      name: 'hi-IN-Neural2-A',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Neural2',
      description: 'Hindi Neural2 Natural Female Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Neural2-B',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Neural2',
      description: 'Hindi Neural2 Warm Male Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Neural2-C',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Neural2',
      description: 'Hindi Neural2 Articulate Male Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Neural2-D',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Neural2',
      description: 'Hindi Neural2 Clear Female Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Neural2-A',
      languageCode: 'en-IN',
      ssmlGender: 'FEMALE',
      family: 'Neural2',
      description: 'Indian English Neural2 Female Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Neural2-B',
      languageCode: 'en-IN',
      ssmlGender: 'MALE',
      family: 'Neural2',
      description: 'Indian English Neural2 Male Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Neural2-C',
      languageCode: 'en-IN',
      ssmlGender: 'MALE',
      family: 'Neural2',
      description: 'Indian English Neural2 Conversational Male',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Neural2-D',
      languageCode: 'en-IN',
      ssmlGender: 'FEMALE',
      family: 'Neural2',
      description: 'Indian English Neural2 Professional Female',
    ),

    // 3. Wavenet Voices
    GoogleCloudVoice(
      name: 'hi-IN-Wavenet-A',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Wavenet',
      description: 'Hindi Wavenet High-Quality Female',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Wavenet-B',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Wavenet',
      description: 'Hindi Wavenet Deep Male',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Wavenet-C',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Wavenet',
      description: 'Hindi Wavenet Energetic Male',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Wavenet-D',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Wavenet',
      description: 'Hindi Wavenet Crisp Female',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Wavenet-A',
      languageCode: 'en-IN',
      ssmlGender: 'FEMALE',
      family: 'Wavenet',
      description: 'Indian English Wavenet Female',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Wavenet-B',
      languageCode: 'en-IN',
      ssmlGender: 'MALE',
      family: 'Wavenet',
      description: 'Indian English Wavenet Male',
    ),

    // 4. Standard Voices (Lowest Latency & Cost)
    GoogleCloudVoice(
      name: 'hi-IN-Standard-A',
      languageCode: 'hi-IN',
      ssmlGender: 'FEMALE',
      family: 'Standard',
      description: 'Hindi Standard Female Voice',
    ),
    GoogleCloudVoice(
      name: 'hi-IN-Standard-B',
      languageCode: 'hi-IN',
      ssmlGender: 'MALE',
      family: 'Standard',
      description: 'Hindi Standard Male Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Standard-A',
      languageCode: 'en-IN',
      ssmlGender: 'FEMALE',
      family: 'Standard',
      description: 'Indian English Standard Female Voice',
    ),
    GoogleCloudVoice(
      name: 'en-IN-Standard-B',
      languageCode: 'en-IN',
      ssmlGender: 'MALE',
      family: 'Standard',
      description: 'Indian English Standard Male Voice',
    ),
  ];

  final http.Client _httpClient;

  GoogleCloudTtsClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Validates the Google Cloud API Key with a quick test
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final response = await _httpClient.post(
        Uri.parse('$synthesizeUrl?key=${apiKey.trim()}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': 'hi'},
          'voice': {
            'languageCode': 'en-IN',
            'name': 'en-IN-Standard-A',
            'ssmlGender': 'FEMALE',
          },
          'audioConfig': {'audioEncoding': 'MP3'},
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Synthesizes text using Google Cloud Text-to-Speech REST API and returns local MP3 file path
  Future<String> synthesizeSpeech({
    required String apiKey,
    required String text,
    String voiceName = 'hi-IN-Chirp3-HD-Algenib',
    String languageCode = 'hi-IN',
    String ssmlGender = 'MALE',
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Google Cloud API Key is required.');
    }

    final payload = {
      'input': {'text': text},
      'voice': {
        'languageCode': languageCode,
        'name': voiceName,
        'ssmlGender': ssmlGender,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': speakingRate.clamp(0.25, 4.0),
        'pitch': pitch.clamp(-20.0, 20.0),
      },
    };

    final response = await _httpClient.post(
      Uri.parse('$synthesizeUrl?key=${apiKey.trim()}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final audioContent = data['audioContent'] as String?;
      if (audioContent == null || audioContent.isEmpty) {
        throw Exception('No audioContent returned from Google Cloud TTS');
      }

      final bytes = base64Decode(audioContent);

      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/gcloud_audio_cache');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = 'gcloud_${const Uuid().v4().substring(0, 8)}.mp3';
      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } else {
      String errMsg = 'Google Cloud TTS Error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          errMsg = errJson['error']['message'];
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }
}
