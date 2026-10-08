import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../features/accounts/domain/model/account_model.dart';
import '../../../features/budgets/domain/enum/budget_period.dart';
import '../../../features/budgets/domain/model/budget_model.dart';
import '../../../features/goals/domain/model/goal_model.dart';

/// Money in and out over some window, in **base currency minor units**.
@immutable
class PeriodTotals extends Equatable {
  const PeriodTotals({this.inflowMinor = 0, this.outflowMinor = 0});

  final int inflowMinor;
  final int outflowMinor;

  int get netMinor => inflowMinor - outflowMinor;
  bool get isPositive => netMinor >= 0;

  /// What fraction of income was kept. Null when nothing came in — a savings
  /// rate on zero income is not 0%, it is undefined, and rendering "0%" there
  /// tells the user they failed at something they never attempted.
  double? get savingsRate =>
      inflowMinor <= 0 ? null : (netMinor / inflowMinor).clamp(-1.0, 1.0);

  PeriodTotals operator +(PeriodTotals other) => PeriodTotals(
    inflowMinor: inflowMinor + other.inflowMinor,
    outflowMinor: outflowMinor + other.outflowMinor,
  );

  @override
  List<Object?> get props => [inflowMinor, outflowMinor];
}

/// One category's slice of a window's spend.
@immutable
class CategorySpend extends Equatable {
  const CategorySpend({
    required this.categoryId,
    required this.minor,
    required this.share,
    required this.transactionCount,
  });

  final String categoryId;
  final int minor;

  /// 0..1 of the window's total spend.
  final double share;

  final int transactionCount;

  @override
  List<Object?> get props => [categoryId, minor, share, transactionCount];
}

/// A point on a time series — a day's spend, a balance on a date.
@immutable
class SeriesPoint extends Equatable {
  const SeriesPoint({required this.date, required this.minor});

  final DateTime date;
  final int minor;

  @override
  List<Object?> get props => [date, minor];
}

/// A wallet and what is in it.
@immutable
class AccountBalance extends Equatable {
  const AccountBalance({
    required this.account,
    required this.minor,
    required this.baseMinor,
  });

  final AccountModel account;

  /// In the **wallet's own** currency. What the user sees on the wallet card.
  final int minor;

  /// The same money in base currency. What totals are summed from.
  ///
  /// ⚠️ Both are stored rather than converting at the call site, because
  /// summing the *displayed* figures across a multi-currency wallet list is
  /// how you get a net worth of "KSh 19,670 + $1,240 = 20,910".
  final int baseMinor;

  @override
  List<Object?> get props => [account, minor, baseMinor];
}

/// How a budget is doing in one window.
@immutable
class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.budget,
    required this.window,
    required this.spentMinor,
    required this.transactionCount,
    this.perCategoryMinor = const {},
  });

  final BudgetModel budget;
  final BudgetWindow window;

  /// In the budget's own currency.
  final int spentMinor;

  final int transactionCount;

  /// `categoryId → spent`, for budgets carrying sub-limits.
  final Map<String, int> perCategoryMinor;

  int get limitMinor => budget.limitMinor;

  /// Can go negative — that is the point. A clamped "remaining" hides the
  /// overspend, which is the single most important number on the card.
  int get remainingMinor => limitMinor - spentMinor;

  bool get isOver => spentMinor > limitMinor;

  /// 0..1 for the meter fill. Overspend is shown by the card's colour and the
  /// negative remaining, not by a bar running off the end.
  double get fraction =>
      limitMinor <= 0 ? 0 : (spentMinor / limitMinor).clamp(0.0, 1.0);

  /// Unclamped, for the "237% of your limit" read.
  double get rawFraction => limitMinor <= 0 ? 0 : spentMinor / limitMinor;

  /// How far through the window we are — the pace marker on the meter.
  double get paceFraction => window.elapsedFraction;

  /// Spending faster than the clock. The whole reason a budget card shows a
  /// pace marker: 60% spent is fine on day 25 and alarming on day 5.
  bool get isAheadOfPace => fraction > paceFraction + 0.02;

  /// Where this lands if the current daily rate holds to the end of the
  /// window.
  ///
  /// ⚠️ **Do not put this number in front of a user.** It is a linear
  /// extrapolation, and a month's spending is not linear: rent lands on the
  /// 1st, so on the 6th of a 31-day month this reads six days of rent plus
  /// subscriptions as the daily rate and forecasts an overspend of a quarter
  /// of a million shillings. Technically derived, wildly untrue, and the kind
  /// of number that makes someone stop trusting the whole app.
  ///
  /// [runsOutOn] is the figure the UI shows instead: same rate, but bounded
  /// by the window, so the worst it can be is early rather than absurd.
  /// This getter stays for callers that want the raw rate.
  int? get projectedMinor {
    final elapsed = window.elapsedDays;
    if (elapsed < 1 || spentMinor <= 0) return null;
    return ((spentMinor / elapsed) * window.totalDays).round();
  }

  /// The day the limit runs out if the current rate holds.
  ///
  /// Null when the budget is already over, when the rate would see it through
  /// to the end of the window, or when there is too little of the window
  /// behind us to say anything — the same information as [projectedMinor] in
  /// a form that cannot embarrass itself.
  DateTime? get runsOutOn {
    if (isOver) return null;
    final elapsed = window.elapsedDays;
    // At least a fifth of the window and at least three days. Below that the
    // denominator is small enough that one big entry is the entire "rate".
    if (elapsed < 3 || window.elapsedFraction < 0.2) return null;
    if (spentMinor <= 0 || limitMinor <= 0) return null;

    final perDay = spentMinor / elapsed;
    if (perDay <= 0) return null;
    final daysToLimit = limitMinor / perDay;
    if (daysToLimit >= window.totalDays) return null; // comfortably inside

    final date = DateTime(
      window.start.year,
      window.start.month,
      window.start.day + daysToLimit.ceil() - 1,
    );
    return date.isBefore(DateTime.now()) ? null : date;
  }

  /// What is left per remaining day. Null once the window is out of days.
  int? get perDayRemainingMinor {
    final days = window.remainingDays;
    if (days <= 0) return null;
    return (remainingMinor / days).round();
  }

  /// A short, human read of the state. Used as the card's status line.
  BudgetHealth get health {
    if (isOver) return BudgetHealth.over;
    if (fraction >= 0.9) return BudgetHealth.tight;
    if (isAheadOfPace) return BudgetHealth.ahead;
    return BudgetHealth.onTrack;
  }

  @override
  List<Object?> get props => [
    budget,
    window,
    spentMinor,
    transactionCount,
    perCategoryMinor,
  ];
}

enum BudgetHealth { onTrack, ahead, tight, over }

extension BudgetHealthX on BudgetHealth {
  String get label => switch (this) {
    BudgetHealth.onTrack => 'On track',
    BudgetHealth.ahead => 'Spending fast',
    BudgetHealth.tight => 'Nearly there',
    BudgetHealth.over => 'Over',
  };
}

/// How a goal is doing.
@immutable
class GoalProgress extends Equatable {
  const GoalProgress({
    required this.goal,
    required this.savedMinor,
    required this.contributionCount,
    this.lastContribution,
  });

  final GoalModel goal;

  /// In the goal's currency.
  final int savedMinor;

  final int contributionCount;
  final DateTime? lastContribution;

  int get targetMinor => goal.targetMinor;
  int get remainingMinor => (targetMinor - savedMinor).clamp(0, targetMinor);

  double get fraction =>
      targetMinor <= 0 ? 0 : (savedMinor / targetMinor).clamp(0.0, 1.0);

  bool get isComplete => savedMinor >= targetMinor && targetMinor > 0;

  int? get dailyPaceMinor => goal.dailyPaceMinor(savedMinor);

  /// On course to land by the deadline, judged against the pace the goal
  /// *needed* from the start rather than against the calendar alone.
  bool? get isOnPace {
    final target = goal.targetDate;
    if (target == null || targetMinor <= 0) return null;
    final total = target.difference(goal.startDate).inDays;
    if (total <= 0) return null;
    final elapsed = DateTime.now().difference(goal.startDate).inDays;
    final expected = (elapsed / total).clamp(0.0, 1.0);
    return fraction + 0.02 >= expected;
  }

  @override
  List<Object?> get props => [
    goal,
    savedMinor,
    contributionCount,
    lastContribution,
  ];
}

/// The home screen's headline: what is genuinely left to spend, and at what
/// daily rate that lasts to the end of the window.
///
/// Budgy's own invention rather than a Cashew port. It answers the question a
/// user actually opens a budget app with — *can I buy this?* — which neither a
/// balance ("yes, but rent is due") nor a month-to-date total ("I don't know,
/// is that a lot?") answers on its own.
@immutable
class SpendingPulse extends Equatable {
  const SpendingPulse({
    required this.remainingMinor,
    required this.allowanceMinor,
    required this.spentMinor,
    required this.window,
    required this.source,
    required this.committedUpcomingMinor,
  });

  /// Allowance minus spend minus upcoming commitments. Signed — a negative
  /// figure is the most useful thing this screen can say.
  final int remainingMinor;

  /// The ceiling this is measured against: a pinned budget's limit, or the
  /// window's income when there is no budget to go on.
  final int allowanceMinor;

  final int spentMinor;

  /// Scheduled-but-unsettled outflow inside the window.
  ///
  /// ⚠️ Subtracted from what is "safe". Rent that is due on Friday is not
  /// money you can spend on Thursday, and a safe-to-spend figure that ignores
  /// it is actively misleading — the one failure mode that would make this
  /// number worse than no number.
  final int committedUpcomingMinor;

  final BudgetWindow window;

  /// The budget this was derived from, or null when it fell back to income.
  final BudgetModel? source;

  bool get isDerivedFromBudget => source != null;
  bool get isOverspent => remainingMinor < 0;

  double get fraction => allowanceMinor <= 0
      ? 0
      : (spentMinor / allowanceMinor).clamp(0.0, 1.0);

  double get paceFraction => window.elapsedFraction;
  bool get isAheadOfPace => fraction > paceFraction + 0.02;

  /// What is left, per remaining day. Null when the window has no days left.
  int? get perDayMinor {
    final days = window.remainingDays;
    if (days <= 0 || remainingMinor < 0) return null;
    return (remainingMinor / days).round();
  }

  int get daysLeft => window.remainingDays;

  @override
  List<Object?> get props => [
    remainingMinor,
    allowanceMinor,
    spentMinor,
    committedUpcomingMinor,
    window,
    source,
  ];
}
