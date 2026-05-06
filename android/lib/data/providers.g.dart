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
