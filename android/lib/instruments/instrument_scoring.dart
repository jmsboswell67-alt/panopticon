import 'instrument.dart';

/// Pure scoring engine — given an instrument and a map of (item_id → response),
/// computes subscale scores and evaluates flag rules.
///
/// Response values follow the shape stored in `instrument_response_payload`:
/// each item maps to a number, string, or boolean. Likert and integer items
/// produce numbers; enum items produce their `value` string.
class InstrumentScorer {
  InstrumentScorer(this.instrument);

  final Instrument instrument;

  /// Compute every subscale defined on the instrument.
  Map<String, double> computeSubscales(Map<String, Object?> responses) {
    final results = <String, double>{};
    for (final s in instrument.subscales) {
      final v = _computeOne(s, responses, results);
      if (v != null) results[s.id] = v;
    }
    return results;
  }

  double? _computeOne(
    Subscale s,
    Map<String, Object?> responses,
    Map<String, double> alreadyComputed,
  ) {
    switch (s.method) {
      case 'sum':
        return _numericValuesFor(s.items, responses, reverse: false).fold<double>(0, (a, b) => a + b);
      case 'sum_with_reversal':
        return _numericValuesWithReversal(s.items, responses).fold<double>(0, (a, b) => a + b);
      case 'sum_times_4':
        final s4 = _numericValuesFor(s.items, responses, reverse: false).fold<double>(0, (a, b) => a + b);
        return s4 * 4;
      case 'mean':
        final vs = _numericValuesFor(s.items, responses, reverse: false);
        if (vs.isEmpty) return null;
        return vs.fold<double>(0, (a, b) => a + b) / vs.length;
      case 'mean_of_subscales':
        final vs = s.subscaleInputs
            .map((id) => alreadyComputed[id])
            .whereType<double>()
            .toList();
        if (vs.isEmpty) return null;
        return vs.fold<double>(0, (a, b) => a + b) / vs.length;
      case 'individualizing_minus_binding':
        final ind = alreadyComputed['individualizing'];
        final bind = alreadyComputed['binding'];
        if (ind == null || bind == null) return null;
        return ind - bind;
      default:
        return null;
    }
  }

  Iterable<double> _numericValuesFor(
    List<String> itemIds,
    Map<String, Object?> responses, {
    required bool reverse,
  }) sync* {
    for (final id in itemIds) {
      final raw = responses[id];
      if (raw is num) yield raw.toDouble();
    }
  }

  /// For sum_with_reversal: walk the subscale's items, look up each item on
  /// the instrument, apply the reverse polarity if marked.
  Iterable<double> _numericValuesWithReversal(
    List<String> itemIds,
    Map<String, Object?> responses,
  ) sync* {
    final byId = {for (final i in instrument.allItems) i.id: i};
    for (final id in itemIds) {
      final item = byId[id];
      final raw = responses[id];
      if (raw is! num || item == null) continue;
      if (item.reverse) {
        // Reversal uses the response_format's max value.
        final max = _maxValueFor(item.responseFormat);
        if (max == null) {
          yield raw.toDouble();
        } else {
          yield max - raw.toDouble();
        }
      } else {
        yield raw.toDouble();
      }
    }
  }

  double? _maxValueFor(ResponseFormat fmt) {
    switch (fmt) {
      case LikertResponseFormat(:final options):
        return options.map((o) => o.value).reduce((a, b) => a > b ? a : b);
      case LikertScaleResponseFormat(:final max):
        return max.toDouble();
      case IntegerResponseFormat(max: final max):
        return max?.toDouble();
      case EnumResponseFormat _:
      case TextResponseFormat _:
        return null;
    }
  }

  /// Find the interpretation band for a computed subscale score.
  InterpretationRange? interpretFor(String subscaleId, double value) {
    for (final s in instrument.subscales) {
      if (s.id != subscaleId) continue;
      for (final r in s.interpretation) {
        if (r.covers(value)) return r;
      }
    }
    return null;
  }

  /// Evaluate flag rules. Returns one entry per rule that fires.
  ///
  /// Conditions supported:
  ///   `<token> <op> <number>`         where op ∈ { <, <=, ==, !=, >=, > }
  ///   `<token> in [<csv-of-strings>]`
  ///
  /// Tokens are item ids OR subscale ids OR `total`. Strings inside the list
  /// can be quoted with single quotes, double quotes, or unquoted bare words.
  List<FiredFlag> evaluateFlags(
    Map<String, Object?> responses,
    Map<String, double> subscaleScores,
  ) {
    final scope = <String, Object?>{
      ...responses,
      ...subscaleScores,
    };
    final fired = <FiredFlag>[];
    for (final rule in instrument.flagRules) {
      if (rule.condition.isEmpty) continue;
      final matched = _evaluateCondition(rule.condition, scope);
      if (matched == null || matched == false) continue;

      final severity = _severityFor(rule, scope, matched);
      fired.add(FiredFlag(rule: rule, severity: severity));
    }
    return fired;
  }

  String _severityFor(FlagRule rule, Map<String, Object?> scope, Object matched) {
    if (rule.flagSeverity != null) return rule.flagSeverity!;
    if (rule.flagSeverityMap.isNotEmpty) {
      // Severity map keys correspond to the matched value (item response or
      // enum value), e.g. PHQ-9 q9 maps {"1": "watch", "2": "concern", "3": "urgent"}.
      final key = matched.toString();
      final mapped = rule.flagSeverityMap[key];
      if (mapped is String) return mapped;
      if (mapped is num) return mapped.toString();
    }
    return 'watch';
  }

  /// Returns the value that satisfied the condition (truthy), or null/false
  /// if not matched. The truthy value is sometimes the matched response
  /// itself (e.g. `phq9_9 > 0` returns the numeric response so the severity
  /// map can key off it).
  Object? _evaluateCondition(String condition, Map<String, Object?> scope) {
    final trimmed = condition.trim();

    // String containment: <token> in [a, b, c]
    final inMatch = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+\[(.+)\]$').firstMatch(trimmed);
    if (inMatch != null) {
      final token = inMatch.group(1)!;
      final list = inMatch.group(2)!
          .split(',')
          .map((s) => s.trim().replaceAll(RegExp("^['\"]|['\"]\$"), ''))
          .toList();
      final v = scope[token];
      if (v == null) return null;
      if (list.contains(v.toString())) return v;
      return null;
    }

    // Numeric comparison
    final cmpMatch = RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*(<=|>=|==|!=|<|>)\s*(-?\d+(?:\.\d+)?)$')
        .firstMatch(trimmed);
    if (cmpMatch != null) {
      final token = cmpMatch.group(1)!;
      final op = cmpMatch.group(2)!;
      final rhs = double.parse(cmpMatch.group(3)!);
      final raw = scope[token];
      if (raw is! num) return null;
      final lhs = raw.toDouble();
      final ok = switch (op) {
        '<' => lhs < rhs,
        '<=' => lhs <= rhs,
        '==' => lhs == rhs,
        '!=' => lhs != rhs,
        '>=' => lhs >= rhs,
        '>' => lhs > rhs,
        _ => false,
      };
      return ok ? raw : null;
    }

    return null;
  }
}

class FiredFlag {
  FiredFlag({required this.rule, required this.severity});
  final FlagRule rule;
  final String severity;

  bool get isUrgent => severity == 'urgent';
  bool get isConcernOrAbove => severity == 'concern' || isUrgent;
  bool get isSafetyCategory =>
      rule.flagCategory == 'suicidality' || rule.flagCategory == 'self_harm';
}
