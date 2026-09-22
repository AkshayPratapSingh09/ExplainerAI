class TtsNormalizer {
  /// Financial, investment, and business acronyms dictionary with natural speech expansions.
  static final Map<String, String> acronymExpansions = {
    'YTM': 'yield to maturity',
    'CAGR': 'C A G R',
    'ETF': 'E T F',
    'ETFs': 'E T Fs',
    'NAV': 'N A V',
    'P/E': 'P by E ratio',
    'EPS': 'E P S',
    'BPS': 'basis points',
    'bps': 'basis points',
    'AAA': 'triple A',
    'AA+': 'double A plus',
    'AA': 'double A',
    'A+': 'A plus',
    'IPO': 'I P O',
    'FD': 'fixed deposit',
    'FDs': 'fixed deposits',
    'SIP': 'S I P',
    'SIPs': 'S I Ps',
    'GST': 'G S T',
    'TDS': 'T D S',
    'ITR': 'I T R',
    'FY': 'financial year',
    'Q1': 'quarter one',
    'Q2': 'quarter two',
    'Q3': 'quarter three',
    'Q4': 'quarter four',
    'RoE': 'return on equity',
    'ROE': 'return on equity',
    'RoCE': 'return on capital employed',
    'ROCE': 'return on capital employed',
    'AUM': 'A U M',
    'NFO': 'N F O',
    'RBI': 'R B I',
    'SEBI': 'SEBI',
    'UPI': 'U P I',
    'API': 'A P I',
    'APIs': 'A P Is',
    'LLM': 'L L M',
    'LLMs': 'L L Ms',
    'AI': 'A I',
    'TTS': 'T T S',
    'HD': 'H D',
    'vs': 'versus',
    'vs.': 'versus',
    'w/': 'with',
    'w/o': 'without',
    'e.g.': 'for example',
    'i.e.': 'that is',
    'etc.': 'and so on',
    'approx.': 'approximately',
  };

  /// Normalizes raw text specifically for on-device TTS and Google Cloud engines.
  /// Converts currency numbers, percentages, acronyms, and formatting into clean spoken English/Hinglish.
  static String normalizeForNativeTts(String text, {bool isIndianEnglishMode = true}) {
    var s = text;

    // 1. Remove markdown code blocks and inline code
    s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' [code block] ');
    s = s.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // 2. Remove markdown links [title](url) -> title
    s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m.group(1) ?? '');

    // 3. Remove citations like [1], [2], [citation needed]
    s = s.replaceAll(RegExp(r'\[\s*\d+\s*\]'), '');
    s = s.replaceAll(RegExp(r'\[citation[^\]]*\]', caseSensitive: false), '');

    // 4. Remove markdown table dividers |---|---|
    s = s.replaceAll(RegExp(r'\|?\s*[-:]+[-| :]+\|?'), ' ');
    s = s.replaceAll(RegExp(r'\|'), ', ');

    // 5. Expand Indian Currency formatting:
    // e.g. ₹1,00,000 / ₹1,00,00,000 / ₹5,000 / ₹500
    s = _normalizeIndianCurrency(s);

    // 6. Dollar/Euro formatting:
    s = s.replaceAllMapped(RegExp(r'\$\s*(\d+(?:,\d+)*(?:\.\d+)?)'), (m) {
      final numStr = m.group(1)?.replaceAll(',', '') ?? '0';
      return '$numStr dollars';
    });

    // 7. Percentages: e.g. 11.25% -> eleven point two five percent (or 11.25 percent)
    s = s.replaceAllMapped(RegExp(r'(\d+(?:\.\d+)?)\s*%'), (m) {
      final val = m.group(1) ?? '';
      return '$val percent';
    });

    // 8. Expand financial acronyms (whole words only)
    acronymExpansions.forEach((acronym, expansion) {
      // Escape special regex chars like + or /
      final escaped = RegExp.escape(acronym);
      s = s.replaceAllMapped(
        RegExp('(?<=^|\\s|\\(|\\/|\\[)$escaped(?=\\s|\\)|\\/|\\]|[.,!?]|\$)', caseSensitive: true),
        (m) => expansion,
      );
    });

    // 9. Remove markdown formatting bold/italics
    s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1) ?? '');
    s = s.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m.group(1) ?? '');

    // 10. Remove markdown headers (#, ##, ###) and bullets
    s = s.replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*[-*+>]\s+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 11. Remove emojis
    s = s.replaceAll(
      RegExp(r'[\u{1F600}-\u{1F64F}|\u{1F300}-\u{1F5FF}|\u{1F680}-\u{1F6FF}|\u{1F1E0}-\u{1F1FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]', unicode: true),
      '',
    );

    // 12. Cleanup multiple spaces & newlines
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return s.trim();
  }

  /// Converts ₹ amounts into verbal words (lakhs, crores, thousands, rupees)
  static String _normalizeIndianCurrency(String text) {
    return text.replaceAllMapped(RegExp(r'₹\s*(\d+(?:,\d+)*(?:\.\d+)?)'), (m) {
      final raw = m.group(1)?.replaceAll(',', '') ?? '0';
      final doubleVal = double.tryParse(raw);
      if (doubleVal == null) return '$raw rupees';

      if (doubleVal >= 10000000) {
        final cr = (doubleVal / 10000000);
        final crStr = cr == cr.roundToDouble() ? cr.toInt().toString() : cr.toStringAsFixed(2);
        return '$crStr crore rupees';
      } else if (doubleVal >= 100000) {
        final lakh = (doubleVal / 100000);
        final lakhStr = lakh == lakh.roundToDouble() ? lakh.toInt().toString() : lakh.toStringAsFixed(2);
        return '$lakhStr lakh rupees';
      } else if (doubleVal >= 1000) {
        final k = (doubleVal / 1000);
        final kStr = k == k.roundToDouble() ? k.toInt().toString() : k.toStringAsFixed(2);
        return '$kStr thousand rupees';
      } else {
        return '${doubleVal.toInt()} rupees';
      }
    });
  }
}
