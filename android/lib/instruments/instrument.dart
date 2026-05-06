import 'dart:convert';

/// In-memory representation of an `instruments/*.json` file.
///
/// Phase 2 supports two top-level shapes:
///   - Single-section instruments with a top-level `items` array (PHQ-9, GAD-7,
///     WHO-5, IRI), or `scales` (daily_scales — heterogeneous response types).
///   - Multi-part instruments with a top-level `parts[]` (MFQ-30), each part
///     carrying its own stem, response_format, and items.
class Instrument {
  Instrument({
    required this.id,
    required this.version,
    required this.name,
    required this.purpose,
    required this.tier,
    this.stem,
    required this.parts,
    required this.subscales,
    required this.flagRules,
    required this.estimatedMinutes,
    required this.minimumIntervalDays,
    this.requiresTraumaScreens = false,
  });

  final String id;
  final String version;
  final String name;
  final String purpose;
  final InstrumentTier tier;
  final String? stem;
  final List<InstrumentPart> parts;
  final List<Subscale> subscales;
  final List<FlagRule> flagRules;
  final int estimatedMinutes;
  final int minimumIntervalDays;
  final bool requiresTraumaScreens;

  /// Convenience: every item across every part, in administration order.
  Iterable<InstrumentItem> get allItems sync* {
    for (final part in parts) {
      yield* part.items;
    }
  }

  bool get hasSafetyCriticalItems =>
      allItems.any((i) => i.safetyCritical);

  factory Instrument.fromJson(Map<String, dynamic> json) {
    final id = json['instrument_id'] as String;
    final partsJson = json['parts'] as List?;
    final defaultStem = json['stem'] as String?;
    final defaultResponseFormat = json['response_format'] != null
        ? ResponseFormat.fromJson(json['response_format'] as Map<String, dynamic>)
        : null;

    final parts = <InstrumentPart>[];
    if (partsJson != null && partsJson.isNotEmpty) {
      for (final partRaw in partsJson) {
        final part = partRaw as Map<String, dynamic>;
        final responseFormat = part['response_format'] != null
            ? ResponseFormat.fromJson(part['response_format'] as Map<String, dynamic>)
            : defaultResponseFormat;
        parts.add(InstrumentPart(
          id: part['part_id'] as String? ?? 'part_${parts.length}',
          stem: part['stem'] as String? ?? defaultStem,
          items: _parseItems(part['items'] as List, responseFormat, fallbackResponse: responseFormat),
        ));
      }
    } else {
      // Single-section instrument: items or scales.
      final itemsJson = (json['items'] ?? json['scales']) as List;
      parts.add(InstrumentPart(
        id: 'main',
        stem: defaultStem,
        items: _parseItems(itemsJson, defaultResponseFormat, fallbackResponse: defaultResponseFormat),
      ));
    }

    final scoring = (json['scoring'] as Map<String, dynamic>?) ?? const {};
    final subscalesJson = (scoring['subscales'] as List?) ?? const [];
    final flagsJson = (scoring['flag_rules'] as List?) ?? const [];

    final administration = (json['administration'] as Map<String, dynamic>?) ?? const {};

    return Instrument(
      id: id,
      version: json['instrument_version'] as String? ?? '1.0',
      name: json['name'] as String? ?? id,
      purpose: json['purpose'] as String? ?? '',
      tier: _inferTier(id),
      stem: defaultStem,
      parts: parts,
      subscales: subscalesJson
          .map((s) => Subscale.fromJson(s as Map<String, dynamic>))
          .toList(),
      flagRules: flagsJson
          .map((r) => FlagRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: (administration['estimated_minutes'] as num?)?.toInt() ??
          ((administration['estimated_seconds'] as num?)?.toInt() != null
              ? ((administration['estimated_seconds'] as num).toInt() / 60).ceil()
              : 5),
      minimumIntervalDays:
          (administration['minimum_interval_days'] as num?)?.toInt() ??
              ((administration['minimum_interval_hours'] as num?)?.toInt() != null
                  ? ((administration['minimum_interval_hours'] as num).toInt() / 24).ceil()
                  : 1),
      requiresTraumaScreens:
          (administration['requires_trauma_screens'] as bool?) ?? false,
    );
  }

  static List<InstrumentItem> _parseItems(
    List<dynamic> raw,
    ResponseFormat? sectionFormat, {
    ResponseFormat? fallbackResponse,
  }) {
    return raw.map((r) {
      final map = r as Map<String, dynamic>;
      final type = map['type'] as String?;
      final ResponseFormat fmt;
      if (type != null) {
        fmt = ResponseFormat.fromInlineScale(map);
      } else {
        fmt = sectionFormat ?? fallbackResponse ?? const ResponseFormat.text();
      }
      return InstrumentItem(
        id: (map['item_id'] ?? map['scale_id']) as String,
        prompt: (map['prompt'] ?? map['scale_id']) as String,
        subscale: map['subscale'] as String?,
        reverse: map['reverse'] as bool? ?? false,
        safetyCritical: map['safety_critical'] as bool? ?? false,
        notes: map['notes'] as String?,
        responseFormat: fmt,
        secondaryField: map['secondary_field'] != null
            ? SecondaryField.fromJson(map['secondary_field'] as Map<String, dynamic>)
            : null,
      );
    }).toList();
  }

  static InstrumentTier _inferTier(String id) {
    // daily_scales is project-specific (Tier 4); everything else in our current
    // set is a validated screen (Tier 1).
    if (id == 'daily_scales') return InstrumentTier.projectSpecific;
    return InstrumentTier.validatedScreen;
  }

  static Instrument decode(String jsonString) =>
      Instrument.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

enum InstrumentTier {
  validatedScreen,
  projectSpecific;

  String get label => switch (this) {
        InstrumentTier.validatedScreen => 'Validated screen',
        InstrumentTier.projectSpecific => 'Project-specific self-report',
      };
}

class InstrumentPart {
  InstrumentPart({required this.id, required this.stem, required this.items});

  final String id;
  final String? stem;
  final List<InstrumentItem> items;
}

class InstrumentItem {
  InstrumentItem({
    required this.id,
    required this.prompt,
    required this.responseFormat,
    this.subscale,
    this.reverse = false,
    this.safetyCritical = false,
    this.notes,
    this.secondaryField,
  });

  final String id;
  final String prompt;
  final String? subscale;
  final bool reverse;
  final bool safetyCritical;
  final String? notes;
  final ResponseFormat responseFormat;
  final SecondaryField? secondaryField;

  bool get isCatchItem => subscale == 'catch';
}

/// A response-input style. Heterogeneous: an instrument-level format applies
/// to all items, but daily_scales-style files specify a per-item type instead.
sealed class ResponseFormat {
  const ResponseFormat();

  const factory ResponseFormat.likert(List<LikertOption> options) =
      LikertResponseFormat;
  const factory ResponseFormat.likertScale({
    required int min,
    required int max,
    String? anchorLow,
    String? anchorHigh,
  }) = LikertScaleResponseFormat;
  const factory ResponseFormat.integer({int? min, int? max}) =
      IntegerResponseFormat;
  const factory ResponseFormat.enumOptions(List<EnumOption> options) =
      EnumResponseFormat;
  const factory ResponseFormat.text() = TextResponseFormat;

  static ResponseFormat fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'likert':
        final options = (json['options'] as List)
            .map((o) => LikertOption.fromJson(o as Map<String, dynamic>))
            .toList();
        return ResponseFormat.likert(options);
      default:
        return ResponseFormat.fromInlineScale(json);
    }
  }

  /// daily_scales-style per-item types: `likert_1_10`, `integer`, `enum`.
  static ResponseFormat fromInlineScale(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'likert_1_10':
        return ResponseFormat.likertScale(
          min: 1,
          max: 10,
          anchorLow: map['anchor_low'] as String?,
          anchorHigh: map['anchor_high'] as String?,
        );
      case 'integer':
        return ResponseFormat.integer(
          min: (map['min'] as num?)?.toInt(),
          max: (map['max'] as num?)?.toInt(),
        );
      case 'enum':
        final raw = map['options'] as List;
        final options = raw.map((o) {
          if (o is Map) {
            return EnumOption.fromJson(o.cast<String, dynamic>());
          }
          final s = o as String;
          return EnumOption(value: s, label: s);
        }).toList();
        return ResponseFormat.enumOptions(options);
      case 'text':
        return const ResponseFormat.text();
      default:
        return const ResponseFormat.text();
    }
  }
}

class LikertResponseFormat extends ResponseFormat {
  const LikertResponseFormat(this.options);
  final List<LikertOption> options;
}

class LikertScaleResponseFormat extends ResponseFormat {
  const LikertScaleResponseFormat({
    required this.min,
    required this.max,
    this.anchorLow,
    this.anchorHigh,
  });
  final int min;
  final int max;
  final String? anchorLow;
  final String? anchorHigh;
}

class IntegerResponseFormat extends ResponseFormat {
  const IntegerResponseFormat({this.min, this.max});
  final int? min;
  final int? max;
}

class EnumResponseFormat extends ResponseFormat {
  const EnumResponseFormat(this.options);
  final List<EnumOption> options;
}

class TextResponseFormat extends ResponseFormat {
  const TextResponseFormat();
}

class LikertOption {
  LikertOption({required this.value, required this.label});
  factory LikertOption.fromJson(Map<String, dynamic> j) =>
      LikertOption(value: (j['value'] as num).toDouble(), label: j['label'] as String);
  final double value;
  final String label;
}

class EnumOption {
  EnumOption({required this.value, required this.label});
  factory EnumOption.fromJson(Map<String, dynamic> j) =>
      EnumOption(value: j['value'] as String, label: (j['label'] ?? j['value']) as String);
  final String value;
  final String label;
}

class SecondaryField {
  SecondaryField({
    required this.id,
    required this.prompt,
    required this.type,
    this.optional = false,
  });
  factory SecondaryField.fromJson(Map<String, dynamic> j) => SecondaryField(
        id: j['field_id'] as String,
        prompt: j['prompt'] as String,
        type: j['type'] as String? ?? 'text',
        optional: j['optional'] as bool? ?? false,
      );
  final String id;
  final String prompt;
  final String type;
  final bool optional;
}

class Subscale {
  Subscale({
    required this.id,
    required this.name,
    required this.method,
    this.items = const [],
    this.subscaleInputs = const [],
    this.maxScore,
    this.interpretation = const [],
    this.description,
  });

  factory Subscale.fromJson(Map<String, dynamic> j) {
    final interp = (j['interpretation'] as List?) ?? const [];
    return Subscale(
      id: j['subscale_id'] as String,
      name: j['name'] as String? ?? j['subscale_id'] as String,
      method: j['method'] as String,
      items: ((j['items'] as List?) ?? const []).cast<String>(),
      subscaleInputs: ((j['subscale_inputs'] as List?) ?? const []).cast<String>(),
      maxScore: (j['max_score'] as num?)?.toDouble(),
      description: j['description'] as String?,
      interpretation: interp
          .map((r) => InterpretationRange.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String method;
  final List<String> items;
  final List<String> subscaleInputs;
  final double? maxScore;
  final List<InterpretationRange> interpretation;
  final String? description;
}

class InterpretationRange {
  InterpretationRange({
    required this.low,
    required this.high,
    required this.label,
    required this.severity,
  });
  factory InterpretationRange.fromJson(Map<String, dynamic> j) {
    final range = (j['range'] as List).cast<num>();
    return InterpretationRange(
      low: range[0].toDouble(),
      high: range[1].toDouble(),
      label: j['label'] as String,
      severity: j['severity'] as String? ?? 'info',
    );
  }
  final double low;
  final double high;
  final String label;
  final String severity;

  bool covers(double value) => value >= low && value <= high;
}

class FlagRule {
  FlagRule({
    required this.id,
    required this.condition,
    required this.flagCategory,
    this.flagSeverity,
    this.flagSeverityMap = const {},
    this.description,
    this.notes,
  });
  factory FlagRule.fromJson(Map<String, dynamic> j) => FlagRule(
        id: j['rule_id'] as String,
        condition: (j['condition'] as String?) ?? '',
        flagCategory: j['flag_category'] as String,
        flagSeverity: j['flag_severity'] as String?,
        flagSeverityMap:
            ((j['flag_severity_map'] as Map?) ?? const {}).cast<String, dynamic>(),
        description: j['description'] as String?,
        notes: j['notes'] as String?,
      );

  final String id;
  final String condition;
  final String flagCategory;
  final String? flagSeverity;
  final Map<String, dynamic> flagSeverityMap;
  final String? description;
  final String? notes;
}
