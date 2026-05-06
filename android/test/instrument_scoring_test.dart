import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/instruments/instrument.dart';
import 'package:panopticon/instruments/instrument_scoring.dart';

void main() {
  group('PHQ-9', () {
    final phq9 = _loadAsset('assets/instruments/phq9.json');
    final scorer = InstrumentScorer(phq9);

    test('total = sum of all 9 items', () {
      final responses = <String, Object?>{
        for (var i = 1; i <= 9; i++) 'phq9_$i': 2,
      };
      final scores = scorer.computeSubscales(responses);
      expect(scores['total'], equals(18.0));
    });

    test('item 9 endorsement fires the suicidality flag with severity-mapped value', () {
      final responses = <String, Object?>{
        for (var i = 1; i <= 8; i++) 'phq9_$i': 0,
        'phq9_9': 2,
      };
      final scores = scorer.computeSubscales(responses);
      final fired = scorer.evaluateFlags(responses, scores);
      final suicidalityFlag = fired.firstWhere(
        (f) => f.rule.flagCategory == 'suicidality',
      );
      expect(suicidalityFlag.severity, equals('concern'));
    });

    test('item 9 = 0 does not fire', () {
      final responses = <String, Object?>{for (var i = 1; i <= 9; i++) 'phq9_$i': 0};
      final fired = scorer.evaluateFlags(responses, scorer.computeSubscales(responses));
      expect(fired.where((f) => f.rule.flagCategory == 'suicidality'), isEmpty);
    });

    test('total >= 20 fires depression_severity urgent', () {
      final responses = <String, Object?>{for (var i = 1; i <= 9; i++) 'phq9_$i': 3};
      final scores = scorer.computeSubscales(responses);
      final fired = scorer.evaluateFlags(responses, scores);
      final sev = fired.firstWhere((f) => f.rule.flagCategory == 'depression_severity');
      expect(sev.severity, equals('urgent'));
    });

    test('interpretation band reports correctly', () {
      final r = scorer.interpretFor('total', 12);
      expect(r, isNotNull);
      expect(r!.label.toLowerCase(), contains('moderate'));
    });
  });

  group('IRI sum_with_reversal', () {
    final iri = _loadAsset('assets/instruments/iri.json');

    test('reverse-scored items invert before summing', () {
      final scorer = InstrumentScorer(iri);
      // PT subscale items: iri_3 (rev), iri_8, iri_11, iri_15 (rev), iri_21,
      // iri_25, iri_28. Likert max value = 4. Set every PT item to 0; the
      // reverse-scored items should contribute 4 each (max minus 0).
      final responses = <String, Object?>{
        'iri_3': 0,
        'iri_8': 0,
        'iri_11': 0,
        'iri_15': 0,
        'iri_21': 0,
        'iri_25': 0,
        'iri_28': 0,
      };
      final scores = scorer.computeSubscales(responses);
      // Two reversed items, both contribute 4.
      expect(scores['PT'], equals(8.0));
    });
  });

  group('daily_scales suicidal_ideation', () {
    final dsc = _loadAsset('assets/instruments/daily_scales.json');
    final scorer = InstrumentScorer(dsc);

    test('active_no_plan fires concern', () {
      final fired = scorer.evaluateFlags(
        {'suicidal_ideation': 'active_no_plan'},
        const {},
      );
      final flag = fired.firstWhere((f) => f.rule.flagCategory == 'suicidality');
      expect(flag.severity, equals('concern'));
    });

    test('active_with_plan fires urgent', () {
      final fired = scorer.evaluateFlags(
        {'suicidal_ideation': 'active_with_plan'},
        const {},
      );
      final flag = fired.firstWhere((f) => f.rule.flagCategory == 'suicidality');
      expect(flag.severity, equals('urgent'));
    });

    test('none does not fire', () {
      final fired = scorer.evaluateFlags(
        {'suicidal_ideation': 'none'},
        const {},
      );
      expect(fired.where((f) => f.rule.flagCategory == 'suicidality'), isEmpty);
    });
  });

  group('WHO-5 percentage', () {
    final who5 = _loadAsset('assets/instruments/who5.json');
    final scorer = InstrumentScorer(who5);

    test('sum_times_4 produces the percentage score', () {
      final scores = scorer.computeSubscales({
        for (var i = 1; i <= 5; i++) 'who5_$i': 5,
      });
      expect(scores['raw'], equals(25.0));
      expect(scores['percentage'], equals(100.0));
    });

    test('low percentage fires depression_severity', () {
      final scores = scorer.computeSubscales({
        for (var i = 1; i <= 5; i++) 'who5_$i': 1,
      });
      final fired = scorer.evaluateFlags({}, scores);
      expect(fired.any((f) => f.rule.flagCategory == 'depression_severity'), isTrue);
    });
  });

  group('MFQ-30 mean_of_subscales + individualizing_minus_binding', () {
    final mfq = _loadAsset('assets/instruments/mfq30.json');
    final scorer = InstrumentScorer(mfq);

    test('individualizing > binding produces positive progressivism_score', () {
      final responses = <String, Object?>{};
      // Care + Fairness items high; Loyalty + Authority + Sanctity items low.
      for (final item in mfq.allItems) {
        if (['care', 'fairness'].contains(item.subscale)) {
          responses[item.id] = 5;
        } else if (['loyalty', 'authority', 'sanctity'].contains(item.subscale)) {
          responses[item.id] = 0;
        }
      }
      final scores = scorer.computeSubscales(responses);
      expect(scores['progressivism_score']! > 0, isTrue);
    });
  });
}

Instrument _loadAsset(String relative) {
  final file = File(relative);
  return Instrument.decode(file.readAsStringSync());
}
