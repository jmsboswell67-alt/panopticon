import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/journal/journal_pipeline.dart';

void main() {
  final pipeline = JournalPipeline();

  test('detects food + exercise sections', () {
    final result = pipeline.run(
        'Went for a run this morning. Then I ate Burger King for lunch.');
    final types = result.sections.map((s) => s.sectionType).toSet();
    expect(types, contains('food'));
    expect(types, contains('exercise'));
  });

  test('detects "I always X" self-hypothesis', () {
    final result = pipeline.run("I always eat junk after going for a run.");
    expect(result.selfHypotheses, isNotEmpty);
    expect(result.selfHypotheses.first.claim.toLowerCase(),
        contains('i always eat junk'));
  });

  test('detects "Whenever ... I usually ..." pattern', () {
    final result = pipeline.run(
        'Whenever I go on a run, I usually fuck it up by eating like shit after.');
    expect(result.selfHypotheses, isNotEmpty);
  });

  test('linguistic metrics produce sane numbers', () {
    final result = pipeline.run(
        'The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs.');
    expect(result.linguisticMetrics.wordCount, greaterThan(10));
    expect(result.linguisticMetrics.sentenceCount, equals(2));
    expect(result.linguisticMetrics.ttr, lessThanOrEqualTo(1));
  });

  test('safety scanner triggers on direct ideation phrasing', () {
    final result = pipeline.run('Honestly today I just want to die.');
    expect(result.safety.isNotEmpty, isTrue);
    expect(result.safety.categories, contains('suicidality'));
  });

  test('safety scanner does NOT trigger on benign "kill" usage', () {
    final result = pipeline.run('I could kill for a coffee right now.');
    expect(result.safety.isEmpty, isTrue);
  });

  test('mergeIntoPayload preserves the original prose verbatim', () {
    const text = 'Today I slept terribly. I always have weird dreams when stressed.';
    final result = pipeline.run(text);
    final merged = result.mergeIntoPayload({'text': text});
    expect(merged['text'], equals(text));
    expect(merged['sections'], isA<List>());
    expect(merged['self_hypotheses'], isA<List>());
    expect(merged['linguistic_metrics'], isA<Map>());
  });
}
