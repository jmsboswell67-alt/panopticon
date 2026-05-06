/// Tier-1 trauma-aware safety scanner.
///
/// Scans free-text (journal prose, observed-interaction notes) for
/// language indicating active suicidal ideation, self-harm intent, or
/// crisis. False positives are acceptable here — the response is "show
/// crisis resources + log a flag," not "block submission."
///
/// These patterns are intentionally conservative: short phrases with
/// minimal stop-words tend to over-trigger ("kill" alone matches "could
/// kill for a coffee"). The phrases below were chosen to require enough
/// context to be a real signal in most cases.
///
/// Calibration philosophy: match phrases that a clinician would want
/// surfaced even if the user is just venting. The cost of a false
/// positive is a one-time crisis-resources card; the cost of a false
/// negative is silence at the worst possible moment.
class SafetyScanner {
  SafetyScanner();

  static final List<RegExp> _suicidalityPatterns = [
    // Direct ideation
    RegExp(r"\b(want|wanting|wanted)\s+to\s+die\b", caseSensitive: false),
    RegExp(r"\b(want|wanting|wanted)\s+to\s+(kill|end)\s+myself\b", caseSensitive: false),
    RegExp(r"\bkill\s+myself\b", caseSensitive: false),
    RegExp(r"\bend\s+(my\s+life|it\s+all)\b", caseSensitive: false),
    RegExp(r"\bbetter\s+off\s+dead\b", caseSensitive: false),
    RegExp(r"\bdon'?t\s+want\s+to\s+(be\s+(here|alive)|live\s+anymore|wake\s+up)\b",
        caseSensitive: false),
    RegExp(r"\bno\s+(reason|point)\s+to\s+(live|go\s+on|keep\s+going)\b",
        caseSensitive: false),
    RegExp(r"\b(thinking|thoughts)\s+(about|of)\s+suicide\b", caseSensitive: false),
    RegExp(r"\bsuicidal\b", caseSensitive: false),
    // Plan-flavored
    RegExp(r"\bhave\s+a\s+plan\s+to\s+(kill|end|hurt)\b", caseSensitive: false),
    RegExp(r"\b(stockpiling|hoarding)\s+pills\b", caseSensitive: false),
  ];

  static final List<RegExp> _selfHarmPatterns = [
    RegExp(r"\bcut(ting)?\s+myself\b", caseSensitive: false),
    RegExp(r"\bself[-\s]?harm(ing)?\b", caseSensitive: false),
    RegExp(r"\bhurt(ing)?\s+myself\b", caseSensitive: false),
    RegExp(r"\bburn(ing)?\s+myself\b", caseSensitive: false),
  ];

  /// Returns the categories that matched, plus the verbatim spans (for the
  /// crisis screen to optionally quote back).
  SafetyScanResult scan(String text) {
    final matches = <SafetyMatch>[];
    for (final p in _suicidalityPatterns) {
      for (final m in p.allMatches(text)) {
        matches.add(SafetyMatch(
          category: 'suicidality',
          start: m.start,
          end: m.end,
          quote: text.substring(m.start, m.end),
        ));
      }
    }
    for (final p in _selfHarmPatterns) {
      for (final m in p.allMatches(text)) {
        matches.add(SafetyMatch(
          category: 'self_harm',
          start: m.start,
          end: m.end,
          quote: text.substring(m.start, m.end),
        ));
      }
    }
    return SafetyScanResult(matches: matches);
  }
}

class SafetyScanResult {
  SafetyScanResult({required this.matches});
  final List<SafetyMatch> matches;

  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;

  Set<String> get categories => matches.map((m) => m.category).toSet();
}

class SafetyMatch {
  SafetyMatch({
    required this.category,
    required this.start,
    required this.end,
    required this.quote,
  });
  final String category;
  final int start;
  final int end;
  final String quote;
}
