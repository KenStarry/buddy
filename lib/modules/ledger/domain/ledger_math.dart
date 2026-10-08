import '../../../core/domain/currency.dart';
import '../../../core/utils/extensions/date_extensions.dart';
import '../../../core/utils/functions/money_format.dart';
import '../../../features/accounts/domain/model/account_model.dart';
import '../../../features/budgets/domain/enum/budget_period.dart';
import '../../../features/budgets/domain/model/budget_model.dart';
import '../../../features/goals/domain/model/goal_model.dart';
import '../../../features/transactions/domain/enum/transaction_type.dart';
import '../../../features/transactions/domain/model/transaction_model.dart';
import 'ledger_values.dart';

/// Every number Budgy shows that isn't stored, derived here.
///
/// All of it is **pure static functions over lists** — no Riverpod, no Hive,
/// no `BuildContext`. That is what makes the money maths testable without a
/// widget tree, and it is where the rules about what counts as spend live, so
/// the home screen, the budget card and the reports page cannot quietly
/// disagree about the same month.
///
/// ## Two invariants, everywhere in this file
///
/// 1. **Unsettled rows do not count.** A scheduled bill and an outstanding
///    loan are plans. They appear in Upcoming and in the pulse's commitments,
///    never in a balance or a budget's spend.
/// 2. **Aggregates are in base currency.** Per-wallet figures stay in the
///    wallet's own currency; the moment two currencies are summed, both go
///    through [MoneyFormat.convert] first.
class LedgerMath {
  LedgerMath._();

  /// Transactions whose date falls inside [window].
  static List<TransactionModel> inWindow(
    Iterable<TransactionModel> transactions,
    BudgetWindow window,
  ) => [for (final t in transactions) if (window.contains(t.date)) t];

  /// Transactions in `[from, to]` inclusive of both days.
  static List<TransactionModel> between(
    Iterable<TransactionModel> transactions,
    DateTime from,
    DateTime to,
  ) {
    final start = from.startOfDay;
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return [
      for (final t in transactions)
        if (!t.date.isBefore(start) && !t.date.isAfter(end)) t,
    ];
  }

  /// Money in and out, in base currency.
  static PeriodTotals totals(
    Iterable<TransactionModel> transactions,
    Currency base,
  ) {
    var inflow = 0;
    var outflow = 0;
    for (final t in transactions) {
      final amount = MoneyFormat.convert(t.amountMinor, t.currency, base);
      if (t.countsAsSpend) {
        outflow += amount;
      } else if (t.countsAsIncome) {
        inflow += amount;
      }
      // Transfers and unsettled rows fall through deliberately: a transfer is
      // neither, and an unsettled row is not yet anything.
    }
    return PeriodTotals(inflowMinor: inflow, outflowMinor: outflow);
  }

  /// Spend per category, largest first, with each slice's share of the total.
  ///
  /// Rows with no category are gathered under [uncategorisedId] rather than
  /// dropped — a missing category is a data-entry gap the user should see, and
  /// silently omitting it makes the slices not add up to the total shown above
  /// them.
  static const uncategorisedId = '__uncategorised__';

  static List<CategorySpend> spendByCategory(
    Iterable<TransactionModel> transactions,
    Currency base,
  ) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    var grand = 0;

    for (final t in transactions) {
      if (!t.countsAsSpend) continue;
      final key = t.categoryId ?? uncategorisedId;
      final amount = MoneyFormat.convert(t.amountMinor, t.currency, base);
      totals[key] = (totals[key] ?? 0) + amount;
      counts[key] = (counts[key] ?? 0) + 1;
      grand += amount;
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (final e in entries)
        CategorySpend(
          categoryId: e.key,
          minor: e.value,
          share: grand == 0 ? 0 : e.value / grand,
          transactionCount: counts[e.key] ?? 0,
        ),
    ];
  }

  /// Daily spend across `[from, to]`, **including days with none**.
  ///
  /// ⚠️ The zero-fill is load-bearing. A line chart or heatmap built from only
  /// the days that had transactions draws a quiet week as a straight line
  /// between its neighbours — which reads as steady spending through a week
  /// where nothing was spent at all.
  static List<SeriesPoint> dailySpend(
    Iterable<TransactionModel> transactions,
    DateTime from,
    DateTime to,
    Currency base,
  ) {
    final buckets = <DateTime, int>{};
    final start = from.startOfDay;
    final totalDays = BudgetPeriodMath.daysBetween(start, to) + 1;
    for (var i = 0; i < totalDays; i++) {
      buckets[DateTime(start.year, start.month, start.day + i)] = 0;
    }

    for (final t in transactions) {
      if (!t.countsAsSpend) continue;
      final day = t.date.startOfDay;
      if (!buckets.containsKey(day)) continue;
      buckets[day] =
          buckets[day]! + MoneyFormat.convert(t.amountMinor, t.currency, base);
    }

    final days = buckets.keys.toList()..sort();
    return [for (final d in days) SeriesPoint(date: d, minor: buckets[d]!)];
  }

  /// Monthly in/out totals for the last [months] months, oldest first.
  static List<({DateTime month, PeriodTotals totals})> monthlyTotals(
    Iterable<TransactionModel> transactions,
    Currency base, {
    int months = 6,
  }) {
    final now = DateTime.now();
    final out = <({DateTime month, PeriodTotals totals})>[];
    for (var back = months - 1; back >= 0; back--) {
      final anchor = DateTime(now.year, now.month - back);
      final rows = [
        for (final t in transactions)
          if (t.date.isSameMonth(anchor)) t,
      ];
      out.add((month: anchor, totals: totals(rows, base)));
    }
    return out;
  }

  /// Every wallet's balance: opening plus every settled movement.
  static List<AccountBalance> balances(
    Iterable<AccountModel> accounts,
    Iterable<TransactionModel> transactions,
    Currency base,
  ) {
    final out = <AccountBalance>[];
    for (final account in accounts) {
      var minor = account.openingBalanceMinor;
      for (final t in transactions) {
        final delta = t.signedMinorFor(account.id);
        if (delta == 0) continue;
        // ⚠️ Convert into the WALLET's currency, not out of it. A $40 charge
        // on a KES wallet has to land as its KES value or the wallet's own
        // balance is denominated in two units at once.
        minor += MoneyFormat.convert(delta, t.currency, account.currency);
      }
      out.add(
        AccountBalance(
          account: account,
          minor: minor,
          baseMinor: MoneyFormat.convert(minor, account.currency, base),
        ),
      );
    }
    return out;
  }

  /// Net worth — every wallet not opted out, in base currency.
  static int netWorth(Iterable<AccountBalance> balances) {
    var total = 0;
    for (final b in balances) {
      if (b.account.excludeFromNetWorth) continue;
      total += b.baseMinor;
    }
    return total;
  }

  /// Net worth on each day across `[from, to]`.
  ///
  /// Walks **forward from the opening position** rather than computing each
  /// day independently: the latter is O(days × transactions) and, more
  /// importantly, it recomputes the same prefix sum every step, so a rounding
  /// difference in one day's conversion shows up as a sawtooth in the line.
  static List<SeriesPoint> netWorthSeries(
    Iterable<AccountModel> accounts,
    Iterable<TransactionModel> transactions,
    DateTime from,
    DateTime to,
    Currency base,
  ) {
    final tracked = [
      for (final a in accounts) if (!a.excludeFromNetWorth) a,
    ];
    if (tracked.isEmpty) return const [];

    final start = from.startOfDay;

    // Opening position: every settled movement strictly before the window.
    var running = 0;
    for (final a in tracked) {
      running += MoneyFormat.convert(a.openingBalanceMinor, a.currency, base);
    }
    final deltasByDay = <DateTime, int>{};
    for (final t in transactions) {
      var delta = 0;
      for (final a in tracked) {
        final d = t.signedMinorFor(a.id);
        if (d != 0) {
          delta += MoneyFormat.convert(d, t.currency, base);
        }
      }
      if (delta == 0) continue;
      if (t.date.isBefore(start)) {
        running += delta;
      } else {
        final day = t.date.startOfDay;
        deltasByDay[day] = (deltasByDay[day] ?? 0) + delta;
      }
    }

    final out = <SeriesPoint>[];
    final totalDays = BudgetPeriodMath.daysBetween(start, to) + 1;
    for (var i = 0; i < totalDays; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      running += deltasByDay[day] ?? 0;
      out.add(SeriesPoint(date: day, minor: running));
    }
    return out;
  }

  // ───────────────────── Budgets ───────────────────────────────────────────

  /// Does [budget] count [t]? Scope, date and settlement all together.
  static bool budgetCounts(
    BudgetModel budget,
    TransactionModel t,
    BudgetWindow window,
  ) {
    if (!window.contains(t.date)) return false;
    if (!t.isSettled) return false;
    if (t.excludeFromBudgets) return false;
    if (t.type.isTransfer) return false;
    if (t.nature.isLoan) return false;

    if (budget.isAddedOnly) return t.budgetIds.contains(budget.id);

    // A row explicitly added to a scoped budget counts even if its category
    // falls outside — an explicit choice outranks a filter.
    if (t.budgetIds.contains(budget.id)) return true;

    return budget.coversScope(categoryId: t.categoryId, accountId: t.accountId);
  }

  /// A budget's state in the window [offset] periods from now (0 = current).
  static BudgetProgress budgetProgress(
    BudgetModel budget,
    Iterable<TransactionModel> transactions, {
    int offset = 0,
    DateTime? now,
  }) {
    final window = budget.windowOffset(offset, from: now);
    final currency = budget.currency;

    var spent = 0;
    var count = 0;
    final perCategory = <String, int>{};

    for (final t in transactions) {
      if (!budgetCounts(budget, t, window)) continue;
      final amount = MoneyFormat.convert(t.amountMinor, t.currency, currency);

      if (t.type.isExpense) {
        spent += amount;
        count++;
        final key = t.categoryId ?? uncategorisedId;
        perCategory[key] = (perCategory[key] ?? 0) + amount;
      } else if (t.type.isIncome && budget.includeIncomeAsCredit) {
        // Reduces spend rather than adding to the limit, so the meter still
        // reads against the number the user set.
        spent -= amount;
        count++;
      }
    }

    return BudgetProgress(
      budget: budget,
      window: window,
      spentMinor: spent,
      transactionCount: count,
      perCategoryMinor: perCategory,
    );
  }

  /// Budget history, newest first: the current window plus [count] past ones.
  static List<BudgetProgress> budgetHistory(
    BudgetModel budget,
    Iterable<TransactionModel> transactions, {
    int count = 6,
  }) => [
    for (var offset = 0; offset > -count; offset--)
      budgetProgress(budget, transactions, offset: offset),
  ];

  // ───────────────────── Goals ─────────────────────────────────────────────

  /// What a goal has gathered.
  ///
  /// A **saving** goal counts money arriving in its name — income tagged to
  /// it, and transfers tagged to it (moving cash into a savings wallet is the
  /// commonest way to feed one). A **spending** goal counts the same
  /// contributions, because the user is saving *up* for it; the difference is
  /// entirely in how the UI frames hitting the target.
  static GoalProgress goalProgress(
    GoalModel goal,
    Iterable<TransactionModel> transactions,
  ) {
    final currency = goal.currency;
    var saved = 0;
    var count = 0;
    DateTime? last;

    for (final t in transactions) {
      if (t.goalId != goal.id) continue;
      if (!t.isSettled) continue;
      final amount = MoneyFormat.convert(t.amountMinor, t.currency, currency);

      switch (t.type) {
        case TransactionType.income:
        case TransactionType.transfer:
          saved += amount;
        case TransactionType.expense:
          // Spending *out of* a goal draws it down — how a spending goal gets
          // consumed once it is reached.
          saved -= amount;
      }
      count++;
      if (last == null || t.date.isAfter(last)) last = t.date;
    }

    return GoalProgress(
      goal: goal,
      savedMinor: saved,
      contributionCount: count,
      lastContribution: last,
    );
  }

  // ───────────────────── Upcoming & loans ──────────────────────────────────

  /// Unsettled rows dated before today, soonest-overdue last.
  static List<TransactionModel> overdue(
    Iterable<TransactionModel> transactions,
  ) =>
      [for (final t in transactions) if (t.isOverdue && !t.nature.isLoan) t]
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Unsettled rows dated today or later, soonest first.
  static List<TransactionModel> upcoming(
    Iterable<TransactionModel> transactions, {
    int withinDays = 30,
  }) {
    final horizon = DateTime.now().startOfDay.add(Duration(days: withinDays));
    return [
      for (final t in transactions)
        if (t.isUpcoming && !t.nature.isLoan && !t.date.isAfter(horizon)) t,
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Outstanding loans — money owed to you and money you owe.
  static List<TransactionModel> openLoans(
    Iterable<TransactionModel> transactions,
  ) =>
      [for (final t in transactions) if (t.nature.isLoan && !t.isSettled) t]
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Everything that recurs, next occurrence first.
  static List<TransactionModel> recurring(
    Iterable<TransactionModel> transactions,
  ) {
    // One row per recurring series, keyed by title + nature: the ledger holds
    // a settled row per past occurrence, and listing all of them would show
    // "Netflix" three times under Subscriptions.
    final seen = <String, TransactionModel>{};
    for (final t in transactions) {
      if (t.recurrence == null && !t.nature.recurs) continue;
      final key = '${t.title.toLowerCase()}|${t.nature.name}';
      final existing = seen[key];
      if (existing == null || t.date.isAfter(existing.date)) {
        seen[key] = t;
      }
    }
    return seen.values.toList()
      ..sort((a, b) {
        final an = a.nextOccurrence ?? a.date;
        final bn = b.nextOccurrence ?? b.date;
        return an.compareTo(bn);
      });
  }

  // ───────────────────── The home headline ─────────────────────────────────

  /// Budgy's safe-to-spend figure.
  ///
  /// Prefers a **pinned, all-categories** budget as the allowance, because
  /// that is the user explicitly stating what a month is supposed to cost.
  /// Falls back to the window's income when there is no such budget — a worse
  /// answer, but a real one, and [SpendingPulse.isDerivedFromBudget] lets the
  /// UI say which it is instead of presenting a guess as a limit.
  static SpendingPulse pulse({
    required Iterable<TransactionModel> transactions,
    required Iterable<BudgetModel> budgets,
    required Currency base,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    final candidate =
        budgets
            .where((b) => b.isPinned && b.isAllCategories && !b.isAddedOnly)
            .firstOrNull ??
        budgets
            .where((b) => b.isAllCategories && !b.isAddedOnly)
            .firstOrNull;

    if (candidate != null) {
      final progress = budgetProgress(
        candidate,
        transactions,
        now: reference,
      );
      final committed = _committedIn(
        transactions,
        progress.window,
        candidate.currency,
      );
      final allowance = MoneyFormat.convert(
        candidate.limitMinor,
        candidate.currency,
        base,
      );
      final spent = MoneyFormat.convert(
        progress.spentMinor,
        candidate.currency,
        base,
      );
      final committedBase = MoneyFormat.convert(
        committed,
        candidate.currency,
        base,
      );
      return SpendingPulse(
        remainingMinor: allowance - spent - committedBase,
        allowanceMinor: allowance,
        spentMinor: spent,
        committedUpcomingMinor: committedBase,
        window: progress.window,
        source: candidate,
      );
    }

    // No budget to go on — measure the calendar month against its own income.
    final window = BudgetPeriodMath.windowFor(
      period: BudgetPeriod.monthly,
      anchor: reference.startOfMonth,
      date: reference,
    );
    final rows = inWindow(transactions, window);
    final monthTotals = totals(rows, base);
    final committed = _committedIn(transactions, window, base);

    return SpendingPulse(
      remainingMinor:
          monthTotals.inflowMinor - monthTotals.outflowMinor - committed,
      allowanceMinor: monthTotals.inflowMinor,
      spentMinor: monthTotals.outflowMinor,
      committedUpcomingMinor: committed,
      window: window,
      source: null,
    );
  }

  /// Unsettled outflow dated inside [window] — money already promised.
  static int _committedIn(
    Iterable<TransactionModel> transactions,
    BudgetWindow window,
    Currency target,
  ) {
    var total = 0;
    for (final t in transactions) {
      if (t.isSettled) continue;
      if (!t.type.isExpense) continue;
      if (t.nature.isLoan) continue;
      if (!window.contains(t.date)) continue;
      total += MoneyFormat.convert(t.amountMinor, t.currency, target);
    }
    return total;
  }

  /// Groups a ledger into day buckets, newest day first, each day's rows
  /// newest first. The shape every transaction list renders from.
  static List<({DateTime day, List<TransactionModel> rows, PeriodTotals totals})>
  groupByDay(Iterable<TransactionModel> transactions, Currency base) {
    final buckets = <DateTime, List<TransactionModel>>{};
    for (final t in transactions) {
      buckets.putIfAbsent(t.date.startOfDay, () => []).add(t);
    }
    final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in days)
        (
          day: day,
          rows: buckets[day]!..sort((a, b) => b.date.compareTo(a.date)),
          totals: totals(buckets[day]!, base),
        ),
    ];
  }
}
