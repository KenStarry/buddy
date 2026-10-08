// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoalsController)
final goalsControllerProvider = GoalsControllerProvider._();

final class GoalsControllerProvider
    extends $NotifierProvider<GoalsController, GoalsState> {
  GoalsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsControllerHash();

  @$internal
  @override
  GoalsController create() => GoalsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalsState>(value),
    );
  }
}

String _$goalsControllerHash() => r'48f7b4e915b63db870b037ccf6b59ffc25b11bb8';

abstract class _$GoalsController extends $Notifier<GoalsState> {
  GoalsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GoalsState, GoalsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalsState, GoalsState>,
              GoalsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
