// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$panopticonDatabaseHash() =>
    r'cd0e78f1ac3d9d97fe9639a134de5ad2a5feb104';

/// See also [panopticonDatabase].
@ProviderFor(panopticonDatabase)
final panopticonDatabaseProvider = Provider<PanopticonDatabase>.internal(
  panopticonDatabase,
  name: r'panopticonDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$panopticonDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PanopticonDatabaseRef = ProviderRef<PanopticonDatabase>;
String _$eventRepositoryHash() => r'4fdf4bc19e6f047c9f5cd861297e065234069662';

/// See also [eventRepository].
@ProviderFor(eventRepository)
final eventRepositoryProvider = Provider<EventRepository>.internal(
  eventRepository,
  name: r'eventRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eventRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EventRepositoryRef = ProviderRef<EventRepository>;
String _$nativeBridgeHash() => r'54cb31bb6b2fbe13d11aeb5cf3e43524ad52e94d';

/// See also [nativeBridge].
@ProviderFor(nativeBridge)
final nativeBridgeProvider = Provider<NativeBridge>.internal(
  nativeBridge,
  name: r'nativeBridgeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nativeBridgeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NativeBridgeRef = ProviderRef<NativeBridge>;
String _$instrumentLoaderHash() => r'ecf0b14b7b5a4131ffc2d06835093191072267f7';

/// See also [instrumentLoader].
@ProviderFor(instrumentLoader)
final instrumentLoaderProvider = Provider<InstrumentLoader>.internal(
  instrumentLoader,
  name: r'instrumentLoaderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$instrumentLoaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InstrumentLoaderRef = ProviderRef<InstrumentLoader>;
String _$manualRepositoryHash() => r'3e54f461c47094c1dce6484c5c0829c63f40e6bb';

/// See also [manualRepository].
@ProviderFor(manualRepository)
final manualRepositoryProvider = Provider<ManualRepository>.internal(
  manualRepository,
  name: r'manualRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$manualRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManualRepositoryRef = ProviderRef<ManualRepository>;
String _$instrumentRepositoryHash() =>
    r'97039c8595ae235c71b35b829f303455afaa398f';

/// See also [instrumentRepository].
@ProviderFor(instrumentRepository)
final instrumentRepositoryProvider = Provider<InstrumentRepository>.internal(
  instrumentRepository,
  name: r'instrumentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$instrumentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InstrumentRepositoryRef = ProviderRef<InstrumentRepository>;
String _$availableInstrumentsHash() =>
    r'1cdfd1bad26f169555327c7c075528c52d9bde49';

/// See also [availableInstruments].
@ProviderFor(availableInstruments)
final availableInstrumentsProvider =
    AutoDisposeFutureProvider<List<Instrument>>.internal(
      availableInstruments,
      name: r'availableInstrumentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availableInstrumentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableInstrumentsRef =
    AutoDisposeFutureProviderRef<List<Instrument>>;
String _$instrumentByIdHash() => r'f9b4178d1635328c20dc1093c9fefd4d18c297a6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [instrumentById].
@ProviderFor(instrumentById)
const instrumentByIdProvider = InstrumentByIdFamily();

/// See also [instrumentById].
class InstrumentByIdFamily extends Family<AsyncValue<Instrument>> {
  /// See also [instrumentById].
  const InstrumentByIdFamily();

  /// See also [instrumentById].
  InstrumentByIdProvider call(String id) {
    return InstrumentByIdProvider(id);
  }

  @override
  InstrumentByIdProvider getProviderOverride(
    covariant InstrumentByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'instrumentByIdProvider';
}

/// See also [instrumentById].
class InstrumentByIdProvider extends AutoDisposeFutureProvider<Instrument> {
  /// See also [instrumentById].
  InstrumentByIdProvider(String id)
    : this._internal(
        (ref) => instrumentById(ref as InstrumentByIdRef, id),
        from: instrumentByIdProvider,
        name: r'instrumentByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$instrumentByIdHash,
        dependencies: InstrumentByIdFamily._dependencies,
        allTransitiveDependencies:
            InstrumentByIdFamily._allTransitiveDependencies,
        id: id,
      );

  InstrumentByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Instrument> Function(InstrumentByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InstrumentByIdProvider._internal(
        (ref) => create(ref as InstrumentByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Instrument> createElement() {
    return _InstrumentByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InstrumentByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InstrumentByIdRef on AutoDisposeFutureProviderRef<Instrument> {
  /// The parameter `id` of this provider.
  String get id;
}

class _InstrumentByIdProviderElement
    extends AutoDisposeFutureProviderElement<Instrument>
    with InstrumentByIdRef {
  _InstrumentByIdProviderElement(super.provider);

  @override
  String get id => (origin as InstrumentByIdProvider).id;
}

String _$lastAdministeredHash() => r'1444c7af4fc2eb498c613114def07ab5403e4185';

/// See also [lastAdministered].
@ProviderFor(lastAdministered)
const lastAdministeredProvider = LastAdministeredFamily();

/// See also [lastAdministered].
class LastAdministeredFamily extends Family<AsyncValue<DateTime?>> {
  /// See also [lastAdministered].
  const LastAdministeredFamily();

  /// See also [lastAdministered].
  LastAdministeredProvider call(String instrumentId) {
    return LastAdministeredProvider(instrumentId);
  }

  @override
  LastAdministeredProvider getProviderOverride(
    covariant LastAdministeredProvider provider,
  ) {
    return call(provider.instrumentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lastAdministeredProvider';
}

/// See also [lastAdministered].
class LastAdministeredProvider extends AutoDisposeFutureProvider<DateTime?> {
  /// See also [lastAdministered].
  LastAdministeredProvider(String instrumentId)
    : this._internal(
        (ref) => lastAdministered(ref as LastAdministeredRef, instrumentId),
        from: lastAdministeredProvider,
        name: r'lastAdministeredProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$lastAdministeredHash,
        dependencies: LastAdministeredFamily._dependencies,
        allTransitiveDependencies:
            LastAdministeredFamily._allTransitiveDependencies,
        instrumentId: instrumentId,
      );

  LastAdministeredProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.instrumentId,
  }) : super.internal();

  final String instrumentId;

  @override
  Override overrideWith(
    FutureOr<DateTime?> Function(LastAdministeredRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LastAdministeredProvider._internal(
        (ref) => create(ref as LastAdministeredRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        instrumentId: instrumentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DateTime?> createElement() {
    return _LastAdministeredProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LastAdministeredProvider &&
        other.instrumentId == instrumentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, instrumentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LastAdministeredRef on AutoDisposeFutureProviderRef<DateTime?> {
  /// The parameter `instrumentId` of this provider.
  String get instrumentId;
}

class _LastAdministeredProviderElement
    extends AutoDisposeFutureProviderElement<DateTime?>
    with LastAdministeredRef {
  _LastAdministeredProviderElement(super.provider);

  @override
  String get instrumentId => (origin as LastAdministeredProvider).instrumentId;
}

String _$totalEventCountHash() => r'b15638d906a1b99eefc405c3c351e0be01f7ce6e';

/// See also [totalEventCount].
@ProviderFor(totalEventCount)
final totalEventCountProvider = AutoDisposeStreamProvider<int>.internal(
  totalEventCount,
  name: r'totalEventCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalEventCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalEventCountRef = AutoDisposeStreamProviderRef<int>;
String _$recentEventsHash() => r'ebc70d493034387b4b832f6a1d0a2c749001e578';

/// See also [recentEvents].
@ProviderFor(recentEvents)
const recentEventsProvider = RecentEventsFamily();

/// See also [recentEvents].
class RecentEventsFamily extends Family<AsyncValue<List<Event>>> {
  /// See also [recentEvents].
  const RecentEventsFamily();

  /// See also [recentEvents].
  RecentEventsProvider call({int limit = 100}) {
    return RecentEventsProvider(limit: limit);
  }

  @override
  RecentEventsProvider getProviderOverride(
    covariant RecentEventsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recentEventsProvider';
}

/// See also [recentEvents].
class RecentEventsProvider extends AutoDisposeStreamProvider<List<Event>> {
  /// See also [recentEvents].
  RecentEventsProvider({int limit = 100})
    : this._internal(
        (ref) => recentEvents(ref as RecentEventsRef, limit: limit),
        from: recentEventsProvider,
        name: r'recentEventsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recentEventsHash,
        dependencies: RecentEventsFamily._dependencies,
        allTransitiveDependencies:
            RecentEventsFamily._allTransitiveDependencies,
        limit: limit,
      );

  RecentEventsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    Stream<List<Event>> Function(RecentEventsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecentEventsProvider._internal(
        (ref) => create(ref as RecentEventsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Event>> createElement() {
    return _RecentEventsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecentEventsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecentEventsRef on AutoDisposeStreamProviderRef<List<Event>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _RecentEventsProviderElement
    extends AutoDisposeStreamProviderElement<List<Event>>
    with RecentEventsRef {
  _RecentEventsProviderElement(super.provider);

  @override
  int get limit => (origin as RecentEventsProvider).limit;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
