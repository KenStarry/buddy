import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../enum/transaction_type.dart';

/// A repeat rule.
@immutable
class Recurrence extends Equatable {
  const Recurrence({
    required this.cadence,
    this.interval = 1,
    this.until,
  });

  final RecurrenceCadence cadence;

  /// Every N [cadence]s. Clamped to at least 1 on read — an interval of 0
  /// makes [next] return the same date forever, which is an infinite loop in
  /// whatever is generating occurrences.
  final int interval;

  /// Stops after this date. Null means forever.
  final DateTime? until;

  String get label => cadence.labelEvery(interval);

  /// The next occurrence strictly after [from].
  ///
  /// ⚠️ Monthly stepping clamps the day of month. Naively adding a month to
  /// 31 January lands on 31 February, which `DateTime` silently rolls into
  /// 2 or 3 March — so a rent charge anchored to the 31st drifts into the
  /// next month and then keeps drifting. Clamping to the target month's last
  /// day keeps it on the 28th/30th and, crucially, does not move the anchor.
  DateTime next(DateTime from) {
    final step = interval < 1 ? 1 : interval;
    switch (cadence) {
      case RecurrenceCadence.daily:
        return from.add(Duration(days: step));
      case RecurrenceCadence.weekly:
        return from.add(Duration(days: 7 * step));
      case RecurrenceCadence.monthly:
        return _addMonths(from, step);
      case RecurrenceCadence.yearly:
        return _addMonths(from, 12 * step);
    }
  }

  static DateTime _addMonths(DateTime from, int months) {
    final targetMonth = from.month + months;
    final year = from.year + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;
    // Day 0 of the following month is the last day of this one.
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      from.day > lastDay ? lastDay : from.day,
      from.hour,
      from.minute,
    );
  }

  /// Whether another occurrence is due on or before [horizon].
  bool hasOccurrenceBy(DateTime from, DateTime horizon) {
    final n = next(from);
    if (until != null && n.isAfter(until!)) return false;
    return !n.isAfter(horizon);
  }

  Recurrence copyWith({
    RecurrenceCadence? cadence,
    int? interval,
    DateTime? until,
    bool clearUntil = false,
  }) => Recurrence(
    cadence: cadence ?? this.cadence,
    interval: interval ?? this.interval,
    until: clearUntil ? null : (until ?? this.until),
  );

  factory Recurrence.fromMap(Map<String, dynamic> map) => Recurrence(
    cadence: RecurrenceCadenceX.fromKey(map['cadence']?.toString()),
    interval: ((map['interval'] as num?)?.toInt() ?? 1).clamp(1, 365),
    until: DateTime.tryParse(map['until']?.toString() ?? ''),
  );

  Map<String, dynamic> toMap() => {
    'cadence': cadence.name,
    'interval': interval,
    'until': until?.toIso8601String(),
  };

  @override
  List<Object?> get props => [cadence, interval, until];
}
