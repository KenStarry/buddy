import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/utils/functions/money_format.dart';
import '../../../../features/accounts/presentation/state/controllers/accounts_controller.dart';
import '../../../../features/budgets/domain/enum/budget_period.dart';
import '../../../../features/budgets/presentation/state/controllers/budgets_controller.dart';
import '../../../../features/goals/presentation/state/controllers/goals_controller.dart';
import '../../../../features/settings/presentation/state/controllers/settings_controller.dart';
import '../../../../features/transactions/domain/enum/transaction_type.dart';
import '../../../../features/transactions/domain/model/transaction_model.dart';
import '../../../../features/transactions/presentation/state/controllers/transactions_controller.dart';
import '../../domain/ledger_math.dart';
import '../../domain/ledger_values.dart';

part 'ledger_providers.g.dart';

/// The currency every cross-wallet total is expressed in.
@riverpod
Currency baseCurrency(Ref ref) =>
    ref.watch(settingsControllerProvider).baseCurrency;

/// The whole ledger, newest first. Every provider below derives from this one
/// list, which is what keeps the home screen, the budget cards and the reports
/// page agreeing about the same month.
@riverpod
List<TransactionModel> ledger(Ref ref) =>
    ref.watch(transactionsControllerProvider).items;

// ───────────────────── Wallets & net worth ─────────────────────────────────

@riverpod
List<AccountBalance> accountBalances(Ref ref) => LedgerMath.balances(
  ref.watch(accountsControllerProvider).live,
  ref.watch(ledgerProvider),
  ref.watch(baseCurrencyProvider),
);

@riverpod
int netWorth(Ref ref) => LedgerMath.netWorth(ref.watch(accountBalancesProvider));

/// Net worth over the last [days] days, oldest first.
@riverpod
List<SeriesPoint> netWorthSeries(Ref ref, {int days = 90}) {
  final today = DateTime.now().startOfDay;
  return LedgerMath.netWorthSeries(
    ref.watch(accountsControllerProvider).live,
    ref.watch(ledgerProvider),
    DateTime(today.year, today.month, today.day - (days - 1)),
    today,
    ref.watch(baseCurrencyProvider),
  );
}

/// Net worth now against [days] ago, as a **signed fraction** of the earlier
/// figure — the "↗ 2.4% this month" read on the header.
///
/// Null rather than zero whenever the comparison would be dishonest: too few
/// points to compare, or a starting net worth of zero (every change from zero
/// is an infinite percentage, and rendering it as a number is how a brand-new
/// user is told their wealth grew by 12,400%).
@riverpod
double? netWorthTrend(Ref ref, {int days = 30}) {
  final series = ref.watch(netWorthSeriesProvider(days: days + 1));
  if (series.length < 2) return null;
  final first = series.first.minor;
  if (first == 0) return null;
  return (series.last.minor - first) / first.abs();
}

// ───────────────────── The headline ────────────────────────────────────────

@riverpod
SpendingPulse spendingPulse(Ref ref) => LedgerMath.pulse(
  transactions: ref.watch(ledgerProvider),
  budgets: ref.watch(budgetsControllerProvider).ordered,
  base: ref.watch(baseCurrencyProvider),
);

// ───────────────────── Budgets ─────────────────────────────────────────────

/// Every budget's current window, in the user's order.
@riverpod
List<BudgetProgress> budgetProgressList(Ref ref) {
  final ledger = ref.watch(ledgerProvider);
  return [
    for (final budget in ref.watch(budgetsControllerProvider).ordered)
      LedgerMath.budgetProgress(budget, ledger),
  ];
}

@riverpod
List<BudgetProgress> pinnedBudgetProgress(Ref ref) =>
    [for (final p in ref.watch(budgetProgressListProvider)) if (p.budget.isPinned) p];

/// One budget's current window. Null once the budget is deleted — callers on
/// a detail route must handle that rather than assume it is still there.
@riverpod
BudgetProgress? budgetProgress(Ref ref, String budgetId) {
  final budget = ref.watch(budgetsControllerProvider).byId(budgetId);
  if (budget == null) return null;
  return LedgerMath.budgetProgress(budget, ref.watch(ledgerProvider));
}

/// The current window plus the previous [count] − 1, newest first.
@riverpod
List<BudgetProgress> budgetHistory(
  Ref ref,
  String budgetId, {
  int count = 6,
}) {
  final budget = ref.watch(budgetsControllerProvider).byId(budgetId);
  if (budget == null) return const [];
  return LedgerMath.budgetHistory(
    budget,
    ref.watch(ledgerProvider),
    count: count,
  );
}

// ───────────────────── Goals ───────────────────────────────────────────────

@riverpod
List<GoalProgress> goalProgressList(Ref ref) {
  final ledger = ref.watch(ledgerProvider);
  return [
    for (final goal in ref.watch(goalsControllerProvider).live)
      LedgerMath.goalProgress(goal, ledger),
  ];
}

@riverpod
List<GoalProgress> pinnedGoalProgress(Ref ref) =>
    [for (final p in ref.watch(goalProgressListProvider)) if (p.goal.isPinned) p];

@riverpod
GoalProgress? goalProgress(Ref ref, String goalId) {
  final goal = ref.watch(goalsControllerProvider).byId(goalId);
  if (goal == null) return null;
  return LedgerMath.goalProgress(goal, ref.watch(ledgerProvider));
}

// ───────────────────── Totals & breakdowns ─────────────────────────────────

/// In / out / kept for the calendar month containing today.
@riverpod
PeriodTotals monthTotals(Ref ref) {
  final now = DateTime.now();
  final window = BudgetPeriodMath.windowFor(
    period: BudgetPeriod.monthly,
    anchor: now.startOfMonth,
    date: now,
  );
  return LedgerMath.totals(
    LedgerMath.inWindow(ref.watch(ledgerProvider), window),
    ref.watch(baseCurrencyProvider),
  );
}

/// The last [months] calendar months, oldest first. Feeds the reports page's
/// in-vs-out diverging columns.
@riverpod
List<({DateTime month, PeriodTotals totals})> monthlyTotals(
  Ref ref, {
  int months = 6,
}) => LedgerMath.monthlyTotals(
  ref.watch(ledgerProvider),
  ref.watch(baseCurrencyProvider),
  months: months,
);

/// Spend by category for the **pulse's own window**, so the home screen's
/// breakdown covers exactly the period its headline number does. A breakdown
/// over the calendar month beside a headline over a 15th-anchored budget is
/// two different months stacked on one screen.
@riverpod
List<CategorySpend> pulseSpendByCategory(Ref ref) {
  final pulse = ref.watch(spendingPulseProvider);
  return LedgerMath.spendByCategory(
    LedgerMath.inWindow(ref.watch(ledgerProvider), pulse.window),
    ref.watch(baseCurrencyProvider),
  );
}

/// Spend by category over the last [days] days.
@riverpod
List<CategorySpend> spendByCategory(Ref ref, {int days = 30}) {
  final today = DateTime.now();
  return LedgerMath.spendByCategory(
    LedgerMath.between(
      ref.watch(ledgerProvider),
      DateTime(today.year, today.month, today.day - (days - 1)),
      today,
    ),
    ref.watch(baseCurrencyProvider),
  );
}

/// Daily spend over the last [days] days, zero-filled. Heatmap and line chart.
@riverpod
List<SeriesPoint> dailySpend(Ref ref, {int days = 84}) {
  final today = DateTime.now().startOfDay;
  return LedgerMath.dailySpend(
    ref.watch(ledgerProvider),
    DateTime(today.year, today.month, today.day - (days - 1)),
    today,
    ref.watch(baseCurrencyProvider),
  );
}

// ───────────────────── Obligations ─────────────────────────────────────────

@riverpod
List<TransactionModel> overdueTransactions(Ref ref) =>
    LedgerMath.overdue(ref.watch(ledgerProvider));

@riverpod
List<TransactionModel> upcomingTransactions(Ref ref, {int withinDays = 30}) =>
    LedgerMath.upcoming(ref.watch(ledgerProvider), withinDays: withinDays);

@riverpod
List<TransactionModel> openLoans(Ref ref) =>
    LedgerMath.openLoans(ref.watch(ledgerProvider));

@riverpod
List<TransactionModel> recurringTransactions(Ref ref) =>
    LedgerMath.recurring(ref.watch(ledgerProvider));

/// Net position on open loans, in base currency.
///
/// Read as: `inflowMinor` is owed **to** you, `outflowMinor` is what you owe,
/// and `netMinor` is the net — positive means you are a creditor.
@riverpod
PeriodTotals loanPosition(Ref ref) {
  final base = ref.watch(baseCurrencyProvider);
  var owedToYou = 0;
  var youOwe = 0;
  for (final t in ref.watch(openLoansProvider)) {
    final amount = MoneyFormat.convert(t.amountMinor, t.currency, base);
    // A credit is money you handed over (recorded as an expense) that is
    // coming back; a debt is money you received (income) that has to go back.
    if (t.type.isExpense) {
      owedToYou += amount;
    } else {
      youOwe += amount;
    }
  }
  return PeriodTotals(inflowMinor: owedToYou, outflowMinor: youOwe);
}

// ───────────────────── Lists ───────────────────────────────────────────────

@riverpod
List<TransactionModel> recentTransactions(Ref ref, {int limit = 6}) {
  final settled = [
    for (final t in ref.watch(ledgerProvider)) if (t.isSettled) t,
  ];
  return settled.take(limit).toList();
}

/// Day-grouped ledger — the shape the transactions list renders from.
@riverpod
List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
groupedLedger(Ref ref) => LedgerMath.groupByDay(
  ref.watch(ledgerProvider),
  ref.watch(baseCurrencyProvider),
);
