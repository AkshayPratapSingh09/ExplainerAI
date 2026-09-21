import 'package:flutter_test/flutter_test.dart';
import 'package:explainer_ai/core/utils/text_sanitizer.dart';
import 'package:explainer_ai/models/chat_message.dart';
import 'package:explainer_ai/models/chat_session.dart';

void main() {
  group('TextSanitizer Tests', () {
    test('Cleans markdown formatting, citations and symbols correctly', () {
      const rawText = '''
# Heading 1
Here is **important** data with a citation [1] and [citation needed].
- ₹500 discount for all users.
- Growth is 25% w/o extra cost.
| Col A | Col B |
|---|---|
| Value 1 | Value 2 |
''';

      final sanitized = TextSanitizer.sanitizeForAudioSpeech(rawText);

      // Verify citations removed
      expect(sanitized.contains('[1]'), isFalse);
      expect(sanitized.contains('[citation needed]'), isFalse);

      // Verify currency & percentage converted
      expect(sanitized.contains('500 rupees'), isTrue);
      expect(sanitized.contains('25 percent'), isTrue);
      expect(sanitized.contains('without'), isTrue);

      // Verify table dividers and bold markers removed
      expect(sanitized.contains('|---|---|'), isFalse);
      expect(sanitized.contains('**important**'), isFalse);
      expect(sanitized.contains('important'), isTrue);
    });

    test('Extracts audio_script tags accurately', () {
      const fullLlmResponse = '''
### Breakdown
Here is the explanation for you to read.

<audio_script>
Namaste dosto! Aaj hum is topic ko aasan bhasha mein samjhenge.
</audio_script>
''';

      final script = TextSanitizer.extractSpokenScript(fullLlmResponse);
      final display = TextSanitizer.cleanDisplayText(fullLlmResponse);

      expect(script, contains('Namaste dosto! Aaj hum is topic ko aasan bhasha mein samjhenge.'));
      expect(display, contains('### Breakdown'));
      expect(display.contains('<audio_script>'), isFalse);
    });

    test('Splits long text into manageable TTS chunks', () {
      final longText = List.generate(20, (i) => 'Yeh sentence number $i hai jo audio explain karega.').join(' ');
      final chunks = TextSanitizer.splitIntoTtsChunks(longText, maxChunkLength: 200);

      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.isNotEmpty, isTrue);
      }
    });
  });

  group('Model Serialization Tests', () {
    test('ChatMessage serializes to/from map properly', () {
      final msg = ChatMessage(
        id: 'msg-123',
        text: 'Sample text',
        spokenScript: 'Sample spoken',
        audioPath: '/path/to/speech.mp3',
        role: MessageRole.assistant,
        mode: ProcessingMode.explain,
        modelUsed: 'sarvam-105b-conversations',
        speakerUsed: 'shubh',
        paceUsed: 1.25,
      );

      final map = msg.toMap();
      final revived = ChatMessage.fromMap(map);

      expect(revived.id, equals('msg-123'));
      expect(revived.text, equals('Sample text'));
      expect(revived.spokenScript, equals('Sample spoken'));
      expect(revived.audioPath, equals('/path/to/speech.mp3'));
      expect(revived.role, equals(MessageRole.assistant));
      expect(revived.mode, equals(ProcessingMode.explain));
      expect(revived.speakerUsed, equals('shubh'));
      expect(revived.paceUsed, equals(1.25));
    });

    test('ChatSession serializes messages list properly', () {
      final session = ChatSession(
        id: 'sess-1',
        title: 'Explaining Pricing Table',
        messages: [
          ChatMessage(id: '1', text: 'Hello', role: MessageRole.user),
          ChatMessage(id: '2', text: 'Namaste', role: MessageRole.assistant),
        ],
      );

      final jsonStr = session.toJson();
      final revived = ChatSession.fromJson(jsonStr);

      expect(revived.id, equals('sess-1'));
      expect(revived.title, equals('Explaining Pricing Table'));
      expect(revived.messages.length, equals(2));
      expect(revived.messages.first.text, equals('Hello'));
      expect(revived.messages.last.text, equals('Namaste'));
    });
  });
}
