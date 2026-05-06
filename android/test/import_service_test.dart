import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/data/import_service.dart';

void main() {
  group('computeDedupKey', () {
    test('identical inputs produce identical keys', () {
      final a = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 1715116800000,
        payloadJson: '{"title":"X","platform":"youtube"}',
      );
      final b = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 1715116800000,
        payloadJson: '{"title":"X","platform":"youtube"}',
      );
      expect(a, equals(b));
    });

    test('payload key reordering still produces the same key', () {
      final a = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 100,
        payloadJson: '{"title":"X","platform":"youtube"}',
      );
      final b = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 100,
        payloadJson: '{"platform":"youtube","title":"X"}',
      );
      expect(a, equals(b),
          reason: 'JSON key ordering must not affect the dedup key');
    });

    test('different timestamps produce different keys', () {
      final a = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 100,
        payloadJson: '{"title":"X"}',
      );
      final b = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 101,
        payloadJson: '{"title":"X"}',
      );
      expect(a, isNot(equals(b)));
    });

    test('different sources produce different keys', () {
      final a = computeDedupKey(
        source: 'media',
        eventType: 'video_view',
        timestampUtc: 100,
        payloadJson: null,
      );
      final b = computeDedupKey(
        source: 'browse',
        eventType: 'video_view',
        timestampUtc: 100,
        payloadJson: null,
      );
      expect(a, isNot(equals(b)));
    });

    test('null and empty payload produce the same key', () {
      final a = computeDedupKey(
        source: 's',
        eventType: 'e',
        timestampUtc: 1,
        payloadJson: null,
      );
      final b = computeDedupKey(
        source: 's',
        eventType: 'e',
        timestampUtc: 1,
        payloadJson: '',
      );
      expect(a, equals(b));
    });
  });
}
