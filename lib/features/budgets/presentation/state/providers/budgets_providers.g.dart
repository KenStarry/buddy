// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(budgetsRepository)
final budgetsRepositoryProvider = BudgetsRepositoryProvider._();

final class BudgetsRepositoryProvider
    extends
        $FunctionalProvider<
          BudgetsRepository,
          BudgetsRepository,
          BudgetsRepository
        >
    with $Provider<BudgetsRepository> {
  BudgetsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsRepositoryHash();

  @$internal
  @override
  $ProviderElement<BudgetsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BudgetsRepository create(Ref ref) {
    return budgetsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetsRepository>(value),
    );
  }
}

String _$budgetsRepositoryHash() => r'03e72986edb616ab274c6a9578dfa009d11e1a49';
