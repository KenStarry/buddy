// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The currency every cross-wallet total is expressed in.

@ProviderFor(baseCurrency)
final baseCurrencyProvider = BaseCurrencyProvider._();

/// The currency every cross-wallet total is expressed in.

final class BaseCurrencyProvider
    extends $FunctionalProvider<Currency, Currency, Currency>
    with $Provider<Currency> {
  /// The currency every cross-wallet total is expressed in.
  BaseCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baseCurrencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baseCurrencyHash();

  @$internal
  @override
  $ProviderElement<Currency> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Currency create(Ref ref) {
    return baseCurrency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Currency value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Currency>(value),
    );
  }
}

String _$baseCurrencyHash() => r'5913825671baaf5a7168b1daeb074b3e3ed163d3';

/// The whole ledger, newest first. Every provider below derives from this one
/// list, which is what keeps the home screen, the budget cards and the reports
/// page agreeing about the same month.

@ProviderFor(ledger)
final ledgerProvider = LedgerProvider._();

/// The whole ledger, newest first. Every provider below derives from this one
/// list, which is what keeps the home screen, the budget cards and the reports
/// page agreeing about the same month.

final class LedgerProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  /// The whole ledger, newest first. Every provider below derives from this one
  /// list, which is what keeps the home screen, the budget cards and the reports
  /// page agreeing about the same month.
  LedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerHash();

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    return ledger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }
}

String _$ledgerHash() => r'74bd8f3607ba1868a4e250da93a5d2b127564d7f';

@ProviderFor(accountBalances)
final accountBalancesProvider = AccountBalancesProvider._();

final class AccountBalancesProvider
    extends
        $FunctionalProvider<
          List<AccountBalance>,
          List<AccountBalance>,
          List<AccountBalance>
        >
    with $Provider<List<AccountBalance>> {
  AccountBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountBalancesHash();

  @$internal
  @override
  $ProviderElement<List<AccountBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<AccountBalance> create(Ref ref) {
    return accountBalances(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AccountBalance> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AccountBalance>>(value),
    );
  }
}

String _$accountBalancesHash() => r'fc67ed70a447686ddf76ac12262b2eec7f64aa11';

@ProviderFor(netWorth)
final netWorthProvider = NetWorthProvider._();

final class NetWorthProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  NetWorthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return netWorth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$netWorthHash() => r'd871c94776f853079b1a8fa931711902bf0f3cd9';

/// Net worth over the last [days] days, oldest first.

@ProviderFor(netWorthSeries)
final netWorthSeriesProvider = NetWorthSeriesFamily._();

/// Net worth over the last [days] days, oldest first.

final class NetWorthSeriesProvider
    extends
        $FunctionalProvider<
          List<SeriesPoint>,
          List<SeriesPoint>,
          List<SeriesPoint>
        >
    with $Provider<List<SeriesPoint>> {
  /// Net worth over the last [days] days, oldest first.
  NetWorthSeriesProvider._({
    required NetWorthSeriesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'netWorthSeriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$netWorthSeriesHash();

  @override
  String toString() {
    return r'netWorthSeriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<SeriesPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SeriesPoint> create(Ref ref) {
    final argument = this.argument as int;
    return netWorthSeries(ref, days: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SeriesPoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SeriesPoint>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthSeriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$netWorthSeriesHash() => r'f6d83f9ee6ca141f1e5b4dd32157c0277f360ac5';

/// Net worth over the last [days] days, oldest first.

final class NetWorthSeriesFamily extends $Family
    with $FunctionalFamilyOverride<List<SeriesPoint>, int> {
  NetWorthSeriesFamily._()
    : super(
        retry: null,
        name: r'netWorthSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Net worth over the last [days] days, oldest first.

  NetWorthSeriesProvider call({int days = 90}) =>
      NetWorthSeriesProvider._(argument: days, from: this);

  @override
  String toString() => r'netWorthSeriesProvider';
}

/// Net worth now against [days] ago, as a **signed fraction** of the earlier
/// figure — the "↗ 2.4% this month" read on the header.
///
/// Null rather than zero whenever the comparison would be dishonest: too few
/// points to compare, or a starting net worth of zero (every change from zero
/// is an infinite percentage, and rendering it as a number is how a brand-new
/// user is told their wealth grew by 12,400%).

@ProviderFor(netWorthTrend)
final netWorthTrendProvider = NetWorthTrendFamily._();

/// Net worth now against [days] ago, as a **signed fraction** of the earlier
/// figure — the "↗ 2.4% this month" read on the header.
///
/// Null rather than zero whenever the comparison would be dishonest: too few
/// points to compare, or a starting net worth of zero (every change from zero
/// is an infinite percentage, and rendering it as a number is how a brand-new
/// user is told their wealth grew by 12,400%).

final class NetWorthTrendProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
  /// Net worth now against [days] ago, as a **signed fraction** of the earlier
  /// figure — the "↗ 2.4% this month" read on the header.
  ///
  /// Null rather than zero whenever the comparison would be dishonest: too few
  /// points to compare, or a starting net worth of zero (every change from zero
  /// is an infinite percentage, and rendering it as a number is how a brand-new
  /// user is told their wealth grew by 12,400%).
  NetWorthTrendProvider._({
    required NetWorthTrendFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'netWorthTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$netWorthTrendHash();

  @override
  String toString() {
    return r'netWorthTrendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    final argument = this.argument as int;
    return netWorthTrend(ref, days: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$netWorthTrendHash() => r'efea8175f1f48c6e28dfd9a76d35bd05d65f516d';

/// Net worth now against [days] ago, as a **signed fraction** of the earlier
/// figure — the "↗ 2.4% this month" read on the header.
///
/// Null rather than zero whenever the comparison would be dishonest: too few
/// points to compare, or a starting net worth of zero (every change from zero
/// is an infinite percentage, and rendering it as a number is how a brand-new
/// user is told their wealth grew by 12,400%).

final class NetWorthTrendFamily extends $Family
    with $FunctionalFamilyOverride<double?, int> {
  NetWorthTrendFamily._()
    : super(
        retry: null,
        name: r'netWorthTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Net worth now against [days] ago, as a **signed fraction** of the earlier
  /// figure — the "↗ 2.4% this month" read on the header.
  ///
  /// Null rather than zero whenever the comparison would be dishonest: too few
  /// points to compare, or a starting net worth of zero (every change from zero
  /// is an infinite percentage, and rendering it as a number is how a brand-new
  /// user is told their wealth grew by 12,400%).

  NetWorthTrendProvider call({int days = 30}) =>
      NetWorthTrendProvider._(argument: days, from: this);

  @override
  String toString() => r'netWorthTrendProvider';
}

@ProviderFor(spendingPulse)
final spendingPulseProvider = SpendingPulseProvider._();

final class SpendingPulseProvider
    extends $FunctionalProvider<SpendingPulse, SpendingPulse, SpendingPulse>
    with $Provider<SpendingPulse> {
  SpendingPulseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'spendingPulseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spendingPulseHash();

  @$internal
  @override
  $ProviderElement<SpendingPulse> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpendingPulse create(Ref ref) {
    return spendingPulse(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpendingPulse value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpendingPulse>(value),
    );
  }
}

String _$spendingPulseHash() => r'94f7ed4df08a9f0abc15d569619f2497d942220d';

/// Every budget's current window, in the user's order.

@ProviderFor(budgetProgressList)
final budgetProgressListProvider = BudgetProgressListProvider._();

/// Every budget's current window, in the user's order.

final class BudgetProgressListProvider
    extends
        $FunctionalProvider<
          List<BudgetProgress>,
          List<BudgetProgress>,
          List<BudgetProgress>
        >
    with $Provider<List<BudgetProgress>> {
  /// Every budget's current window, in the user's order.
  BudgetProgressListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetProgressListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetProgressListHash();

  @$internal
  @override
  $ProviderElement<List<BudgetProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<BudgetProgress> create(Ref ref) {
    return budgetProgressList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BudgetProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BudgetProgress>>(value),
    );
  }
}

String _$budgetProgressListHash() =>
    r'ab826bb81637ee5a8f1d62d77e7b1e900c62f25c';

@ProviderFor(pinnedBudgetProgress)
final pinnedBudgetProgressProvider = PinnedBudgetProgressProvider._();

final class PinnedBudgetProgressProvider
    extends
        $FunctionalProvider<
          List<BudgetProgress>,
          List<BudgetProgress>,
          List<BudgetProgress>
        >
    with $Provider<List<BudgetProgress>> {
  PinnedBudgetProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedBudgetProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedBudgetProgressHash();

  @$internal
  @override
  $ProviderElement<List<BudgetProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<BudgetProgress> create(Ref ref) {
    return pinnedBudgetProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BudgetProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BudgetProgress>>(value),
    );
  }
}

String _$pinnedBudgetProgressHash() =>
    r'ba424a50a035c819796c769b0bdfc9c44558fcc4';

/// One budget's current window. Null once the budget is deleted — callers on
/// a detail route must handle that rather than assume it is still there.

@ProviderFor(budgetProgress)
final budgetProgressProvider = BudgetProgressFamily._();

/// One budget's current window. Null once the budget is deleted — callers on
/// a detail route must handle that rather than assume it is still there.

final class BudgetProgressProvider
    extends
        $FunctionalProvider<BudgetProgress?, BudgetProgress?, BudgetProgress?>
    with $Provider<BudgetProgress?> {
  /// One budget's current window. Null once the budget is deleted — callers on
  /// a detail route must handle that rather than assume it is still there.
  BudgetProgressProvider._({
    required BudgetProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'budgetProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetProgressHash();

  @override
  String toString() {
    return r'budgetProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<BudgetProgress?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetProgress? create(Ref ref) {
    final argument = this.argument as String;
    return budgetProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetProgressHash() => r'97a85be238c5df45e9aedc96c6a3aeb143b7796b';

/// One budget's current window. Null once the budget is deleted — callers on
/// a detail route must handle that rather than assume it is still there.

final class BudgetProgressFamily extends $Family
    with $FunctionalFamilyOverride<BudgetProgress?, String> {
  BudgetProgressFamily._()
    : super(
        retry: null,
        name: r'budgetProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One budget's current window. Null once the budget is deleted — callers on
  /// a detail route must handle that rather than assume it is still there.

  BudgetProgressProvider call(String budgetId) =>
      BudgetProgressProvider._(argument: budgetId, from: this);

  @override
  String toString() => r'budgetProgressProvider';
}

/// The current window plus the previous [count] − 1, newest first.

@ProviderFor(budgetHistory)
final budgetHistoryProvider = BudgetHistoryFamily._();

/// The current window plus the previous [count] − 1, newest first.

final class BudgetHistoryProvider
    extends
        $FunctionalProvider<
          List<BudgetProgress>,
          List<BudgetProgress>,
          List<BudgetProgress>
        >
    with $Provider<List<BudgetProgress>> {
  /// The current window plus the previous [count] − 1, newest first.
  BudgetHistoryProvider._({
    required BudgetHistoryFamily super.from,
    required (String, {int count}) super.argument,
  }) : super(
         retry: null,
         name: r'budgetHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetHistoryHash();

  @override
  String toString() {
    return r'budgetHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<BudgetProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<BudgetProgress> create(Ref ref) {
    final argument = this.argument as (String, {int count});
    return budgetHistory(ref, argument.$1, count: argument.count);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BudgetProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BudgetProgress>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetHistoryHash() => r'16fff0c219993a4e8bee96d212ff1f30f5e51891';

/// The current window plus the previous [count] − 1, newest first.

final class BudgetHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<List<BudgetProgress>, (String, {int count})> {
  BudgetHistoryFamily._()
    : super(
        retry: null,
        name: r'budgetHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The current window plus the previous [count] − 1, newest first.

  BudgetHistoryProvider call(String budgetId, {int count = 6}) =>
      BudgetHistoryProvider._(argument: (budgetId, count: count), from: this);

  @override
  String toString() => r'budgetHistoryProvider';
}

@ProviderFor(goalProgressList)
final goalProgressListProvider = GoalProgressListProvider._();

final class GoalProgressListProvider
    extends
        $FunctionalProvider<
          List<GoalProgress>,
          List<GoalProgress>,
          List<GoalProgress>
        >
    with $Provider<List<GoalProgress>> {
  GoalProgressListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalProgressListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalProgressListHash();

  @$internal
  @override
  $ProviderElement<List<GoalProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<GoalProgress> create(Ref ref) {
    return goalProgressList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<GoalProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<GoalProgress>>(value),
    );
  }
}

String _$goalProgressListHash() => r'7f6043c7a760125c973d527441c201fb8687b096';

@ProviderFor(pinnedGoalProgress)
final pinnedGoalProgressProvider = PinnedGoalProgressProvider._();

final class PinnedGoalProgressProvider
    extends
        $FunctionalProvider<
          List<GoalProgress>,
          List<GoalProgress>,
          List<GoalProgress>
        >
    with $Provider<List<GoalProgress>> {
  PinnedGoalProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedGoalProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedGoalProgressHash();

  @$internal
  @override
  $ProviderElement<List<GoalProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<GoalProgress> create(Ref ref) {
    return pinnedGoalProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<GoalProgress> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<GoalProgress>>(value),
    );
  }
}

String _$pinnedGoalProgressHash() =>
    r'4ab766af3e3f2be8dde9cd21a62b80fbc5175e88';

@ProviderFor(goalProgress)
final goalProgressProvider = GoalProgressFamily._();

final class GoalProgressProvider
    extends $FunctionalProvider<GoalProgress?, GoalProgress?, GoalProgress?>
    with $Provider<GoalProgress?> {
  GoalProgressProvider._({
    required GoalProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalProgressHash();

  @override
  String toString() {
    return r'goalProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<GoalProgress?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalProgress? create(Ref ref) {
    final argument = this.argument as String;
    return goalProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalProgress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalProgressHash() => r'598e78d3c2f117a40c8f857f2ecd54492fe931e3';

final class GoalProgressFamily extends $Family
    with $FunctionalFamilyOverride<GoalProgress?, String> {
  GoalProgressFamily._()
    : super(
        retry: null,
        name: r'goalProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoalProgressProvider call(String goalId) =>
      GoalProgressProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalProgressProvider';
}

/// In / out / kept for the calendar month containing today.

@ProviderFor(monthTotals)
final monthTotalsProvider = MonthTotalsProvider._();

/// In / out / kept for the calendar month containing today.

final class MonthTotalsProvider
    extends $FunctionalProvider<PeriodTotals, PeriodTotals, PeriodTotals>
    with $Provider<PeriodTotals> {
  /// In / out / kept for the calendar month containing today.
  MonthTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthTotalsHash();

  @$internal
  @override
  $ProviderElement<PeriodTotals> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PeriodTotals create(Ref ref) {
    return monthTotals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PeriodTotals value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PeriodTotals>(value),
    );
  }
}

String _$monthTotalsHash() => r'98a6e68d1fe73fc19c325ec2e7a468efff79057f';

/// The last [months] calendar months, oldest first. Feeds the reports page's
/// in-vs-out diverging columns.

@ProviderFor(monthlyTotals)
final monthlyTotalsProvider = MonthlyTotalsFamily._();

/// The last [months] calendar months, oldest first. Feeds the reports page's
/// in-vs-out diverging columns.

final class MonthlyTotalsProvider
    extends
        $FunctionalProvider<
          List<({DateTime month, PeriodTotals totals})>,
          List<({DateTime month, PeriodTotals totals})>,
          List<({DateTime month, PeriodTotals totals})>
        >
    with $Provider<List<({DateTime month, PeriodTotals totals})>> {
  /// The last [months] calendar months, oldest first. Feeds the reports page's
  /// in-vs-out diverging columns.
  MonthlyTotalsProvider._({
    required MonthlyTotalsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'monthlyTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyTotalsHash();

  @override
  String toString() {
    return r'monthlyTotalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<({DateTime month, PeriodTotals totals})>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  List<({DateTime month, PeriodTotals totals})> create(Ref ref) {
    final argument = this.argument as int;
    return monthlyTotals(ref, months: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    List<({DateTime month, PeriodTotals totals})> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<List<({DateTime month, PeriodTotals totals})>>(
            value,
          ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyTotalsHash() => r'734831c801adc6a75468358e382faad7e39e36a9';

/// The last [months] calendar months, oldest first. Feeds the reports page's
/// in-vs-out diverging columns.

final class MonthlyTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<({DateTime month, PeriodTotals totals})>,
          int
        > {
  MonthlyTotalsFamily._()
    : super(
        retry: null,
        name: r'monthlyTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The last [months] calendar months, oldest first. Feeds the reports page's
  /// in-vs-out diverging columns.

  MonthlyTotalsProvider call({int months = 6}) =>
      MonthlyTotalsProvider._(argument: months, from: this);

  @override
  String toString() => r'monthlyTotalsProvider';
}

/// Spend by category for the **pulse's own window**, so the home screen's
/// breakdown covers exactly the period its headline number does. A breakdown
/// over the calendar month beside a headline over a 15th-anchored budget is
/// two different months stacked on one screen.

@ProviderFor(pulseSpendByCategory)
final pulseSpendByCategoryProvider = PulseSpendByCategoryProvider._();

/// Spend by category for the **pulse's own window**, so the home screen's
/// breakdown covers exactly the period its headline number does. A breakdown
/// over the calendar month beside a headline over a 15th-anchored budget is
/// two different months stacked on one screen.

final class PulseSpendByCategoryProvider
    extends
        $FunctionalProvider<
          List<CategorySpend>,
          List<CategorySpend>,
          List<CategorySpend>
        >
    with $Provider<List<CategorySpend>> {
  /// Spend by category for the **pulse's own window**, so the home screen's
  /// breakdown covers exactly the period its headline number does. A breakdown
  /// over the calendar month beside a headline over a 15th-anchored budget is
  /// two different months stacked on one screen.
  PulseSpendByCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pulseSpendByCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pulseSpendByCategoryHash();

  @$internal
  @override
  $ProviderElement<List<CategorySpend>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategorySpend> create(Ref ref) {
    return pulseSpendByCategory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategorySpend> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategorySpend>>(value),
    );
  }
}

String _$pulseSpendByCategoryHash() =>
    r'829515e934e4b0a897a6c970901e8b109269fd73';

/// Spend by category over the last [days] days.

@ProviderFor(spendByCategory)
final spendByCategoryProvider = SpendByCategoryFamily._();

/// Spend by category over the last [days] days.

final class SpendByCategoryProvider
    extends
        $FunctionalProvider<
          List<CategorySpend>,
          List<CategorySpend>,
          List<CategorySpend>
        >
    with $Provider<List<CategorySpend>> {
  /// Spend by category over the last [days] days.
  SpendByCategoryProvider._({
    required SpendByCategoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'spendByCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$spendByCategoryHash();

  @override
  String toString() {
    return r'spendByCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<CategorySpend>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategorySpend> create(Ref ref) {
    final argument = this.argument as int;
    return spendByCategory(ref, days: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategorySpend> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategorySpend>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpendByCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spendByCategoryHash() => r'2cc22c4591044f09a194389c9259c9b9b54fcf9b';

/// Spend by category over the last [days] days.

final class SpendByCategoryFamily extends $Family
    with $FunctionalFamilyOverride<List<CategorySpend>, int> {
  SpendByCategoryFamily._()
    : super(
        retry: null,
        name: r'spendByCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Spend by category over the last [days] days.

  SpendByCategoryProvider call({int days = 30}) =>
      SpendByCategoryProvider._(argument: days, from: this);

  @override
  String toString() => r'spendByCategoryProvider';
}

/// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.

@ProviderFor(dailySpend)
final dailySpendProvider = DailySpendFamily._();

/// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.

final class DailySpendProvider
    extends
        $FunctionalProvider<
          List<SeriesPoint>,
          List<SeriesPoint>,
          List<SeriesPoint>
        >
    with $Provider<List<SeriesPoint>> {
  /// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.
  DailySpendProvider._({
    required DailySpendFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'dailySpendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailySpendHash();

  @override
  String toString() {
    return r'dailySpendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<SeriesPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SeriesPoint> create(Ref ref) {
    final argument = this.argument as int;
    return dailySpend(ref, days: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SeriesPoint> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SeriesPoint>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailySpendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailySpendHash() => r'6109a8c29ae2b4c0dab520d00428624b4c4b6dd0';

/// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.

final class DailySpendFamily extends $Family
    with $FunctionalFamilyOverride<List<SeriesPoint>, int> {
  DailySpendFamily._()
    : super(
        retry: null,
        name: r'dailySpendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.

  DailySpendProvider call({int days = 84}) =>
      DailySpendProvider._(argument: days, from: this);

  @override
  String toString() => r'dailySpendProvider';
}

@ProviderFor(overdueTransactions)
final overdueTransactionsProvider = OverdueTransactionsProvider._();

final class OverdueTransactionsProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  OverdueTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overdueTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overdueTransactionsHash();

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    return overdueTransactions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }
}

String _$overdueTransactionsHash() =>
    r'434b7b86c98735dc78a616050f152163803b1856';

@ProviderFor(upcomingTransactions)
final upcomingTransactionsProvider = UpcomingTransactionsFamily._();

final class UpcomingTransactionsProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  UpcomingTransactionsProvider._({
    required UpcomingTransactionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'upcomingTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$upcomingTransactionsHash();

  @override
  String toString() {
    return r'upcomingTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    final argument = this.argument as int;
    return upcomingTransactions(ref, withinDays: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingTransactionsHash() =>
    r'd3a333dd32490776839fd867f8c545a12a7e3352';

final class UpcomingTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<List<TransactionModel>, int> {
  UpcomingTransactionsFamily._()
    : super(
        retry: null,
        name: r'upcomingTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UpcomingTransactionsProvider call({int withinDays = 30}) =>
      UpcomingTransactionsProvider._(argument: withinDays, from: this);

  @override
  String toString() => r'upcomingTransactionsProvider';
}

@ProviderFor(openLoans)
final openLoansProvider = OpenLoansProvider._();

final class OpenLoansProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  OpenLoansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openLoansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openLoansHash();

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    return openLoans(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }
}

String _$openLoansHash() => r'297f81bad04b5c8b2574531762ea043eec19410a';

@ProviderFor(recurringTransactions)
final recurringTransactionsProvider = RecurringTransactionsProvider._();

final class RecurringTransactionsProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  RecurringTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringTransactionsHash();

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    return recurringTransactions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }
}

String _$recurringTransactionsHash() =>
    r'fed0162acb44ab6c622c8e50788f959ad61978ea';

/// Net position on open loans, in base currency.
///
/// Read as: `inflowMinor` is owed **to** you, `outflowMinor` is what you owe,
/// and `netMinor` is the net — positive means you are a creditor.

@ProviderFor(loanPosition)
final loanPositionProvider = LoanPositionProvider._();

/// Net position on open loans, in base currency.
///
/// Read as: `inflowMinor` is owed **to** you, `outflowMinor` is what you owe,
/// and `netMinor` is the net — positive means you are a creditor.

final class LoanPositionProvider
    extends $FunctionalProvider<PeriodTotals, PeriodTotals, PeriodTotals>
    with $Provider<PeriodTotals> {
  /// Net position on open loans, in base currency.
  ///
  /// Read as: `inflowMinor` is owed **to** you, `outflowMinor` is what you owe,
  /// and `netMinor` is the net — positive means you are a creditor.
  LoanPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanPositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanPositionHash();

  @$internal
  @override
  $ProviderElement<PeriodTotals> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PeriodTotals create(Ref ref) {
    return loanPosition(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PeriodTotals value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PeriodTotals>(value),
    );
  }
}

String _$loanPositionHash() => r'8c528683433fca2bda4ee94e8e21b31c31fa1738';

@ProviderFor(recentTransactions)
final recentTransactionsProvider = RecentTransactionsFamily._();

final class RecentTransactionsProvider
    extends
        $FunctionalProvider<
          List<TransactionModel>,
          List<TransactionModel>,
          List<TransactionModel>
        >
    with $Provider<List<TransactionModel>> {
  RecentTransactionsProvider._({
    required RecentTransactionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recentTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentTransactionsHash();

  @override
  String toString() {
    return r'recentTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<TransactionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransactionModel> create(Ref ref) {
    final argument = this.argument as int;
    return recentTransactions(ref, limit: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransactionModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransactionModel>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecentTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentTransactionsHash() =>
    r'0ad9bdcfbbb462ff41c9fd33ae8ccf7e89ef0a92';

final class RecentTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<List<TransactionModel>, int> {
  RecentTransactionsFamily._()
    : super(
        retry: null,
        name: r'recentTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecentTransactionsProvider call({int limit = 6}) =>
      RecentTransactionsProvider._(argument: limit, from: this);

  @override
  String toString() => r'recentTransactionsProvider';
}

/// Day-grouped ledger — the shape the transactions list renders from.

@ProviderFor(groupedLedger)
final groupedLedgerProvider = GroupedLedgerProvider._();

/// Day-grouped ledger — the shape the transactions list renders from.

final class GroupedLedgerProvider
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
  /// Day-grouped ledger — the shape the transactions list renders from.
  GroupedLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupedLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupedLedgerHash();

  @$internal
  @override
  $ProviderElement<
    List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
  create(Ref ref) {
    return groupedLedger(ref);
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

String _$groupedLedgerHash() => r'43cb9bc06b8ed4bc9ec077db3a216fe3098336f5';
