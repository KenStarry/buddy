/// The home screen's composable blocks.
///
/// Cashew lets you rearrange and switch off the home sections, and it is one
/// of the best things about it — the screen ends up being *your* dashboard
/// rather than the developer's. Budgy keeps that, with the order and the
/// enabled set stored as a list of these keys.
enum HomeSection {
  /// The safe-to-spend hero. Not reorderable — see [reorderable].
  pulse,
  wallets,
  budgets,
  goals,
  upcoming,
  spendByCategory,
  thisMonth,
  heatmap,
  recent,
  loans,
}

extension HomeSectionX on HomeSection {
  String get key => name;

  String get label => switch (this) {
    HomeSection.pulse => 'Safe to spend',
    HomeSection.wallets => 'Wallets',
    HomeSection.budgets => 'Budgets',
    HomeSection.goals => 'Goals',
    HomeSection.upcoming => 'Upcoming & overdue',
    HomeSection.spendByCategory => 'Where it went',
    HomeSection.thisMonth => 'This month',
    HomeSection.heatmap => 'Spending rhythm',
    HomeSection.recent => 'Recent activity',
    HomeSection.loans => 'Lent & borrowed',
  };

  String get blurb => switch (this) {
    HomeSection.pulse => 'What is genuinely left, and per day',
    HomeSection.wallets => 'Balances across every wallet',
    HomeSection.budgets => 'Your pinned budgets, with pace',
    HomeSection.goals => 'Pinned goals and their progress',
    HomeSection.upcoming => 'Bills due, and ones you missed',
    HomeSection.spendByCategory => 'This window ranked by category',
    HomeSection.thisMonth => 'In, out, and what you kept',
    HomeSection.heatmap => 'Twelve weeks of spending, one square a day',
    HomeSection.recent => 'The last handful of entries',
    HomeSection.loans => 'Money owed to you and by you',
  };

  String get iconKey => switch (this) {
    HomeSection.pulse => 'target',
    HomeSection.wallets => 'wallet',
    HomeSection.budgets => 'piggy-bank',
    HomeSection.goals => 'flag',
    HomeSection.upcoming => 'clock',
    HomeSection.spendByCategory => 'shopping-bag',
    HomeSection.thisMonth => 'banknote',
    HomeSection.heatmap => 'flame',
    HomeSection.recent => 'receipt',
    HomeSection.loans => 'handshake',
  };

  /// The pulse is the screen's anchor and always sits first. Letting it be
  /// moved or switched off leaves a home screen whose first thing is a list of
  /// wallet balances — which is the generic banking-app home this whole
  /// design exists to not be.
  bool get reorderable => this != HomeSection.pulse;

  static HomeSection? fromKey(String key) =>
      HomeSection.values.where((s) => s.name == key).firstOrNull;

  /// The shipped arrangement. Ordered as a story: what can I spend → what am
  /// I on the hook for → how are my plans doing → what have I been doing.
  static const defaults = <HomeSection>[
    HomeSection.pulse,
    HomeSection.budgets,
    HomeSection.upcoming,
    HomeSection.wallets,
    HomeSection.spendByCategory,
    HomeSection.goals,
    HomeSection.thisMonth,
    HomeSection.heatmap,
    HomeSection.recent,
  ];
}
