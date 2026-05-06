import 'dart:math' as math;

import 'safety_regex.dart';

/// Phase 1 of the journal-pipeline (per docs/journal-pipeline.md).
///
/// Pure-Dart, regex/rule based — no LLM, no entity extraction, no sentiment
/// scoring beyond linguistic metrics. Implements:
///
///   - Stage 1: section segmentation (food, sleep, social, work, exercise,
///     media, spending, animal_interaction, cognitive_engagement, intimacy,
///     substance_use, concern, win)
///   - Stage 3: self-hypothesis detection ("I always X", "I keep doing X")
///   - Stage 5: linguistic metrics (TTR, mean sentence length, grade level)
///   - Safety pass via SafetyScanner
///
/// Stages 2 (entities), 4 (sentiment), 6 (topic-of-concern) are deferred to
/// Phase 5 (LLM-backed pipeline).
class JournalPipeline {
  JournalPipeline({SafetyScanner? scanner}) : _safety = scanner ?? SafetyScanner();

  final SafetyScanner _safety;

  JournalPipelineResult run(String text) {
    return JournalPipelineResult(
      sections: _segmentSections(text),
      selfHypotheses: _detectHypotheses(text),
      linguisticMetrics: _linguisticMetrics(text),
      safety: _safety.scan(text),
    );
  }

  // --- Stage 1: section segmentation -----------------------------------------

  static const _sectionKeywords = <String, List<String>>{
    'food': [
      'ate', 'eating', 'eat', 'breakfast', 'lunch', 'dinner', 'snack',
      'meal', 'restaurant', 'cooked', 'cook', 'hungry', 'hunger',
      'fasting', 'fast food', 'burger', 'pizza', 'salad', 'coffee',
      'caffeine', 'sugar', 'soda', 'drink', 'drinking water',
    ],
    'sleep': [
      'slept', 'sleep', 'asleep', 'bed', 'bedtime', 'wake', 'woke',
      'awake', 'nap', 'dream', 'dreamt', 'tired', 'exhausted',
      'insomnia', 'rest',
    ],
    'social': [
      'friend', 'family', 'mom', 'dad', 'partner', 'husband', 'wife',
      'kids', 'colleague', 'coworker', 'lonely', 'alone', 'isolated',
      'hung out', 'caught up with', 'called', 'texted', 'visited',
      'party', 'gathering',
    ],
    'work': [
      'meeting', 'meetings', 'deadline', 'project', 'standup', 'sprint',
      'manager', 'boss', 'task', 'tasks', 'pr', 'code', 'coding',
      'shipped', 'reviewed', 'review', 'school', 'class', 'homework',
      'study', 'studying',
    ],
    'exercise': [
      'ran', 'run', 'running', 'walked', 'walk', 'walking', 'gym',
      'workout', 'lifted', 'weights', 'yoga', 'cycling', 'biked',
      'bike', 'swim', 'swimming', 'hiked', 'hiking', 'sports',
    ],
    'media': [
      'watched', 'watching', 'movie', 'tv', 'series', 'show', 'episode',
      'podcast', 'book', 'reading', 'read', 'youtube', 'instagram',
      'tiktok', 'twitter', 'reddit', 'facebook', 'news',
    ],
    'spending': [
      'bought', 'purchased', 'spent', 'paid', 'order', 'ordered',
      'amazon', 'subscription', 'donation', 'donated', 'gift',
    ],
    'animal_interaction': [
      'dog', 'cat', 'puppy', 'kitten', 'pet', 'walk the dog', 'fed the',
      'leash', 'vet', 'animal', 'wildlife', 'birdwatching',
    ],
    'cognitive_engagement': [
      'learned', 'learning', 'studied', 'studying', 'figured out',
      'puzzle', 'class', 'lecture', 'course', 'tutorial', 'paper',
      'research', 'understood', 'realized', 'thinking about',
    ],
    'intimacy': [
      'sex', 'made love', 'intimate', 'cuddled', 'kissed', 'romantic',
    ],
    'substance_use': [
      'drank', 'beer', 'wine', 'whiskey', 'liquor', 'alcohol', 'drunk',
      'weed', 'cannabis', 'edible', 'joint', 'high', 'cigarette',
      'smoking', 'vape', 'mushrooms', 'shroom',
    ],
    'concern': [
      'worried', 'worry', 'anxious', 'anxiety', 'scared', 'afraid',
      'nervous', 'fear', 'stressed', 'stressful', 'overwhelm',
      'overwhelmed', 'rumination', 'panicked', 'panic',
    ],
    'win': [
      'crushed it', 'nailed it', 'proud of', 'accomplished', 'finished',
      'completed', 'shipped', 'breakthrough', 'finally',
    ],
  };

  List<JournalSection> _segmentSections(String text) {
    if (text.isEmpty) return const [];
    final sentences = _splitSentences(text);
    final sections = <JournalSection>[];

    for (final span in sentences) {
      final lower = span.text.toLowerCase();
      final hits = <String>{};
      for (final entry in _sectionKeywords.entries) {
        for (final kw in entry.value) {
          if (lower.contains(kw)) {
            hits.add(entry.key);
            break;
          }
        }
      }
      final matched = hits.isEmpty ? const ['narrative'] : hits.toList();
      for (final type in matched) {
        sections.add(JournalSection(
          sectionType: type,
          start: span.start,
          end: span.end,
        ));
      }
    }
    return sections;
  }

  // --- Stage 3: self-hypothesis detection ------------------------------------

  static final List<RegExp> _hypothesisPatterns = [
    // "I always/never/usually/often/tend to/keep ..."
    RegExp(
        r"\bI\s+(always|never|usually|often|tend\s+to|keep|seem\s+to|tend\s+to|cannot\s+help\s+but|can'?t\s+help\s+but)\b[^.!?\n]*[.!?]?",
        caseSensitive: false),
    // "Whenever X, I (usually|always|...) Y"
    RegExp(r"\bwhenever\s+[^,\n]+,?\s*I[^.!?\n]*[.!?]?", caseSensitive: false),
    // "Every time X, I ..."
    RegExp(r"\bevery\s+time\s+[^,\n]+,?\s*I[^.!?\n]*[.!?]?", caseSensitive: false),
    // "I'm the kind of person who ..."
    RegExp(r"\bI'?m\s+the\s+kind\s+of\s+person\s+who\b[^.!?\n]*[.!?]?",
        caseSensitive: false),
    // "This is a pattern ..."
    RegExp(r"\bthis\s+is\s+a\s+pattern\b[^.!?\n]*[.!?]?", caseSensitive: false),
    // "I (have|'ve) (been|started) ..." trend statements
    RegExp(r"\bI'?ve\s+been\s+[^.!?\n]*[.!?]?", caseSensitive: false),
  ];

  List<SelfHypothesis> _detectHypotheses(String text) {
    final out = <SelfHypothesis>[];
    final seen = <String>{};
    for (final pattern in _hypothesisPatterns) {
      for (final m in pattern.allMatches(text)) {
        final claim = text.substring(m.start, m.end).trim();
        if (claim.length < 12) continue; // skip trivial fragments
        final canonical = claim.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (seen.contains(canonical)) continue;
        seen.add(canonical);
        out.add(SelfHypothesis(claim: claim, start: m.start, end: m.end));
      }
    }
    return out;
  }

  // --- Stage 5: linguistic metrics -------------------------------------------

  LinguisticMetrics _linguisticMetrics(String text) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) {
      return const LinguisticMetrics(
        ttr: 0,
        meanSentenceLength: 0,
        wordCount: 0,
        sentenceCount: 0,
        flLikeGrade: 0,
      );
    }
    final unique = tokens.toSet();
    final ttr = unique.length / tokens.length;
    final sentences = _splitSentences(text);
    final sentenceCount = sentences.isEmpty ? 1 : sentences.length;
    final meanLen = tokens.length / sentenceCount;

    // Approximate Flesch-Kincaid grade level using a syllable estimator.
    final totalSyllables = tokens.fold<int>(0, (acc, t) => acc + _approxSyllables(t));
    final asl = meanLen;
    final asw = totalSyllables / tokens.length;
    final fk = (0.39 * asl) + (11.8 * asw) - 15.59;

    return LinguisticMetrics(
      ttr: double.parse(ttr.toStringAsFixed(3)),
      meanSentenceLength: double.parse(meanLen.toStringAsFixed(1)),
      wordCount: tokens.length,
      sentenceCount: sentenceCount,
      flLikeGrade: double.parse(math.max(0, fk).toStringAsFixed(1)),
    );
  }

  static List<String> _tokenize(String text) {
    return RegExp(r"[A-Za-z']+")
        .allMatches(text)
        .map((m) => m.group(0)!.toLowerCase())
        .toList();
  }

  static List<_SentenceSpan> _splitSentences(String text) {
    final spans = <_SentenceSpan>[];
    final pattern = RegExp(r"[^.!?\n]+(?:[.!?]+|\n+|$)", multiLine: true);
    for (final m in pattern.allMatches(text)) {
      final raw = text.substring(m.start, m.end).trim();
      if (raw.isEmpty) continue;
      spans.add(_SentenceSpan(text: raw, start: m.start, end: m.end));
    }
    return spans;
  }

  // Crude vowel-group syllable estimator.
  static int _approxSyllables(String word) {
    if (word.isEmpty) return 0;
    final w = word.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '');
    if (w.isEmpty) return 0;
    final groups = RegExp(r"[aeiouy]+").allMatches(w).length;
    var n = groups;
    if (w.endsWith('e') && n > 1) n -= 1;
    return math.max(1, n);
  }
}

class _SentenceSpan {
  _SentenceSpan({required this.text, required this.start, required this.end});
  final String text;
  final int start;
  final int end;
}

class JournalPipelineResult {
  JournalPipelineResult({
    required this.sections,
    required this.selfHypotheses,
    required this.linguisticMetrics,
    required this.safety,
  });

  final List<JournalSection> sections;
  final List<SelfHypothesis> selfHypotheses;
  final LinguisticMetrics linguisticMetrics;
  final SafetyScanResult safety;

  /// Merges pipeline outputs into the journal entry's payload, ready for
  /// persistence as the `manual.journal_entry` event payload.
  Map<String, dynamic> mergeIntoPayload(Map<String, dynamic> base) {
    return {
      ...base,
      'sections': sections
          .map((s) => {
                'section_type': s.sectionType,
                'text_span': {'start': s.start, 'end': s.end},
              })
          .toList(),
      'self_hypotheses': selfHypotheses
          .map((h) => {
                'claim': h.claim,
                'test_status': 'untested',
              })
          .toList(),
      'linguistic_metrics': {
        'ttr': linguisticMetrics.ttr,
        'mean_sentence_length': linguisticMetrics.meanSentenceLength,
        'word_count': linguisticMetrics.wordCount,
        'sentence_count': linguisticMetrics.sentenceCount,
        'fk_grade': linguisticMetrics.flLikeGrade,
      },
    };
  }
}

class JournalSection {
  JournalSection({required this.sectionType, required this.start, required this.end});
  final String sectionType;
  final int start;
  final int end;
}

class SelfHypothesis {
  SelfHypothesis({required this.claim, required this.start, required this.end});
  final String claim;
  final int start;
  final int end;
}

class LinguisticMetrics {
  const LinguisticMetrics({
    required this.ttr,
    required this.meanSentenceLength,
    required this.wordCount,
    required this.sentenceCount,
    required this.flLikeGrade,
  });
  final double ttr;
  final double meanSentenceLength;
  final int wordCount;
  final int sentenceCount;
  final double flLikeGrade;
}
