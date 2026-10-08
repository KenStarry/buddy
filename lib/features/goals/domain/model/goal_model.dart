import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/utils/extensions/date_extensions.dart';

/// What a goal is counting.
enum GoalKind {
  /// Put money aside until you reach a target. Progress is income and
  /// transfers *in* that were tagged to this goal.
  saving,

  /// Save up *for* a purchase and then spend it. Progress is spend tagged to
  /// this goal, and hitting the target is the point of no return rather than
  /// a celebration — so the UI frames it differently.
  spending,
}

extension GoalKindX on GoalKind {
  String get label => switch (this) {
    GoalKind.saving => 'Saving',
    GoalKind.spending => 'Spending',
  };

  static GoalKind fromKey(String? key) => GoalKind.values.firstWhere(
    (k) => k.name == key,
    orElse: () => GoalKind.saving,
  );
}

/// A savings or purchase target. Cashew calls these objectives.
@immutable
class GoalModel extends Equatable {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.currencyCode,
    required this.iconKey,
    required this.colorIndex,
    required this.startDate,
    this.kind = GoalKind.saving,
    this.targetDate,
    this.emoji,
    this.note,
    this.isPinned = false,
    this.isArchived = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final int targetMinor;
  final String currencyCode;
  final String iconKey;
  final int colorIndex;
  final DateTime startDate;
  final GoalKind kind;

  /// Deadline. Null means "whenever" — a goal without a date is still a goal,
  /// so pace is simply not shown rather than faked from a guess.
  final DateTime? targetDate;

  final String? emoji;
  final String? note;
  final bool isPinned;
  final bool isArchived;
  final DateTime? createdAt;

  Currency get currency => CurrencyRegistry.byCode(currencyCode);

  bool get hasDeadline => targetDate != null;

  int? get daysRemaining => targetDate?.daysFromNow;

  bool get isOverdue {
    final days = daysRemaining;
    return days != null && days < 0;
  }

  /// How much more per day to land on the target by the deadline, given
  /// [savedMinor] so far. Null when there is no deadline or it has passed.
  ///
  /// ⚠️ Divides by `days`, which is why the `<= 0` guard is here and not at
  /// the call site: on the deadline itself `daysRemaining` is 0, and an
  /// integer divide by zero in Dart throws rather than yielding infinity.
  int? dailyPaceMinor(int savedMinor) {
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    final remaining = targetMinor - savedMinor;
    if (remaining <= 0) return 0;
    return (remaining / days).ceil();
  }

  GoalModel copyWith({
    String? id,
    String? name,
    int? targetMinor,
    String? currencyCode,
    String? iconKey,
    int? colorIndex,
    DateTime? startDate,
    GoalKind? kind,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? emoji,
    bool clearEmoji = false,
    String? note,
    bool clearNote = false,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
  }) => GoalModel(
    id: id ?? this.id,
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    iconKey: iconKey ?? this.iconKey,
    colorIndex: colorIndex ?? this.colorIndex,
    startDate: startDate ?? this.startDate,
    kind: kind ?? this.kind,
    targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    emoji: clearEmoji ? null : (emoji ?? this.emoji),
    note: clearNote ? null : (note ?? this.note),
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Goal',
    targetMinor: (map['target_minor'] as num?)?.toInt().abs() ?? 0,
    currencyCode:
        map['currency_code']?.toString() ?? CurrencyRegistry.base.code,
    iconKey: map['icon_key']?.toString() ?? 'target',
    colorIndex: ((map['color_index'] as num?)?.toInt() ?? 0).clamp(0, 7),
    startDate:
        DateTime.tryParse(map['start_date']?.toString() ?? '') ??
        DateTime.now(),
    kind: GoalKindX.fromKey(map['kind']?.toString()),
    targetDate: DateTime.tryParse(map['target_date']?.toString() ?? ''),
    emoji: (map['emoji']?.toString().isEmpty ?? true)
        ? null
        : map['emoji'].toString(),
    note: map['note']?.toString(),
    isPinned: map['is_pinned'] == true,
    isArchived: map['is_archived'] == true,
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'target_minor': targetMinor,
    'currency_code': currencyCode,
    'icon_key': iconKey,
    'color_index': colorIndex,
    'start_date': startDate.toIso8601String(),
    'kind': kind.name,
    'target_date': targetDate?.toIso8601String(),
    'emoji': emoji,
    'note': note,
    'is_pinned': isPinned,
    'is_archived': isArchived,
    'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    targetMinor,
    currencyCode,
    iconKey,
    colorIndex,
    startDate,
    kind,
    targetDate,
    emoji,
    note,
    isPinned,
    isArchived,
  ];
}
