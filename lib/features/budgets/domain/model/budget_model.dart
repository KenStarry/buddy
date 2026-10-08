import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/domain/currency.dart';
import '../enum/budget_period.dart';

/// A spending limit over a repeating window.
@immutable
class BudgetModel extends Equatable {
  const BudgetModel({
    required this.id,
    required this.name,
    required this.limitMinor,
    required this.currencyCode,
    required this.period,
    required this.anchorDate,
    required this.iconKey,
    required this.colorIndex,
    this.customDays = 30,
    this.categoryIds = const [],
    this.categoryLimits = const {},
    this.accountIds = const [],
    this.isAddedOnly = false,
    this.isPinned = false,
    this.includeIncomeAsCredit = false,
    this.createdAt,
  });

  final String id;
  final String name;

  /// The ceiling for one window.
  final int limitMinor;

  final String currencyCode;

  final BudgetPeriod period;

  /// The budget's zero point — its day-of-month for monthly, weekday for
  /// weekly, and so on. See [BudgetPeriodMath.windowFor].
  final DateTime anchorDate;

  final String iconKey;
  final int colorIndex;

  /// Window length when [period] is custom.
  final int customDays;

  /// Categories that count. **Empty means all of them** — which is how a
  /// top-level "everything" budget is expressed without a magic flag.
  final List<String> categoryIds;

  /// Per-category ceilings *inside* this budget (Cashew's budget limits):
  /// `categoryId → minor units`. A category absent from this map has no
  /// sub-limit; it just counts toward [limitMinor].
  final Map<String, int> categoryLimits;

  /// Wallets that count. Empty means all.
  final List<String> accountIds;

  /// An "added" budget counts **only** transactions explicitly assigned to it
  /// via `TransactionModel.budgetIds`, ignoring the category and wallet
  /// filters entirely. For one-off envelopes — a trip, a renovation — where
  /// the defining question is "did I decide this belongs here", not "what
  /// category is it".
  final bool isAddedOnly;

  final bool isPinned;

  /// Lets income inside the window claw back spend — useful for a
  /// reimbursement-heavy envelope, misleading for a normal monthly budget,
  /// so it is off by default.
  final bool includeIncomeAsCredit;

  final DateTime? createdAt;

  Currency get currency => CurrencyRegistry.byCode(currencyCode);

  /// Watches every category rather than a named subset.
  bool get isAllCategories => categoryIds.isEmpty;

  bool get hasSubLimits => categoryLimits.isNotEmpty;

  /// Sum of the per-category ceilings. If this exceeds [limitMinor] the
  /// sub-limits are collectively over-committed, which the UI surfaces rather
  /// than silently rebalancing — the user's numbers are the user's numbers.
  int get committedMinor =>
      categoryLimits.values.fold(0, (sum, v) => sum + v);

  bool get isOverCommitted => committedMinor > limitMinor;

  /// The window containing [date] (today, by default).
  BudgetWindow windowFor([DateTime? date]) => BudgetPeriodMath.windowFor(
    period: period,
    anchor: anchorDate,
    date: date ?? DateTime.now(),
    customDays: customDays,
  );

  /// The window [offset] periods from the current one. `-1` is last month.
  BudgetWindow windowOffset(int offset, {DateTime? from}) =>
      BudgetPeriodMath.windowOffset(
        period: period,
        anchor: anchorDate,
        from: from ?? DateTime.now(),
        offset: offset,
        customDays: customDays,
      );

  /// Whether a transaction's category and wallet fall inside this budget's
  /// filters. Date and settlement are the caller's business — this answers
  /// scope only.
  ///
  /// ⚠️ An added-only budget answers `false` here for everything. Callers
  /// must check [isAddedOnly] and consult `transaction.budgetIds` instead;
  /// returning `true` for the unfiltered case would make an added-only budget
  /// behave exactly like an all-categories one.
  bool coversScope({String? categoryId, required String accountId}) {
    if (isAddedOnly) return false;
    if (!isAllCategories &&
        (categoryId == null || !categoryIds.contains(categoryId))) {
      return false;
    }
    if (accountIds.isNotEmpty && !accountIds.contains(accountId)) return false;
    return true;
  }

  BudgetModel copyWith({
    String? id,
    String? name,
    int? limitMinor,
    String? currencyCode,
    BudgetPeriod? period,
    DateTime? anchorDate,
    String? iconKey,
    int? colorIndex,
    int? customDays,
    List<String>? categoryIds,
    Map<String, int>? categoryLimits,
    List<String>? accountIds,
    bool? isAddedOnly,
    bool? isPinned,
    bool? includeIncomeAsCredit,
    DateTime? createdAt,
  }) => BudgetModel(
    id: id ?? this.id,
    name: name ?? this.name,
    limitMinor: limitMinor ?? this.limitMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    period: period ?? this.period,
    anchorDate: anchorDate ?? this.anchorDate,
    iconKey: iconKey ?? this.iconKey,
    colorIndex: colorIndex ?? this.colorIndex,
    customDays: customDays ?? this.customDays,
    categoryIds: categoryIds ?? this.categoryIds,
    categoryLimits: categoryLimits ?? this.categoryLimits,
    accountIds: accountIds ?? this.accountIds,
    isAddedOnly: isAddedOnly ?? this.isAddedOnly,
    isPinned: isPinned ?? this.isPinned,
    includeIncomeAsCredit:
        includeIncomeAsCredit ?? this.includeIncomeAsCredit,
    createdAt: createdAt ?? this.createdAt,
  );

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Budget',
    limitMinor: (map['limit_minor'] as num?)?.toInt().abs() ?? 0,
    currencyCode:
        map['currency_code']?.toString() ?? CurrencyRegistry.base.code,
    period: BudgetPeriodX.fromKey(map['period']?.toString()),
    anchorDate:
        DateTime.tryParse(map['anchor_date']?.toString() ?? '') ??
        DateTime.now(),
    iconKey: map['icon_key']?.toString() ?? 'wallet',
    colorIndex: ((map['color_index'] as num?)?.toInt() ?? 0).clamp(0, 7),
    customDays: ((map['custom_days'] as num?)?.toInt() ?? 30).clamp(1, 3650),
    categoryIds: [
      for (final c in (map['category_ids'] as List<dynamic>? ?? []))
        c.toString(),
    ],
    categoryLimits: {
      for (final entry
          in (map['category_limits'] as Map<dynamic, dynamic>? ?? {}).entries)
        entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
    },
    accountIds: [
      for (final a in (map['account_ids'] as List<dynamic>? ?? []))
        a.toString(),
    ],
    isAddedOnly: map['is_added_only'] == true,
    isPinned: map['is_pinned'] == true,
    includeIncomeAsCredit: map['include_income_as_credit'] == true,
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'limit_minor': limitMinor,
    'currency_code': currencyCode,
    'period': period.name,
    'anchor_date': anchorDate.toIso8601String(),
    'icon_key': iconKey,
    'color_index': colorIndex,
    'custom_days': customDays,
    'category_ids': categoryIds,
    'category_limits': categoryLimits,
    'account_ids': accountIds,
    'is_added_only': isAddedOnly,
    'is_pinned': isPinned,
    'include_income_as_credit': includeIncomeAsCredit,
    'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    limitMinor,
    currencyCode,
    period,
    anchorDate,
    iconKey,
    colorIndex,
    customDays,
    categoryIds,
    categoryLimits,
    accountIds,
    isAddedOnly,
    isPinned,
    includeIncomeAsCredit,
  ];
}
