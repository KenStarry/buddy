// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Swap point between the Hive store and the in-memory one.
/// `return TransactionsMemoryRepository();` drives the whole UI off the demo
/// ledger without touching disk.

@ProviderFor(transactionsRepository)
final transactionsRepositoryProvider = TransactionsRepositoryProvider._();

/// Swap point between the Hive store and the in-memory one.
/// `return TransactionsMemoryRepository();` drives the whole UI off the demo
/// ledger without touching disk.

final class TransactionsRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionsRepository,
          TransactionsRepository,
          TransactionsRepository
        >
    with $Provider<TransactionsRepository> {
  /// Swap point between the Hive store and the in-memory one.
  /// `return TransactionsMemoryRepository();` drives the whole UI off the demo
  /// ledger without touching disk.
  TransactionsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionsRepository create(Ref ref) {
    return transactionsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionsRepository>(value),
    );
  }
}

String _$transactionsRepositoryHash() =>
    r'6c456b838630cf214638f1d8ef8e06642e2588a2';
