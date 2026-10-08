import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../enum/transaction_type.dart';
import 'recurrence.dart';

/// One line in the ledger.
@immutable
class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.type,
    required this.accountId,
    required this.currencyCode,
    required this.date,
    this.nature = TransactionNature.standard,
    this.categoryId,
    this.subcategoryId,
    this.destinationAccountId,
    this.note,
    this.tags = const [],
    this.budgetIds = const [],
    this.goalId,
    this.recurrence,
    this.isSettled = true,
    this.excludeFromBudgets = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;

  /// **Magnitude, always non-negative.** Direction lives in [type].
  ///
  /// ⚠️ Storing a signed amount sounds simpler and is the usual mistake: it
  /// makes "negative income" and "positive expense" representable, which means
  /// every sum has to decide whether to trust the sign or the type, and the
  /// two disagree the moment a user edits a row's type without re-entering the
  /// amount. One source of truth: the type signs it, via [signedMinor].
  final int amountMinor;

  final TransactionType type;
  final TransactionNature nature;

  /// The wallet this came out of / went into.
  final String accountId;

  /// Currency **snapshotted at write time**, denormalised off the account.
  ///
  /// ⚠️ Deliberate denormalisation. Reading the currency off the account
  /// means renaming a wallet's currency silently rewrites the value of every
  /// historical row in it — a 500 KES coffee becoming a 500 USD coffee. The
  /// past is a fact and carries its own unit.
  final String currencyCode;

  final DateTime date;

  final String? categoryId;
  final String? subcategoryId;

  /// The receiving wallet. Only meaningful when [type] is transfer.
  final String? destinationAccountId;

  final String? note;
  final List<String> tags;

  /// Budgets this row was *explicitly* added to, for "added" budgets that
  /// only count what you hand them (Cashew's added-budget behaviour).
  final List<String> budgetIds;

  /// Goal this row counts toward, if any.
  final String? goalId;

  final Recurrence? recurrence;

  /// Has the money actually moved? False for a scheduled bill or an
  /// outstanding loan. Unsettled rows are excluded from balances and budget
  /// spend — they are a plan, not a fact.
  final bool isSettled;

  /// Per-row opt-out: a one-off reimbursed purchase, a transfer you don't
  /// want polluting the groceries budget.
  final bool excludeFromBudgets;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ───────────────────── Derived ───────────────────────────────────────────

  Currency get currency => CurrencyRegistry.byCode(currencyCode);

  /// The amount with its direction applied. Zero for a transfer, which moves
  /// money without changing the total.
  int get signedMinor => amountMinor * type.sign;

  /// Signed effect on **one specific** wallet's balance.
  ///
  /// This is the method transfers exist for: the same row is `−amount` to the
  /// source wallet and `+amount` to the destination. A single `signedMinor`
  /// cannot express that, and a per-account balance computed from it is wrong
  /// by twice the transfer amount.
  int signedMinorFor(String walletId) {
    if (!isSettled) return 0;
    if (type.isTransfer) {
      if (walletId == accountId) return -amountMinor;
      if (walletId == destinationAccountId) return amountMinor;
      return 0;
    }
    return walletId == accountId ? signedMinor : 0;
  }

  /// Counts toward budget spend: a settled expense that hasn't opted out.
  /// Transfers never do — moving your own money is not spending it.
  bool get countsAsSpend =>
      isSettled && type.isExpense && !excludeFromBudgets && !nature.isLoan;

  bool get countsAsIncome => isSettled && type.isIncome && !nature.isLoan;

  bool get isOverdue =>
      !isSettled && date.isBefore(DateTime.now().startOfDay);

  bool get isUpcoming =>
      !isSettled && !date.isBefore(DateTime.now().startOfDay);

  /// Next time this comes round, or null if it does not recur.
  DateTime? get nextOccurrence => recurrence?.next(date);

  TransactionModel copyWith({
    String? id,
    String? title,
    int? amountMinor,
    TransactionType? type,
    TransactionNature? nature,
    String? accountId,
    String? currencyCode,
    DateTime? date,
    String? categoryId,
    bool clearCategory = false,
    String? subcategoryId,
    bool clearSubcategory = false,
    String? destinationAccountId,
    bool clearDestination = false,
    String? note,
    bool clearNote = false,
    List<String>? tags,
    List<String>? budgetIds,
    String? goalId,
    bool clearGoal = false,
    Recurrence? recurrence,
    bool clearRecurrence = false,
    bool? isSettled,
    bool? excludeFromBudgets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionModel(
    id: id ?? this.id,
    title: title ?? this.title,
    amountMinor: amountMinor ?? this.amountMinor,
    type: type ?? this.type,
    nature: nature ?? this.nature,
    accountId: accountId ?? this.accountId,
    currencyCode: currencyCode ?? this.currencyCode,
    date: date ?? this.date,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    subcategoryId: clearSubcategory
        ? null
        : (subcategoryId ?? this.subcategoryId),
    destinationAccountId: clearDestination
        ? null
        : (destinationAccountId ?? this.destinationAccountId),
    note: clearNote ? null : (note ?? this.note),
    tags: tags ?? this.tags,
    budgetIds: budgetIds ?? this.budgetIds,
    goalId: clearGoal ? null : (goalId ?? this.goalId),
    recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    isSettled: isSettled ?? this.isSettled,
    excludeFromBudgets: excludeFromBudgets ?? this.excludeFromBudgets,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final rawAmount = (map['amount_minor'] as num?)?.toInt() ?? 0;
    return TransactionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      // `.abs()` is a repair, not a formality: a row written by an older
      // build (or hand-edited in an import) may carry a signed amount, and
      // letting a negative magnitude through makes an expense *add* to the
      // balance once `type.sign` flips it again.
      amountMinor: rawAmount.abs(),
      type: TransactionTypeX.fromKey(map['type']?.toString()),
      nature: TransactionNatureX.fromKey(map['nature']?.toString()),
      accountId: map['account_id']?.toString() ?? '',
      currencyCode:
          map['currency_code']?.toString() ?? CurrencyRegistry.base.code,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      categoryId: map['category_id']?.toString(),
      subcategoryId: map['subcategory_id']?.toString(),
      destinationAccountId: map['destination_account_id']?.toString(),
      note: map['note']?.toString(),
      tags: [
        for (final t in (map['tags'] as List<dynamic>? ?? [])) t.toString(),
      ],
      budgetIds: [
        for (final b in (map['budget_ids'] as List<dynamic>? ?? []))
          b.toString(),
      ],
      goalId: map['goal_id']?.toString(),
      recurrence: map['recurrence'] == null
          ? null
          : Recurrence.fromMap(
              Map<String, dynamic>.from(map['recurrence'] as Map),
            ),
      isSettled: map['is_settled'] ?? true,
      excludeFromBudgets: map['exclude_from_budgets'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount_minor': amountMinor,
    'type': type.name,
    'nature': nature.name,
    'account_id': accountId,
    'currency_code': currencyCode,
    'date': date.toIso8601String(),
    'category_id': categoryId,
    'subcategory_id': subcategoryId,
    'destination_account_id': destinationAccountId,
    'note': note,
    'tags': tags,
    'budget_ids': budgetIds,
    'goal_id': goalId,
    'recurrence': recurrence?.toMap(),
    'is_settled': isSettled,
    'exclude_from_budgets': excludeFromBudgets,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    title,
    amountMinor,
    type,
    nature,
    accountId,
    currencyCode,
    date,
    categoryId,
    subcategoryId,
    destinationAccountId,
    note,
    tags,
    budgetIds,
    goalId,
    recurrence,
    isSettled,
    excludeFromBudgets,
  ];
}
