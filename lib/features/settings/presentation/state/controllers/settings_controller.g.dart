// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Device preferences.
///
/// Reads Hive directly rather than going through a repository, and that is the
/// one place in Budgy that does. These are not ledger data: they never sync,
/// never merge, and have no server counterpart to abstract over — wrapping six
/// scalar settings in an `Either`-returning contract would buy nothing and
/// make `build()` async for no reason. The ledger aggregates all keep theirs.

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// Device preferences.
///
/// Reads Hive directly rather than going through a repository, and that is the
/// one place in Budgy that does. These are not ledger data: they never sync,
/// never merge, and have no server counterpart to abstract over — wrapping six
/// scalar settings in an `Either`-returning contract would buy nothing and
/// make `build()` async for no reason. The ledger aggregates all keep theirs.
final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, SettingsState> {
  /// Device preferences.
  ///
  /// Reads Hive directly rather than going through a repository, and that is the
  /// one place in Budgy that does. These are not ledger data: they never sync,
  /// never merge, and have no server counterpart to abstract over — wrapping six
  /// scalar settings in an `Either`-returning contract would buy nothing and
  /// make `build()` async for no reason. The ledger aggregates all keep theirs.
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsState>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'cd564c93f48ceed31c9b9709b3b52af62ddf086d';

/// Device preferences.
///
/// Reads Hive directly rather than going through a repository, and that is the
/// one place in Budgy that does. These are not ledger data: they never sync,
/// never merge, and have no server counterpart to abstract over — wrapping six
/// scalar settings in an `Either`-returning contract would buy nothing and
/// make `build()` async for no reason. The ledger aggregates all keep theirs.

abstract class _$SettingsController extends $Notifier<SettingsState> {
  SettingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SettingsState, SettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettingsState, SettingsState>,
              SettingsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
