import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../modules/ledger/domain/ledger_math.dart';
import '../../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../domain/enum/transaction_type.dart';
import '../../../domain/model/transaction_filter.dart';
import '../../../domain/model/transaction_model.dart';

part 'ledger_filter_controller.g.dart';

/// The Ledger screen's filter.
///
/// `autoDispose` — deliberately. A filter is a *view* of the ledger, not a
/// setting: leaving the screen and coming back should show the whole ledger
/// again, not a search from twenty minutes ago that makes the app look empty.
@riverpod
class LedgerFilterController extends _$LedgerFilterController {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleType(TransactionType type) => state = state.copyWith(
    types: _toggled(state.types, type),
  );

  void toggleNature(TransactionNature nature) => state = state.copyWith(
    natures: _toggled(state.natures, nature),
  );

  void toggleCategory(String id) =>
      state = state.copyWith(categoryIds: _toggled(state.categoryIds, id));

  void toggleAccount(String id) =>
      state = state.copyWith(accountIds: _toggled(state.accountIds, id));

  void setRange(DateTime? from, DateTime? to) => state = state.copyWith(
    from: from,
    clearFrom: from == null,
    to: to,
    clearTo: to == null,
  );

  void setAmountRange(int? min, int? max) => state = state.copyWith(
    minMinor: min,
    clearMin: min == null,
    maxMinor: max,
    clearMax: max == null,
  );

  void setOnlyUnsettled(bool value) =>
      state = state.copyWith(onlyUnsettled: value);

  void clear() => state = const TransactionFilter();

  /// Clears everything **except** the query, for the sheet's "Reset" button —
  /// resetting the filters should not wipe what the user typed in the search
  /// box above them.
  void clearFilters() => state = TransactionFilter(query: state.query);

  static Set<T> _toggled<T>(Set<T> set, T value) {
    final next = {...set};
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }
}

/// The filtered, day-grouped ledger the screen renders.
@riverpod
List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
filteredLedger(Ref ref) {
  final filter = ref.watch(ledgerFilterControllerProvider);
  final all = ref.watch(ledgerProvider);
  final base = ref.watch(baseCurrencyProvider);
  if (!filter.isActive) return LedgerMath.groupByDay(all, base);
  return LedgerMath.groupByDay(
    [for (final t in all) if (filter.matches(t)) t],
    base,
  );
}

/// Totals across everything currently matched — the "what am I looking at"
/// summary above a filtered list.
@riverpod
PeriodTotals filteredTotals(Ref ref) {
  final filter = ref.watch(ledgerFilterControllerProvider);
  final all = ref.watch(ledgerProvider);
  final base = ref.watch(baseCurrencyProvider);
  final rows = filter.isActive
      ? [for (final t in all) if (filter.matches(t)) t]
      : all;
  return LedgerMath.totals(rows, base);
}

/// Count of matched rows, for the header.
@riverpod
int filteredCount(Ref ref) {
  final groups = ref.watch(filteredLedgerProvider);
  return groups.fold(0, (sum, g) => sum + g.rows.length);
}
