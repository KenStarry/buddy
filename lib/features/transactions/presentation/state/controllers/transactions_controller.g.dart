// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransactionsController)
final transactionsControllerProvider = TransactionsControllerProvider._();

final class TransactionsControllerProvider
    extends $NotifierProvider<TransactionsController, TransactionsState> {
  TransactionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsControllerHash();

  @$internal
  @override
  TransactionsController create() => TransactionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionsState>(value),
    );
  }
}

String _$transactionsControllerHash() =>
    r'6672c3b165586813b7fbad9bd7d69c9cf43bf827';

abstract class _$TransactionsController extends $Notifier<TransactionsState> {
  TransactionsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TransactionsState, TransactionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionsState, TransactionsState>,
              TransactionsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
