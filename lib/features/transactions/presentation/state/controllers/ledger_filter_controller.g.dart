// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_filter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Ledger screen's filter.
///
/// `autoDispose` — deliberately. A filter is a *view* of the ledger, not a
/// setting: leaving the screen and coming back should show the whole ledger
/// again, not a search from twenty minutes ago that makes the app look empty.

@ProviderFor(LedgerFilterController)
final ledgerFilterControllerProvider = LedgerFilterControllerProvider._();

/// The Ledger screen's filter.
///
/// `autoDispose` — deliberately. A filter is a *view* of the ledger, not a
/// setting: leaving the screen and coming back should show the whole ledger
/// again, not a search from twenty minutes ago that makes the app look empty.
final class LedgerFilterControllerProvider
    extends $NotifierProvider<LedgerFilterController, TransactionFilter> {
  /// The Ledger screen's filter.
  ///
  /// `autoDispose` — deliberately. A filter is a *view* of the ledger, not a
  /// setting: leaving the screen and coming back should show the whole ledger
  /// again, not a search from twenty minutes ago that makes the app look empty.
  LedgerFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerFilterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerFilterControllerHash();

  @$internal
  @override
  LedgerFilterController create() => LedgerFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFilter>(value),
    );
  }
}

String _$ledgerFilterControllerHash() =>
    r'3e858fa19378914c9808bbb49efc6a9c5a406daa';

/// The Ledger screen's filter.
///
/// `autoDispose` — deliberately. A filter is a *view* of the ledger, not a
/// setting: leaving the screen and coming back should show the whole ledger
/// again, not a search from twenty minutes ago that makes the app look empty.

abstract class _$LedgerFilterController extends $Notifier<TransactionFilter> {
  TransactionFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TransactionFilter, TransactionFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFilter, TransactionFilter>,
              TransactionFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The filtered, day-grouped ledger the screen renders.

@ProviderFor(filteredLedger)
final filteredLedgerProvider = FilteredLedgerProvider._();

/// The filtered, day-grouped ledger the screen renders.

final class FilteredLedgerProvider
    extends
        $FunctionalProvider<
          List<
            ({DateTime day, List<TransactionModel> rows, PeriodTotals totals})
          >,
          List<
            ({DateTime day, List<TransactionModel> rows, PeriodTotals totals})
          >,
          List<
            ({DateTime day, List<TransactionModel> rows, PeriodTotals totals})
          >
        >
    with
        $Provider<
          List<
            ({DateTime day, List<TransactionModel> rows, PeriodTotals totals})
          >
        > {
  /// The filtered, day-grouped ledger the screen renders.
  FilteredLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredLedgerHash();

  @$internal
  @override
  $ProviderElement<
    List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
  create(Ref ref) {
    return filteredLedger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            List<
              ({DateTime day, List<TransactionModel> rows, PeriodTotals totals})
            >
          >(value),
    );
  }
}

String _$filteredLedgerHash() => r'f8e63fd9f8c0866d9792037dbde23d920ecd2258';

/// Totals across everything currently matched — the "what am I looking at"
/// summary above a filtered list.

@ProviderFor(filteredTotals)
final filteredTotalsProvider = FilteredTotalsProvider._();

/// Totals across everything currently matched — the "what am I looking at"
/// summary above a filtered list.

final class FilteredTotalsProvider
    extends $FunctionalProvider<PeriodTotals, PeriodTotals, PeriodTotals>
    with $Provider<PeriodTotals> {
  /// Totals across everything currently matched — the "what am I looking at"
  /// summary above a filtered list.
  FilteredTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredTotalsHash();

  @$internal
  @override
  $ProviderElement<PeriodTotals> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PeriodTotals create(Ref ref) {
    return filteredTotals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PeriodTotals value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PeriodTotals>(value),
    );
  }
}

String _$filteredTotalsHash() => r'cb1d3165783abbf77afbd7e1ea5ad1d2efa33e69';

/// Count of matched rows, for the header.

@ProviderFor(filteredCount)
final filteredCountProvider = FilteredCountProvider._();

/// Count of matched rows, for the header.

final class FilteredCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of matched rows, for the header.
  FilteredCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return filteredCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$filteredCountHash() => r'7c2860e8ca3fdefc5327ab07bfe5422299bafd13';
