// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetsController)
final budgetsControllerProvider = BudgetsControllerProvider._();

final class BudgetsControllerProvider
    extends $NotifierProvider<BudgetsController, BudgetsState> {
  BudgetsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsControllerHash();

  @$internal
  @override
  BudgetsController create() => BudgetsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetsState>(value),
    );
  }
}

String _$budgetsControllerHash() => r'4f95c392a3d414485a902892b8274d79d79a51b5';

abstract class _$BudgetsController extends $Notifier<BudgetsState> {
  BudgetsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BudgetsState, BudgetsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BudgetsState, BudgetsState>,
              BudgetsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
