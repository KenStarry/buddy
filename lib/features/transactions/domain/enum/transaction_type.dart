/// Which way the money went. The *direction* axis.
///
/// ⚠️ Kept strictly separate from [TransactionNature] (how the entry behaves —
/// subscription, loan, upcoming). Cashew folds both into one "type" dropdown,
/// which is why it has to answer questions like "is a borrowed amount income?"
/// in the UI layer. Two axes answer it in the model: a debt you took on is
/// `income` × `debt`, and a subscription is `expense` × `subscription`.
enum TransactionType { expense, income, transfer }

extension TransactionTypeX on TransactionType {
  String get label => switch (this) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.transfer => 'Transfer',
  };

  /// The sign a *settled* entry of this type applies to a balance.
  /// Transfers are net-zero across the ledger — the two legs cancel — so the
  /// sign only means anything per-account.
  int get sign => switch (this) {
    TransactionType.expense => -1,
    TransactionType.income => 1,
    TransactionType.transfer => 0,
  };

  bool get isExpense => this == TransactionType.expense;
  bool get isIncome => this == TransactionType.income;
  bool get isTransfer => this == TransactionType.transfer;

  static TransactionType fromKey(String? key) =>
      TransactionType.values.firstWhere(
        (t) => t.name == key,
        orElse: () => TransactionType.expense,
      );
}

/// How the entry *behaves*. The lifecycle axis.
enum TransactionNature {
  /// Happened. Done. The overwhelming majority of rows.
  standard,

  /// A recurring charge you expect to keep paying — Netflix, rent.
  subscription,

  /// Repeats on a cadence but is not a service you subscribe to — a
  /// transfer to savings, a weekly shop.
  repeating,

  /// Scheduled, not yet settled. Shows in Upcoming until paid.
  upcoming,

  /// Money you borrowed. Settles when you pay it back.
  debt,

  /// Money you lent. Settles when you are paid back.
  credit,
}

extension TransactionNatureX on TransactionNature {
  String get label => switch (this) {
    TransactionNature.standard => 'Transaction',
    TransactionNature.subscription => 'Subscription',
    TransactionNature.repeating => 'Repeating',
    TransactionNature.upcoming => 'Upcoming',
    TransactionNature.debt => 'Debt',
    TransactionNature.credit => 'Credit',
  };

  String get iconKey => switch (this) {
    TransactionNature.standard => 'receipt',
    TransactionNature.subscription => 'repeat',
    TransactionNature.repeating => 'rotate-cw',
    TransactionNature.upcoming => 'clock',
    TransactionNature.debt => 'hand-coins',
    TransactionNature.credit => 'handshake',
  };

  /// Whether this entry waits on a settlement event before it counts toward
  /// a balance. An unsettled row is a *plan*, not a fact.
  bool get needsSettlement => switch (this) {
    TransactionNature.standard => false,
    TransactionNature.subscription => false,
    TransactionNature.repeating => false,
    TransactionNature.upcoming => true,
    TransactionNature.debt => true,
    TransactionNature.credit => true,
  };

  /// Debts and credits are a ledger of their own — Cashew gives them a
  /// dedicated screen, and so does Budgy.
  bool get isLoan =>
      this == TransactionNature.debt || this == TransactionNature.credit;

  bool get recurs =>
      this == TransactionNature.subscription ||
      this == TransactionNature.repeating;

  static TransactionNature fromKey(String? key) =>
      TransactionNature.values.firstWhere(
        (n) => n.name == key,
        orElse: () => TransactionNature.standard,
      );
}

/// How often a recurring entry comes round.
enum RecurrenceCadence { daily, weekly, monthly, yearly }

extension RecurrenceCadenceX on RecurrenceCadence {
  String get label => switch (this) {
    RecurrenceCadence.daily => 'Daily',
    RecurrenceCadence.weekly => 'Weekly',
    RecurrenceCadence.monthly => 'Monthly',
    RecurrenceCadence.yearly => 'Yearly',
  };

  /// `every 2 weeks`, `every month`.
  String labelEvery(int interval) => switch (this) {
    RecurrenceCadence.daily => interval == 1 ? 'every day' : 'every $interval days',
    RecurrenceCadence.weekly =>
      interval == 1 ? 'every week' : 'every $interval weeks',
    RecurrenceCadence.monthly =>
      interval == 1 ? 'every month' : 'every $interval months',
    RecurrenceCadence.yearly =>
      interval == 1 ? 'every year' : 'every $interval years',
  };

  static RecurrenceCadence fromKey(String? key) =>
      RecurrenceCadence.values.firstWhere(
        (c) => c.name == key,
        orElse: () => RecurrenceCadence.monthly,
      );
}
