/// Utility for parsing country flag emojis from server names.
///
/// Unicode flag emojis are composed of regional indicator symbol pairs
/// (U+1F1E6 to U+1F1FF). For example, 🇬🇧 = U+1F1EC + U+1F1E7.
class FlagUtils {
  // Regional Indicator Symbol Letter A (🇦) to Z (🇿)
  static const int _riStart = 0x1F1E6;
  static const int _riEnd = 0x1F1FF;

  /// Extracts all flag emoji country codes from a string.
  /// Returns a list of lowercase ISO 3166-1 alpha-2 codes.
  ///
  /// Example: "🇬🇧 via 🇷🇺 server" → ["gb", "ru"]
  static List<String> extractFlags(String text) {
    final flags = <String>[];
    final runes = text.runes.toList();

    for (int i = 0; i < runes.length - 1; i++) {
      if (runes[i] >= _riStart &&
          runes[i] <= _riEnd &&
          runes[i + 1] >= _riStart &&
          runes[i + 1] <= _riEnd) {
        final c1 = String.fromCharCode(
            runes[i] - _riStart + 'a'.codeUnitAt(0));
        final c2 = String.fromCharCode(
            runes[i + 1] - _riStart + 'a'.codeUnitAt(0));
        flags.add('$c1$c2');
        i++; // skip the second indicator (already consumed)
      }
    }
    return flags;
  }

  /// Returns the primary flag code for the [CircleFlag] widget.
  ///
  /// Priority: emoji flag → first two uppercase ASCII letters → 'un' fallback.
  static String getFlag(String serverName) {
    final flags = extractFlags(serverName);
    if (flags.isNotEmpty) return flags.first;

    // Fallback: first 2 consecutive uppercase ASCII letters
    final match = RegExp(r'[A-Z]{2}').firstMatch(serverName);
    if (match != null) return match.group(0)!.toLowerCase();

    return 'un';
  }

  /// Cleans the server name for display:
  /// - Removes the **first** flag emoji (shown separately via CircleFlag widget)
  /// - Replaces subsequent flag emojis with their uppercase ISO code text
  ///   so "via" relationships remain readable (e.g. "🇧🇬 via 🇷🇺 …" → "via RU …")
  static String cleanName(String serverName) {
    final buffer = StringBuffer();
    final runes = serverName.runes.toList();
    bool firstFlagRemoved = false;

    for (int i = 0; i < runes.length; i++) {
      // Check for a regional-indicator pair (= one flag emoji)
      if (i < runes.length - 1 &&
          runes[i] >= _riStart &&
          runes[i] <= _riEnd &&
          runes[i + 1] >= _riStart &&
          runes[i + 1] <= _riEnd) {
        if (!firstFlagRemoved) {
          // Skip the primary flag entirely
          firstFlagRemoved = true;
          i++;
          continue;
        }
        // Replace secondary flags with their text code
        final c1 = String.fromCharCode(
            runes[i] - _riStart + 'A'.codeUnitAt(0));
        final c2 = String.fromCharCode(
            runes[i + 1] - _riStart + 'A'.codeUnitAt(0));
        buffer.write('$c1$c2');
        i++;
        continue;
      }

      // Skip a lone regional indicator (shouldn't happen, safety guard)
      if (runes[i] >= _riStart && runes[i] <= _riEnd) continue;

      buffer.writeCharCode(runes[i]);
    }

    // Collapse extra whitespace and trim
    return buffer.toString().trim().replaceAll(RegExp(r'\s{2,}'), ' ');
  }
}
