import 'package:intl/intl.dart';

extension BudgyDateX on DateTime {
  /// Midnight, same day. The canonical key for day-grouping a ledger.
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get startOfMonth => DateTime(year, month);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Monday-first week start, normalised to midnight.
  DateTime get startOfWeek =>
      startOfDay.subtract(Duration(days: weekday - DateTime.monday));

  DateTime get startOfYear => DateTime(year);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) => year == other.year && month == other.month;

  bool get isToday => isSameDay(DateTime.now());
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  bool get isTomorrow =>
      isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// `Mon 6 Oct` — the ledger's day separator.
  String get dayLabel => DateFormat('EEE d MMM').format(this);

  /// Human-first day heading: Today / Yesterday / Tomorrow, else [dayLabel].
  /// Warm copy beats precision for the three days a user actually cares about.
  String get relativeDayLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return dayLabel;
  }

  /// `October 2026`
  String get monthLabel => DateFormat('MMMM yyyy').format(this);

  /// `Oct`
  String get monthShort => DateFormat('MMM').format(this);

  /// `6 Oct 2026`
  String get fullLabel => DateFormat('d MMM yyyy').format(this);

  /// Days from now, rounded to whole days from midnight so "tomorrow" is
  /// always 1 — never 0 because it is 11pm.
  int get daysFromNow =>
      startOfDay.difference(DateTime.now().startOfDay).inDays;
}
