import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/extensions/date_extensions.dart';

/// How often a budget resets.
enum BudgetPeriod { weekly, monthly, yearly, custom }

extension BudgetPeriodX on BudgetPeriod {
  String get label => switch (this) {
    BudgetPeriod.weekly => 'Weekly',
    BudgetPeriod.monthly => 'Monthly',
    BudgetPeriod.yearly => 'Yearly',
    BudgetPeriod.custom => 'Custom',
  };

  static BudgetPeriod fromKey(String? key) => BudgetPeriod.values.firstWhere(
    (p) => p.name == key,
    orElse: () => BudgetPeriod.monthly,
  );
}

/// One concrete stretch of time a budget applies to.
///
/// [index] counts periods from the budget's anchor: 0 is the period containing
/// the anchor, −1 the one before it. It is what makes "past budgets" a pure
/// function of an integer rather than a stored list of windows.
@immutable
class BudgetWindow extends Equatable {
  const BudgetWindow({
    required this.start,
    required this.end,
    required this.index,
  });

  /// Inclusive, at midnight.
  final DateTime start;

  /// Inclusive, at the last microsecond of the final day. Compare with
  /// `!date.isAfter(end)`.
  final DateTime end;

  final int index;

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  int get totalDays => BudgetPeriodMath.daysBetween(start, end) + 1;

  /// Days elapsed including today, clamped into the window. Used for the
  /// "you're 68% through the month" pace read.
  int get elapsedDays {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return totalDays;
    return BudgetPeriodMath.daysBetween(start, now) + 1;
  }

  int get remainingDays => (totalDays - elapsedDays).clamp(0, totalDays);

  /// 0..1 through the window.
  double get elapsedFraction =>
      totalDays == 0 ? 0 : (elapsedDays / totalDays).clamp(0.0, 1.0);

  bool get isCurrent => contains(DateTime.now());

  /// `1 – 31 Oct`, or `15 Sep – 14 Oct` when the anchor is mid-month.
  String get label {
    final sameMonth = start.month == end.month && start.year == end.year;
    if (sameMonth && start.day == 1 && end.day == BudgetPeriodMath.lastDayOf(end.year, end.month)) {
      return start.monthLabel;
    }
    if (sameMonth) return '${start.day} – ${end.day} ${start.monthShort}';
    return '${start.day} ${start.monthShort} – ${end.day} ${end.monthShort}';
  }

  @override
  List<Object?> get props => [start, end, index];
}

/// Calendar maths for budget windows.
///
/// ⚠️ Everything here steps with `DateTime(y, m, d + n)` rather than
/// `add(Duration(days: n))`. Duration arithmetic is *absolute time*, so across
/// a daylight-saving boundary "+7 days" lands at 23:00 the previous day — and
/// a weekly budget's window silently slides an hour earlier every spring until
/// a transaction logged at midnight falls into the wrong period. Constructing
/// the date is calendar arithmetic and stays put.
class BudgetPeriodMath {
  BudgetPeriodMath._();

  /// Last day number of a month. Day 0 of the next month is the last of this.
  static int lastDayOf(int year, int month) => DateTime(year, month + 1, 0).day;

  /// Whole days between two instants, counted in calendar days so a DST
  /// boundary cannot make it 6.96 and truncate to 6.
  static int daysBetween(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  /// The window of [period] that contains [date], anchored at [anchor].
  ///
  /// The anchor is the budget's `periodStart` — its day-of-month for monthly,
  /// weekday for weekly, month-and-day for yearly, and the zero point for
  /// custom-length periods.
  static BudgetWindow windowFor({
    required BudgetPeriod period,
    required DateTime anchor,
    required DateTime date,
    int customDays = 30,
  }) {
    final day = date.startOfDay;
    final a = anchor.startOfDay;

    switch (period) {
      case BudgetPeriod.weekly:
        final offset = (day.weekday - a.weekday) % 7;
        final start = DateTime(day.year, day.month, day.day - offset);
        // Floor, for the same reason the custom branch floors: a window two
        // weeks before the anchor must index −2, and `~/` would call it 0.
        final index = (daysBetween(a, start) / 7).floor();
        return BudgetWindow(
          start: start,
          end: _endOf(DateTime(start.year, start.month, start.day + 6)),
          index: index,
        );

      case BudgetPeriod.monthly:
        // ⚠️ Clamp from the ANCHOR's day every time, never from the previous
        // window's start. Anchor day 31 gives 28 Feb, and if March then
        // stepped from 28 the budget would reset on the 28th forever — the
        // anchor quietly eroding one month at a time.
        var start = _clampedDay(day.year, day.month, a.day);
        if (start.isAfter(day)) {
          start = _clampedDay(day.year, day.month - 1, a.day);
        }
        final nextStart = _clampedDay(start.year, start.month + 1, a.day);
        final index =
            (start.year - a.year) * 12 + (start.month - a.month);
        return BudgetWindow(
          start: start,
          end: _endOf(
            DateTime(nextStart.year, nextStart.month, nextStart.day - 1),
          ),
          index: index,
        );

      case BudgetPeriod.yearly:
        var start = _clampedDay(day.year, a.month, a.day);
        if (start.isAfter(day)) {
          start = _clampedDay(day.year - 1, a.month, a.day);
        }
        final nextStart = _clampedDay(start.year + 1, a.month, a.day);
        return BudgetWindow(
          start: start,
          end: _endOf(
            DateTime(nextStart.year, nextStart.month, nextStart.day - 1),
          ),
          index: start.year - a.year,
        );

      case BudgetPeriod.custom:
        final length = customDays < 1 ? 1 : customDays;
        // `.floor()`, not `~/`: integer division truncates toward zero, so a
        // date 3 days BEFORE the anchor with a 30-day period lands in period
        // 0 alongside the anchor itself instead of period −1 — two adjacent
        // windows claiming the same days.
        final elapsed = daysBetween(a, day);
        final index = (elapsed / length).floor();
        final start = DateTime(a.year, a.month, a.day + index * length);
        return BudgetWindow(
          start: start,
          end: _endOf(
            DateTime(start.year, start.month, start.day + length - 1),
          ),
          index: index,
        );
    }
  }

  /// The window [offset] periods away from the one containing [from].
  static BudgetWindow windowOffset({
    required BudgetPeriod period,
    required DateTime anchor,
    required DateTime from,
    required int offset,
    int customDays = 30,
  }) {
    final base = windowFor(
      period: period,
      anchor: anchor,
      date: from,
      customDays: customDays,
    );
    if (offset == 0) return base;

    // Step by landing a probe date inside the target window rather than by
    // arithmetic on the window itself — the clamping rules above then apply
    // once, in one place.
    final s = base.start;
    final probe = switch (period) {
      BudgetPeriod.weekly => DateTime(s.year, s.month, s.day + 7 * offset),
      BudgetPeriod.monthly => _clampedDay(s.year, s.month + offset, anchor.day),
      BudgetPeriod.yearly => _clampedDay(
        s.year + offset,
        anchor.month,
        anchor.day,
      ),
      BudgetPeriod.custom => DateTime(
        s.year,
        s.month,
        s.day + (customDays < 1 ? 1 : customDays) * offset,
      ),
    };
    return windowFor(
      period: period,
      anchor: anchor,
      date: probe,
      customDays: customDays,
    );
  }

  /// `(year, month, day)` with the month allowed to run out of range and the
  /// day clamped to that month's length.
  ///
  /// ⚠️ The month rolls with **floor** division, not `~/`. Callers pass
  /// `month + offset`, so month 0 (December of the previous year) and month
  /// −1 (November) are ordinary inputs; `~/` truncates toward zero and maps
  /// both of those onto the *current* year, putting a budget's "two periods
  /// ago" window twelve months out.
  static DateTime _clampedDay(int year, int month, int day) {
    final zeroBased = month - 1;
    final yearDelta = (zeroBased / 12).floor();
    final normalisedMonth = zeroBased - yearDelta * 12 + 1; // 1..12
    final normalisedYear = year + yearDelta;
    final last = lastDayOf(normalisedYear, normalisedMonth);
    return DateTime(
      normalisedYear,
      normalisedMonth,
      day > last ? last : day,
    );
  }

  static DateTime _endOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999, 999);
}
