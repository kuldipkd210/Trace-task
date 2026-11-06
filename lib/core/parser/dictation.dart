class Dictation {
  static const Map<String, String> numbers = {
    'one': '1',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'eleven': '11',
    'twelve': '12',
  };

  static const Set<String> relativeUnits = {
    'minute',
    'minutes',
    'min',
    'mins',
    'hour',
    'hours',
    'hr',
    'hrs',
    'day',
    'days',
    'week',
    'weeks',
  };

  static final RegExp _trailingPunctuation = RegExp(r'[.,?!;:]+$');

  /// Turns a spoken transcript into the terse form Parser reads.
  /// Converts words like "three pm" to "3pm", "in two hours" to "in 2 hours",
  /// and removes trailing speech punctuation.
  static String normalize(String raw) {
    if (raw.trim().isEmpty) return '';

    final rawTokens = raw.split(RegExp(r'\s+'));
    final words = <String>[];
    for (final token in rawTokens) {
      final cleaned = _clean(token);
      if (cleaned.isNotEmpty) {
        words.add(cleaned);
      }
    }

    for (int i = 0; i < words.length - 1; i++) {
      final digit = numbers[words[i].toLowerCase()];
      if (digit == null) continue;
      final next = words[i + 1].toLowerCase();
      final afterIn = i > 0 && words[i - 1].toLowerCase() == 'in';
      if (next == 'am' || next == 'pm' || (afterIn && relativeUnits.contains(next))) {
        words[i] = digit;
      }
    }

    return words.join(' ');
  }

  static String _clean(String word) {
    var stripped = word.replaceAll(_trailingPunctuation, '');
    final lower = stripped.toLowerCase();
    if (lower.endsWith('p.m')) {
      return '${stripped.substring(0, stripped.length - 3)}pm';
    } else if (lower.endsWith('a.m')) {
      return '${stripped.substring(0, stripped.length - 3)}am';
    }
    return stripped;
  }
}

