import 'package:budgy/features/budgets/domain/enum/budget_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BudgetWindow monthly(DateTime anchor, DateTime date) =>
      BudgetPeriodMath.windowFor(
        period: BudgetPeriod.monthly,
        anchor: anchor,
        date: date,
      );

  group('monthly windows', () {
    test('a 1st-anchored budget spans the calendar month', () {
      final w = monthly(DateTime(2026, 1, 1), DateTime(2026, 3, 15));
      expect(w.start, DateTime(2026, 3, 1));
      expect(w.end.day, 31);
      expect(w.end.month, 3);
      expect(w.totalDays, 31);
    });

    test('a 31st anchor clamps in short months and recovers', () {
      // The regression this guards: naively adding a month to 31 Jan lands on
      // 31 Feb, which DateTime rolls into early March — so a budget anchored
      // to the 31st walks forward a few days every short month and never
      // comes back.
      final anchor = DateTime(2026, 1, 31);

      // Mid-February still belongs to the window that STARTED on 31 Jan —
      // the next one cannot begin until the clamped 28th.
      expect(monthly(anchor, DateTime(2026, 2, 15)).start, DateTime(2026, 1, 31));

      // Late February opens the clamped window.
      expect(monthly(anchor, DateTime(2026, 2, 28)).start, DateTime(2026, 2, 28));

      // And March recovers the anchor's own day rather than continuing from
      // the 28th. This is the no-drift property.
      expect(monthly(anchor, DateTime(2026, 4, 1)).start, DateTime(2026, 3, 31));
      expect(monthly(anchor, DateTime(2026, 6, 5)).start, DateTime(2026, 5, 31));
    });

    test('a 31st anchor never drifts across a full year', () {
      final anchor = DateTime(2026, 1, 31);
      for (var month = 1; month <= 12; month++) {
        final lastDay = DateTime(2026, month + 1, 0).day;
        final w = monthly(anchor, DateTime(2026, month, lastDay));
        // Every window opens on the anchor's day, or on the last day of a
        // month too short to hold it — never on anything in between, which is
        // what drift would look like.
        expect(
          w.start.day == 31 || w.start.day == lastDay || w.start.day == DateTime(2026, w.start.month + 1, 0).day,
          isTrue,
          reason: 'month $month opened on ${w.start}',
        );
      }
    });

    test('windows are contiguous and never overlap', () {
      final anchor = DateTime(2026, 1, 31);
      for (var i = 0; i < 14; i++) {
        final probe = DateTime(2026, 1 + i, 15);
        final w = monthly(anchor, probe);
        final next = BudgetPeriodMath.windowOffset(
          period: BudgetPeriod.monthly,
          anchor: anchor,
          from: probe,
          offset: 1,
        );
        expect(
          next.start.difference(w.end).inHours <= 1,
          isTrue,
          reason: 'gap between ${w.end} and ${next.start}',
        );
        expect(w.end.isBefore(next.start), isTrue);
      }
    });

    test('indices go negative for past windows', () {
      final anchor = DateTime(2026, 6, 1);
      expect(monthly(anchor, DateTime(2026, 6, 10)).index, 0);
      expect(monthly(anchor, DateTime(2026, 5, 10)).index, -1);
      expect(monthly(anchor, DateTime(2025, 12, 10)).index, -6);
    });

    test('offset -2 reaches two months back, not twelve', () {
      // `~/` truncates toward zero, so month 0 and month −1 both mapped onto
      // the current year and "two periods ago" landed a year out.
      final w = BudgetPeriodMath.windowOffset(
        period: BudgetPeriod.monthly,
        anchor: DateTime(2026, 1, 15),
        from: DateTime(2026, 1, 20),
        offset: -2,
      );
      expect(w.start, DateTime(2025, 11, 15));
    });
  });

  group('weekly windows', () {
    test('span exactly seven days from the anchor weekday', () {
      final anchor = DateTime(2026, 10, 5); // a Monday
      final w = BudgetPeriodMath.windowFor(
        period: BudgetPeriod.weekly,
        anchor: anchor,
        date: DateTime(2026, 10, 8),
      );
      expect(w.start, DateTime(2026, 10, 5));
      expect(w.totalDays, 7);
      expect(w.start.weekday, anchor.weekday);
    });

    test('index goes negative for past weeks', () {
      final anchor = DateTime(2026, 10, 5);
      final w = BudgetPeriodMath.windowFor(
        period: BudgetPeriod.weekly,
        anchor: anchor,
        date: DateTime(2026, 9, 23),
      );
      expect(w.index, lessThan(0));
    });
  });

  group('custom windows', () {
    test('tile without gaps or overlaps', () {
      final anchor = DateTime(2026, 3, 1);
      final a = BudgetPeriodMath.windowFor(
        period: BudgetPeriod.custom,
        anchor: anchor,
        date: DateTime(2026, 3, 10),
        customDays: 30,
      );
      final b = BudgetPeriodMath.windowFor(
        period: BudgetPeriod.custom,
        anchor: anchor,
        date: DateTime(2026, 4, 5),
        customDays: 30,
      );
      expect(a.index, 0);
      expect(b.index, 1);
      expect(a.totalDays, 30);
      expect(a.end.isBefore(b.start), isTrue);
    });

    test('a date before the anchor lands in a negative period', () {
      // `~/` would have put this in period 0 alongside the anchor itself —
      // two windows claiming the same days.
      final w = BudgetPeriodMath.windowFor(
        period: BudgetPeriod.custom,
        anchor: DateTime(2026, 3, 10),
        date: DateTime(2026, 3, 7),
        customDays: 30,
      );
      expect(w.index, -1);
      expect(w.contains(DateTime(2026, 3, 7)), isTrue);
    });
  });

  test('contains is inclusive at both ends', () {
    final w = monthly(DateTime(2026, 1, 1), DateTime(2026, 3, 15));
    expect(w.contains(DateTime(2026, 3, 1)), isTrue);
    expect(w.contains(DateTime(2026, 3, 31, 23, 59)), isTrue);
    expect(w.contains(DateTime(2026, 2, 28, 23, 59)), isFalse);
    expect(w.contains(DateTime(2026, 4, 1)), isFalse);
  });
}
