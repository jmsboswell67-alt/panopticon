import 'package:flutter/services.dart' show rootBundle;

import 'instrument.dart';

/// Loads instrument JSON files bundled at `assets/instruments/`.
///
/// The available instruments are hardcoded here rather than discovered at
/// runtime — Flutter's rootBundle does not list directories. New instrument
/// files added to `assets/instruments/` must also be added below and to the
/// `assets/instruments/` line in `pubspec.yaml`.
class InstrumentLoader {
  InstrumentLoader();

  static const _knownIds = <String>[
    'phq9',
    'gad7',
    'who5',
    'iri',
    'mfq30',
    'daily_scales',
  ];

  final Map<String, Instrument> _cache = {};

  Future<List<Instrument>> loadAll() async {
    final out = <Instrument>[];
    for (final id in _knownIds) {
      out.add(await load(id));
    }
    return out;
  }

  Future<Instrument> load(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/instruments/$id.json');
    final parsed = Instrument.decode(raw);
    _cache[id] = parsed;
    return parsed;
  }
}
