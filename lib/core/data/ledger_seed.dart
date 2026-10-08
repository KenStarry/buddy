import 'dart:math';

import '../../features/accounts/domain/model/account_model.dart';
import '../../features/budgets/domain/enum/budget_period.dart';
import '../../features/budgets/domain/model/budget_model.dart';
import '../../features/categories/domain/enum/category_kind.dart';
import '../../features/categories/domain/model/category_model.dart';
import '../../features/goals/domain/model/goal_model.dart';
import '../../features/transactions/domain/enum/transaction_type.dart';
import '../../features/transactions/domain/model/recurrence.dart';
import '../../features/transactions/domain/model/transaction_model.dart';
import '../domain/currency.dart';
import '../utils/extensions/date_extensions.dart';

/// A furnished three-month ledger for a fresh install.
///
/// An empty budget app is indistinguishable from a broken one — every chart is
/// blank, every ring reads zero, and there is nothing for the design to be
/// judged against. First launch lands on a plausible month that Settings can
/// wipe in one tap.
///
/// ⚠️ Dates are generated **relative to now**, and the amounts come from a
/// fixed-seed [Random], so the demo is always "the last three months" and
/// always the same three months. A hardcoded date range rots: open the app six
/// months after the build and every chart is empty again.
class LedgerSeed {
  LedgerSeed._();

  static const _currency = CurrencyRegistry.kes;

  /// 42, fixed. The seed must be deterministic or two runs disagree about
  /// what "the demo" is, which makes a screenshot irreproducible and a golden
  /// test impossible.
  static Random _rng() => Random(42);

  // ───────────────────── Accounts ──────────────────────────────────────────

  static List<AccountModel> accounts() => const [
    AccountModel(
      id: 'acc_mpesa',
      name: 'M-Pesa',
      currencyCode: 'KES',
      iconKey: 'smartphone',
      colorIndex: 0,
      openingBalanceMinor: 1250000,
      isPrimary: true,
      sortOrder: 0,
    ),
    AccountModel(
      id: 'acc_bank',
      name: 'Equity',
      currencyCode: 'KES',
      iconKey: 'landmark',
      colorIndex: 2,
      openingBalanceMinor: 18430000,
      sortOrder: 1,
    ),
    AccountModel(
      id: 'acc_cash',
      name: 'Cash',
      currencyCode: 'KES',
      iconKey: 'banknote',
      colorIndex: 3,
      openingBalanceMinor: 320000,
      sortOrder: 2,
    ),
    AccountModel(
      id: 'acc_usd',
      name: 'Dollar savings',
      currencyCode: 'USD',
      iconKey: 'piggy-bank',
      colorIndex: 5,
      openingBalanceMinor: 124000,
      sortOrder: 3,
    ),
  ];

  // ───────────────────── Categories ────────────────────────────────────────

  static List<CategoryModel> categories() => const [
    CategoryModel(
      id: 'cat_food',
      name: 'Food & Drink',
      kind: CategoryKind.expense,
      iconKey: 'utensils-crossed',
      colorIndex: 1,
      emoji: '🍜',
      sortOrder: 0,
      subcategories: [
        CategoryModel(
          id: 'sub_groceries',
          name: 'Groceries',
          kind: CategoryKind.expense,
          iconKey: 'shopping-cart',
          colorIndex: 1,
        ),
        CategoryModel(
          id: 'sub_eating_out',
          name: 'Eating out',
          kind: CategoryKind.expense,
          iconKey: 'utensils-crossed',
          colorIndex: 1,
        ),
        CategoryModel(
          id: 'sub_coffee',
          name: 'Coffee',
          kind: CategoryKind.expense,
          iconKey: 'coffee',
          colorIndex: 1,
        ),
      ],
    ),
    CategoryModel(
      id: 'cat_transport',
      name: 'Transport',
      kind: CategoryKind.expense,
      iconKey: 'car',
      colorIndex: 2,
      emoji: '🚗',
      sortOrder: 1,
      subcategories: [
        CategoryModel(
          id: 'sub_fuel',
          name: 'Fuel',
          kind: CategoryKind.expense,
          iconKey: 'fuel',
          colorIndex: 2,
        ),
        CategoryModel(
          id: 'sub_matatu',
          name: 'Matatu',
          kind: CategoryKind.expense,
          iconKey: 'bus',
          colorIndex: 2,
        ),
      ],
    ),
    CategoryModel(
      id: 'cat_bills',
      name: 'Bills & Utilities',
      kind: CategoryKind.expense,
      iconKey: 'zap',
      colorIndex: 3,
      emoji: '⚡',
      sortOrder: 2,
    ),
    CategoryModel(
      id: 'cat_shopping',
      name: 'Shopping',
      kind: CategoryKind.expense,
      iconKey: 'shopping-bag',
      colorIndex: 4,
      emoji: '🛍️',
      sortOrder: 3,
    ),
    CategoryModel(
      id: 'cat_home',
      name: 'Home',
      kind: CategoryKind.expense,
      iconKey: 'house',
      colorIndex: 5,
      emoji: '🏡',
      sortOrder: 4,
    ),
    CategoryModel(
      id: 'cat_fun',
      name: 'Good times',
      kind: CategoryKind.expense,
      iconKey: 'party-popper',
      colorIndex: 6,
      emoji: '🎉',
      sortOrder: 5,
    ),
    CategoryModel(
      id: 'cat_health',
      name: 'Health',
      kind: CategoryKind.expense,
      iconKey: 'heart-pulse',
      colorIndex: 7,
      emoji: '💚',
      sortOrder: 6,
    ),
    CategoryModel(
      id: 'cat_learning',
      name: 'Learning',
      kind: CategoryKind.expense,
      iconKey: 'graduation-cap',
      colorIndex: 0,
      emoji: '📚',
      sortOrder: 7,
    ),
    CategoryModel(
      id: 'cat_salary',
      name: 'Salary',
      kind: CategoryKind.income,
      iconKey: 'briefcase',
      colorIndex: 0,
      emoji: '💼',
      sortOrder: 0,
    ),
    CategoryModel(
      id: 'cat_freelance',
      name: 'Freelance',
      kind: CategoryKind.income,
      iconKey: 'laptop',
      colorIndex: 2,
      emoji: '💻',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'cat_gifts',
      name: 'Gifts',
      kind: CategoryKind.income,
      iconKey: 'gift',
      colorIndex: 4,
      emoji: '🎁',
      sortOrder: 2,
    ),
  ];

  // ───────────────────── Budgets ───────────────────────────────────────────

  static List<BudgetModel> budgets() {
    final now = DateTime.now();
    final monthAnchor = now.startOfMonth;
    return [
      BudgetModel(
        id: 'bud_month',
        name: 'Monthly spend',
        limitMinor: 8500000,
        currencyCode: _currency.code,
        period: BudgetPeriod.monthly,
        anchorDate: monthAnchor,
        iconKey: 'wallet',
        colorIndex: 0,
        isPinned: true,
        createdAt: monthAnchor,
      ),
      BudgetModel(
        id: 'bud_food',
        name: 'Eating well',
        limitMinor: 2200000,
        currencyCode: _currency.code,
        period: BudgetPeriod.monthly,
        anchorDate: monthAnchor,
        iconKey: 'utensils-crossed',
        colorIndex: 1,
        categoryIds: const ['cat_food'],
        categoryLimits: const {'cat_food': 2200000},
        isPinned: true,
        createdAt: monthAnchor,
      ),
      BudgetModel(
        id: 'bud_fun',
        name: 'Fun money',
        limitMinor: 800000,
        currencyCode: _currency.code,
        period: BudgetPeriod.weekly,
        anchorDate: now.startOfWeek,
        iconKey: 'party-popper',
        colorIndex: 6,
        categoryIds: const ['cat_fun', 'cat_shopping'],
        categoryLimits: const {'cat_fun': 500000, 'cat_shopping': 300000},
        createdAt: now.startOfWeek,
      ),
      BudgetModel(
        id: 'bud_trip',
        name: 'Diani trip',
        limitMinor: 6000000,
        currencyCode: _currency.code,
        period: BudgetPeriod.custom,
        customDays: 45,
        anchorDate: now.subtract(const Duration(days: 12)).startOfDay,
        iconKey: 'palmtree',
        colorIndex: 2,
        isAddedOnly: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }

  // ───────────────────── Goals ─────────────────────────────────────────────

  static List<GoalModel> goals() {
    final now = DateTime.now();
    return [
      GoalModel(
        id: 'goal_emergency',
        name: 'Emergency fund',
        targetMinor: 30000000,
        currencyCode: _currency.code,
        iconKey: 'shield',
        colorIndex: 0,
        startDate: now.subtract(const Duration(days: 120)),
        targetDate: DateTime(now.year, now.month + 8, 1),
        emoji: '🛟',
        note: 'Three months of runway. Boring on purpose.',
        isPinned: true,
      ),
      GoalModel(
        id: 'goal_macbook',
        name: 'MacBook Pro',
        targetMinor: 31000000,
        currencyCode: _currency.code,
        iconKey: 'laptop',
        colorIndex: 2,
        kind: GoalKind.spending,
        startDate: now.subtract(const Duration(days: 60)),
        targetDate: DateTime(now.year, now.month + 5, 15),
        emoji: '💻',
        isPinned: true,
      ),
      GoalModel(
        id: 'goal_japan',
        name: 'Japan 2027',
        targetMinor: 45000000,
        currencyCode: _currency.code,
        iconKey: 'plane',
        colorIndex: 4,
        startDate: now.subtract(const Duration(days: 30)),
        targetDate: DateTime(now.year + 1, 4, 1),
        emoji: '🗾',
        note: 'Cherry blossom season or nothing.',
      ),
    ];
  }

  // ───────────────────── Transactions ──────────────────────────────────────

  /// Roughly three months of plausible activity, ending today.
  static List<TransactionModel> transactions() {
    final rng = _rng();
    final now = DateTime.now();
    final today = now.startOfDay;
    final out = <TransactionModel>[];
    var seq = 0;

    String nextId() => 'seed_${(seq++).toString().padLeft(4, '0')}';

    void add({
      required String title,
      required int minor,
      required TransactionType type,
      required String accountId,
      required DateTime date,
      String? categoryId,
      String? subcategoryId,
      String? destinationAccountId,
      TransactionNature nature = TransactionNature.standard,
      Recurrence? recurrence,
      bool isSettled = true,
      List<String> budgetIds = const [],
      String? goalId,
      String? note,
      String currencyCode = 'KES',
    }) {
      out.add(
        TransactionModel(
          id: nextId(),
          title: title,
          amountMinor: minor,
          type: type,
          nature: nature,
          accountId: accountId,
          currencyCode: currencyCode,
          date: date,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          destinationAccountId: destinationAccountId,
          recurrence: recurrence,
          isSettled: isSettled,
          budgetIds: budgetIds,
          goalId: goalId,
          note: note,
          createdAt: date,
          updatedAt: date,
        ),
      );
    }

    /// A plausible amount in minor units, jittered around [aroundMajor].
    int jitter(int aroundMajor, double spread) {
      final factor = 1 + (rng.nextDouble() * 2 - 1) * spread;
      return _currency.toMinor(aroundMajor * factor);
    }

    // ── Recurring income: salary on the 28th, three months back ───────────
    for (var back = 3; back >= 0; back--) {
      final month = DateTime(now.year, now.month - back, 28);
      if (month.isAfter(today)) continue;
      add(
        title: 'Salary',
        minor: 14500000,
        type: TransactionType.income,
        accountId: 'acc_bank',
        categoryId: 'cat_salary',
        date: month,
        nature: TransactionNature.repeating,
        recurrence: const Recurrence(cadence: RecurrenceCadence.monthly),
      );
    }

    // ── Freelance, irregular ──────────────────────────────────────────────
    for (final daysAgo in [74, 51, 26, 9]) {
      add(
        title: ['Logo work', 'Landing page', 'App audit', 'Brand refresh'][
            [74, 51, 26, 9].indexOf(daysAgo)],
        minor: jitter(32000, 0.35),
        type: TransactionType.income,
        accountId: 'acc_mpesa',
        categoryId: 'cat_freelance',
        date: today.subtract(Duration(days: daysAgo)),
      );
    }

    // ── Rent, the 1st of each month ───────────────────────────────────────
    for (var back = 2; back >= 0; back--) {
      final first = DateTime(now.year, now.month - back, 1);
      if (first.isAfter(today)) continue;
      add(
        title: 'Rent',
        minor: 4500000,
        type: TransactionType.expense,
        accountId: 'acc_bank',
        categoryId: 'cat_home',
        date: first,
        nature: TransactionNature.repeating,
        recurrence: const Recurrence(cadence: RecurrenceCadence.monthly),
      );
    }

    // ── Subscriptions ─────────────────────────────────────────────────────
    const subs = [
      ('Netflix', 110000, 'cat_fun', 7),
      ('Spotify', 65000, 'cat_fun', 12),
      ('Gym', 350000, 'cat_health', 3),
      ('iCloud', 13000, 'cat_bills', 18),
    ];
    for (final (name, minor, cat, day) in subs) {
      for (var back = 2; back >= 0; back--) {
        final when = DateTime(now.year, now.month - back, day);
        if (when.isAfter(today)) continue;
        add(
          title: name,
          minor: minor,
          type: TransactionType.expense,
          accountId: 'acc_mpesa',
          categoryId: cat,
          date: when,
          nature: TransactionNature.subscription,
          recurrence: const Recurrence(cadence: RecurrenceCadence.monthly),
        );
      }
    }

    // ── Utilities ─────────────────────────────────────────────────────────
    for (var back = 2; back >= 0; back--) {
      for (final (name, major, day) in const [
        ('Electricity (KPLC)', 3400, 10),
        ('Internet (Zuku)', 4100, 5),
        ('Water', 1200, 14),
      ]) {
        final when = DateTime(now.year, now.month - back, day);
        if (when.isAfter(today)) continue;
        add(
          title: name,
          minor: jitter(major, 0.18),
          type: TransactionType.expense,
          accountId: 'acc_mpesa',
          categoryId: 'cat_bills',
          date: when,
        );
      }
    }

    // ── Everyday spend, generated day by day ──────────────────────────────
    const everyday = [
      // (title, category, subcategory, typical major, probability per day)
      ('Morning coffee', 'cat_food', 'sub_coffee', 280, 0.55),
      ('Lunch', 'cat_food', 'sub_eating_out', 550, 0.45),
      ('Matatu', 'cat_transport', 'sub_matatu', 160, 0.5),
      ('Groceries', 'cat_food', 'sub_groceries', 3200, 0.16),
      ('Fuel', 'cat_transport', 'sub_fuel', 4500, 0.09),
      ('Airtime', 'cat_bills', null, 500, 0.14),
      ('Uber home', 'cat_transport', null, 850, 0.12),
      ('Snacks', 'cat_food', null, 320, 0.22),
    ];

    for (var daysAgo = 88; daysAgo >= 0; daysAgo--) {
      final day = today.subtract(Duration(days: daysAgo));
      for (final (title, cat, sub, major, probability) in everyday) {
        if (rng.nextDouble() > probability) continue;
        add(
          title: title,
          minor: jitter(major, 0.3),
          type: TransactionType.expense,
          accountId: rng.nextDouble() < 0.78 ? 'acc_mpesa' : 'acc_cash',
          categoryId: cat,
          subcategoryId: sub,
          // Spread the hour so a day's rows sort into a believable order
          // rather than all landing at midnight.
          date: day.add(Duration(hours: 7 + rng.nextInt(13))),
        );
      }
    }

    // ── Occasional larger spend ───────────────────────────────────────────
    const splurges = [
      ('Sneakers', 'cat_shopping', 8900, 64),
      ('Birthday dinner', 'cat_food', 6400, 41),
      ('Concert tickets', 'cat_fun', 4500, 33),
      ('Headphones', 'cat_shopping', 12500, 22),
      ('Dentist', 'cat_health', 7800, 17),
      ('Online course', 'cat_learning', 5600, 11),
      ('Weekend away', 'cat_fun', 15400, 6),
      ('New desk lamp', 'cat_home', 3400, 2),
    ];
    for (final (title, cat, major, daysAgo) in splurges) {
      add(
        title: title,
        minor: jitter(major, 0.1),
        type: TransactionType.expense,
        accountId: rng.nextDouble() < 0.5 ? 'acc_mpesa' : 'acc_bank',
        categoryId: cat,
        date: today.subtract(Duration(days: daysAgo, hours: -14)),
      );
    }

    // ── The added-only trip budget's own entries ──────────────────────────
    for (final (title, major, daysAgo) in const [
      ('Diani — matatu down', 2800, 10),
      ('Diani — Airbnb deposit', 18000, 8),
      ('Diani — snorkelling', 4500, 4),
    ]) {
      add(
        title: title,
        minor: _currency.toMinor(major.toDouble()),
        type: TransactionType.expense,
        accountId: 'acc_mpesa',
        categoryId: 'cat_fun',
        date: today.subtract(Duration(days: daysAgo)),
        budgetIds: const ['bud_trip'],
      );
    }

    // ── Topping up the spending wallet ────────────────────────────────────
    //
    // ⚠️ Not decoration. Salary lands in the bank and almost every expense
    // leaves M-Pesa, so without this the demo's primary wallet drains to a
    // five-figure negative over three months — and the first wallet card a
    // new user sees reads "−KSh 177,287", which looks like a broken app
    // rather than a furnished one. It is also simply what people do.
    for (var back = 3; back >= 0; back--) {
      for (final day in const [1, 16]) {
        final when = DateTime(now.year, now.month - back, day);
        if (when.isAfter(today)) continue;
        add(
          title: 'To M-Pesa',
          minor: 3500000,
          type: TransactionType.transfer,
          accountId: 'acc_bank',
          destinationAccountId: 'acc_mpesa',
          date: when.add(const Duration(hours: 9)),
        );
      }
    }

    // ── Cash withdrawals ──────────────────────────────────────────────────
    //
    // Roughly a fifth of the everyday spend above leaves the cash wallet, so
    // without a matching inflow it drains the same way M-Pesa did. A monthly
    // withdrawal is both the fix and what actually happens.
    for (var back = 3; back >= 0; back--) {
      final when = DateTime(now.year, now.month - back, 2);
      if (when.isAfter(today)) continue;
      add(
        title: 'Cash withdrawal',
        minor: 1200000,
        type: TransactionType.transfer,
        accountId: 'acc_mpesa',
        destinationAccountId: 'acc_cash',
        date: when.add(const Duration(hours: 11)),
      );
    }

    // ── Savings transfers, tagged to the emergency fund ───────────────────
    for (var back = 3; back >= 0; back--) {
      final when = DateTime(now.year, now.month - back, 29);
      if (when.isAfter(today)) continue;
      add(
        title: 'To savings',
        minor: 2500000,
        type: TransactionType.transfer,
        accountId: 'acc_bank',
        destinationAccountId: 'acc_usd',
        date: when,
        goalId: 'goal_emergency',
        note: 'Pay yourself first.',
      );
    }

    // ── A spending goal being saved toward ────────────────────────────────
    //
    // Out of the bank, not out of M-Pesa: salary lands in the bank, and
    // saving out of the spending wallet would both be odd behaviour and
    // drain the demo's primary wallet below zero.
    for (final daysAgo in [55, 40, 25, 12]) {
      add(
        title: 'MacBook fund',
        minor: 3500000,
        type: TransactionType.transfer,
        accountId: 'acc_bank',
        destinationAccountId: 'acc_usd',
        date: today.subtract(Duration(days: daysAgo)),
        goalId: 'goal_macbook',
      );
    }

    // ── Loans: one borrowed, one lent, one already settled ────────────────
    add(
      title: 'Borrowed from Wambui',
      minor: 1500000,
      type: TransactionType.income,
      accountId: 'acc_mpesa',
      date: today.subtract(const Duration(days: 19)),
      nature: TransactionNature.debt,
      isSettled: false,
      note: 'Said end of the month.',
    );
    add(
      title: 'Lent to Brian',
      minor: 500000,
      type: TransactionType.expense,
      accountId: 'acc_mpesa',
      date: today.subtract(const Duration(days: 7)),
      nature: TransactionNature.credit,
      isSettled: false,
    );
    add(
      title: 'Lent to Achieng',
      minor: 300000,
      type: TransactionType.expense,
      accountId: 'acc_cash',
      date: today.subtract(const Duration(days: 44)),
      nature: TransactionNature.credit,
      note: 'Paid back, all good.',
    );

    // ── Upcoming: one overdue, three ahead ────────────────────────────────
    add(
      title: 'Car insurance',
      minor: 2400000,
      type: TransactionType.expense,
      accountId: 'acc_bank',
      categoryId: 'cat_bills',
      date: today.subtract(const Duration(days: 3)),
      nature: TransactionNature.upcoming,
      isSettled: false,
      note: 'Meant to pay this on Monday.',
    );
    add(
      title: 'Rent',
      minor: 4500000,
      type: TransactionType.expense,
      accountId: 'acc_bank',
      categoryId: 'cat_home',
      date: DateTime(now.year, now.month + 1, 1),
      nature: TransactionNature.upcoming,
      isSettled: false,
      recurrence: const Recurrence(cadence: RecurrenceCadence.monthly),
    );
    add(
      title: 'Netflix',
      minor: 110000,
      type: TransactionType.expense,
      accountId: 'acc_mpesa',
      categoryId: 'cat_fun',
      date: today.add(const Duration(days: 5)),
      nature: TransactionNature.subscription,
      isSettled: false,
      recurrence: const Recurrence(cadence: RecurrenceCadence.monthly),
    );
    add(
      title: 'Birthday gift — Mum',
      minor: 600000,
      type: TransactionType.expense,
      accountId: 'acc_mpesa',
      categoryId: 'cat_shopping',
      date: today.add(const Duration(days: 11)),
      nature: TransactionNature.upcoming,
      isSettled: false,
    );

    // ── A gift received ───────────────────────────────────────────────────
    add(
      title: 'Birthday money',
      minor: 1000000,
      type: TransactionType.income,
      accountId: 'acc_mpesa',
      categoryId: 'cat_gifts',
      date: today.subtract(const Duration(days: 29)),
    );

    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }
}
