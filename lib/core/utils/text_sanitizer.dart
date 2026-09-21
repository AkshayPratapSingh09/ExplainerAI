class TextSanitizer {
  /// Builds a high-quality prompt for Sarvam LLM to convert raw text (tables, notes, docs)
  /// into an engaging, clear conversational Hinglish explanation and spoken script.
  static String buildExplainerSystemPrompt({
    String style = 'conversational',
    String? customPrompt,
  }) {
    if (customPrompt != null && customPrompt.trim().isNotEmpty) {
      return customPrompt;
    }

    return '''
You are "Explainer AI" - an intelligent, engaging Indian audio explainer and tutor powered by Sarvam AI.
Your goal is to take any raw input provided by the user (which may contain dense tables, bullet points, citations, financial figures with ₹/\\\$, percentages, technical jargon, or complex articles) and transform it into a crystal-clear, conversational Hinglish (Hindi + English) explanation.

Crucial Spoken-Audio Guidelines:
1. TABLES: If the text contains markdown or raw tables, DO NOT read them row-by-row or column-by-column. Instead, summarize comparisons into smooth, natural spoken sentences (e.g., "Agar hum Plan A aur Plan B ko compare karein, toh Plan A mein...").
2. SYMBOLS & NUMBERS:
   - Convert "₹5,000" into "paanch hazaar rupaye" or "5000 rupees".
   - Convert "75%" into "75 percent" or "pachattar percent".
   - Convert "24/7" into "chobis ghante, saat din".
   - Convert "e.g." / "i.e." into "jaise ki" or "matlab".
3. CITATIONS & PARENTHESES: Completely skip bracketed references like [1], [2], [citation needed] and avoid unnatural parenthetical tangents that sound awkward when spoken.
4. BULLET POINTS & FORMATTING: Turn sterile bullet lists into conversational flowing narratives with natural connectives like "Pehli baat...", "Doosra fayda yeh hai...", "Aur aakhir mein...".
5. LANGUAGE & TONE: Use friendly, expressive, and natural modern Hinglish (the way smart Indian tech leaders, teachers, and podcasters talk). Keep sentences punchy and easy to follow by ear.

Output Format:
1. First, provide a beautifully formatted Markdown breakdown with clear headings and bullet points for the user to read on screen.
2. At the very end, include the exact natural conversational narration inside `<audio_script> ... </audio_script>` tags. This narration will be fed directly into Sarvam TTS. Make it feel alive, warm, and natural!
''';
  }

  /// Builds a system prompt for direct conversational chat mode
  static String buildChatSystemPrompt() {
    return '''
You are Explainer AI, an intelligent, helpful conversational assistant.
Answer the user's questions in a clear, friendly, and natural Hinglish tone.
Keep your explanations insightful and structured. At the end of your response, provide the conversational spoken version inside `<audio_script> ... </audio_script>` tags if speech generation is requested.
''';
  }

  /// Extracts the spoken script portion from the LLM response if present,
  /// or falls back to sanitizing the full text.
  static String extractSpokenScript(String fullResponse) {
    final match = RegExp(r'<audio_script>([\s\S]*?)<\/audio_script>', caseSensitive: false)
        .firstMatch(fullResponse);
    if (match != null && match.group(1) != null) {
      return sanitizeForAudioSpeech(match.group(1)!.trim());
    }

    // If no audio_script tags were produced, clean the full response text
    return sanitizeForAudioSpeech(fullResponse);
  }

  /// Removes the `<audio_script>` tags from the display text so the chat UI displays clean markdown
  static String cleanDisplayText(String fullResponse) {
    return fullResponse
        .replaceAll(RegExp(r'<audio_script>[\s\S]*?<\/audio_script>', caseSensitive: false), '')
        .trim();
  }

  /// Cleans raw text or markdown into smooth, pronounceable text for Sarvam TTS.
  /// Removes markdown formatting, table characters, citations, raw urls, and cleans symbols.
  static String sanitizeForAudioSpeech(String text) {
    var s = text;

    // Remove code blocks
    s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' [Code snippet] ');
    s = s.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove markdown links [text](url) -> text
    s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '');

    // Remove citation brackets like [1], [12], [citation needed]
    s = s.replaceAll(RegExp(r'\[\s*\d+\s*\]'), '');
    s = s.replaceAll(RegExp(r'\[citation[^\]]*\]', caseSensitive: false), '');

    // Remove markdown table divider rows like |---|---|
    s = s.replaceAll(RegExp(r'\|?\s*[-:]+[-| :]+\|?'), ' ');

    // Replace table pipe delimiters with pauses/commas
    s = s.replaceAll(RegExp(r'\|'), ', ');

    // Convert currency symbols
    s = s.replaceAllMapped(RegExp(r'₹\s*(\d+)'), (m) => '${m.group(1)} rupees');
    s = s.replaceAllMapped(RegExp(r'\$\s*(\d+)'), (m) => '${m.group(1)} dollars');

    // Convert percentage
    s = s.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)\s*%'), (m) => '${m.group(1)} percent');

    // Convert common shorthand
    s = s.replaceAll(RegExp(r'\bw/o\b|w/o', caseSensitive: false), 'without');
    s = s.replaceAll(RegExp(r'(?:^|\s)w/(?:\s|$)', caseSensitive: false, multiLine: true), ' with ');
    s = s.replaceAll(RegExp(r'e\.g\.', caseSensitive: false), 'for example');
    s = s.replaceAll(RegExp(r'i\.e\.', caseSensitive: false), 'that is');
    s = s.replaceAll(RegExp(r'\bvs\.?\b|vs\.', caseSensitive: false), 'versus');
    s = s.replaceAll(RegExp(r'\betc\.?\b|etc\.', caseSensitive: false), 'and so on');
    s = s.replaceAll(RegExp(r'\bapprox\.?\b|approx\.', caseSensitive: false), 'approximately');

    // Remove markdown headers (#, ##, ###)
    s = s.replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '');

    // Remove markdown bold / italics (**word**, *word*, __word__, _word_)
    s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');

    // Remove markdown bullet points (- , * , + , > )
    s = s.replaceAll(RegExp(r'^\s*[-*+>]\s+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // Remove emojis that may cause TTS stutters
    s = s.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{1F1E0}-\u{1F1FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]', unicode: true), '');

    // Replace multiple spaces and newlines with clean single spaces
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return s.trim();
  }

  /// Splits long text into manageable chunks (under maxChunkLength chars) at punctuation boundaries
  /// for optimal TTS synthesis and streaming.
  static List<String> splitIntoTtsChunks(String text, {int maxChunkLength = 450}) {
    final clean = text.trim();
    if (clean.length <= maxChunkLength) {
      return [clean];
    }

    final List<String> chunks = [];
    final sentences = clean.split(RegExp(r'(?<=[.?!।\n])\s+'));
    var currentChunk = StringBuffer();

    for (final sentence in sentences) {
      if (currentChunk.length + sentence.length + 1 <= maxChunkLength) {
        if (currentChunk.isNotEmpty) currentChunk.write(' ');
        currentChunk.write(sentence);
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString());
          currentChunk = StringBuffer();
        }

        // If a single sentence exceeds maxChunkLength, split by commas or words
        if (sentence.length > maxChunkLength) {
          final words = sentence.split(' ');
          for (final word in words) {
            if (currentChunk.length + word.length + 1 <= maxChunkLength) {
              if (currentChunk.isNotEmpty) currentChunk.write(' ');
              currentChunk.write(word);
            } else {
              if (currentChunk.isNotEmpty) {
                chunks.add(currentChunk.toString());
                currentChunk = StringBuffer();
              }
              currentChunk.write(word);
            }
          }
        } else {
          currentChunk.write(sentence);
        }
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }

    return chunks.where((c) => c.trim().isNotEmpty).toList();
  }
}
