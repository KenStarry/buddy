import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../domain/currency.dart';
import '../../features/accounts/domain/model/account_model.dart';
import '../../features/budgets/domain/model/budget_model.dart';
import '../../features/categories/domain/model/category_model.dart';
import '../../features/goals/domain/model/goal_model.dart';
import '../../features/transactions/domain/model/transaction_model.dart';
import 'json_collection.dart';

/// Budgy's local store. Hive boxes, opened once at boot, owned here.
///
/// Everything in the app is local-first: the ledger *is* the box. There is no
/// server of record yet, which is why the repositories wrap this rather than a
/// `Dio` client — see `BudgyConfig` for where a backend would slot in.
class HiveService {
  HiveService._();

  static const transactionsBox = 'transactions';
  static const categoriesBox = 'categories';
  static const accountsBox = 'accounts';
  static const budgetsBox = 'budgets';
  static const goalsBox = 'goals';
  static const settingsBox = 'settings';

  // ───────────────────── Typed collections ─────────────────────────────────

  static final transactions = JsonCollection<TransactionModel>(
    boxName: transactionsBox,
    fromMap: TransactionModel.fromMap,
    toMap: (t) => t.toMap(),
    idOf: (t) => t.id,
  );

  static final categories = JsonCollection<CategoryModel>(
    boxName: categoriesBox,
    fromMap: CategoryModel.fromMap,
    toMap: (c) => c.toMap(),
    idOf: (c) => c.id,
  );

  static final accounts = JsonCollection<AccountModel>(
    boxName: accountsBox,
    fromMap: AccountModel.fromMap,
    toMap: (a) => a.toMap(),
    idOf: (a) => a.id,
  );

  static final budgets = JsonCollection<BudgetModel>(
    boxName: budgetsBox,
    fromMap: BudgetModel.fromMap,
    toMap: (b) => b.toMap(),
    idOf: (b) => b.id,
  );

  static final goals = JsonCollection<GoalModel>(
    boxName: goalsBox,
    fromMap: GoalModel.fromMap,
    toMap: (g) => g.toMap(),
    idOf: (g) => g.id,
  );

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(transactionsBox),
      Hive.openBox<String>(categoriesBox),
      Hive.openBox<String>(accountsBox),
      Hive.openBox<String>(budgetsBox),
      Hive.openBox<String>(goalsBox),
      Hive.openBox<dynamic>(settingsBox),
    ]);
  }

  // ───────────────────── Settings ──────────────────────────────────────────

  static const _kThemeMode = 'theme_mode';
  static const _kSchemeId = 'color_scheme_id';
  static const _kBaseCurrency = 'base_currency';
  static const _kHasSeeded = 'has_seeded';
  static const _kHasOnboarded = 'has_onboarded';
  static const _kHomeSections = 'home_sections';
  static const _kUserName = 'user_name';
  static const _kHideAmounts = 'hide_amounts';

  static Box<dynamic> get _settings => Hive.box<dynamic>(settingsBox);

  /// ⚠️ Defaults to **dark**, not `system`. Budgy's composition is designed
  /// on near-black (see `BudgyPalette`); light mode is the accommodation, and
  /// handing a first-time user whichever one their phone happens to be set to
  /// means half of them judge the app on the mode it was not designed in.
  /// Anyone who wants to follow the system can still say so — this is the
  /// default, not a restriction.
  static ThemeMode get themeMode => switch (_settings.get(_kThemeMode)) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static Future<void> setThemeMode(ThemeMode mode) =>
      _settings.put(_kThemeMode, mode.name);

  static String? get schemeId => _settings.get(_kSchemeId) as String?;
  static Future<void> setSchemeId(String id) => _settings.put(_kSchemeId, id);

  static Currency get baseCurrency =>
      CurrencyRegistry.byCode(_settings.get(_kBaseCurrency) as String?);
  static Future<void> setBaseCurrency(String code) =>
      _settings.put(_kBaseCurrency, code);

  static bool get hasSeeded => _settings.get(_kHasSeeded) == true;
  static Future<void> markSeeded() => _settings.put(_kHasSeeded, true);

  static bool get hasOnboarded => _settings.get(_kHasOnboarded) == true;
  static Future<void> markOnboarded() => _settings.put(_kHasOnboarded, true);

  static String? get userName {
    final raw = _settings.get(_kUserName) as String?;
    return (raw == null || raw.trim().isEmpty) ? null : raw.trim();
  }

  static Future<void> setUserName(String? name) => (name == null ||
          name.trim().isEmpty)
      ? _settings.delete(_kUserName)
      : _settings.put(_kUserName, name.trim());

  /// Privacy screen — blurs every amount so the app can be opened in public.
  static bool get hideAmounts => _settings.get(_kHideAmounts) == true;
  static Future<void> setHideAmounts(bool value) =>
      _settings.put(_kHideAmounts, value);

  /// Ordered list of enabled home-section keys. Null until the user
  /// rearranges them, so the default order lives in one place in code rather
  /// than being baked into a fresh install's storage.
  static List<String>? get homeSections {
    final raw = _settings.get(_kHomeSections);
    if (raw is! List) return null;
    return [for (final v in raw) v.toString()];
  }

  static Future<void> setHomeSections(List<String> keys) =>
      _settings.put(_kHomeSections, keys);

  // ───────────────────── Danger zone ──────────────────────────────────────

  /// Wipes the ledger but keeps device preferences.
  ///
  /// ⚠️ Theme, scheme and the onboarding flag are **re-applied** after the
  /// clear. They are properties of the device, not of the data: resetting the
  /// ledger and finding yourself back in light mode on the welcome carousel
  /// reads as the app having reinstalled itself.
  static Future<void> wipeLedger() async {
    final mode = themeMode;
    final scheme = schemeId;
    final currency = baseCurrency.code;
    final name = userName;
    final onboarded = hasOnboarded;

    await Future.wait([
      transactions.clear(),
      categories.clear(),
      accounts.clear(),
      budgets.clear(),
      goals.clear(),
      _settings.clear(),
    ]);

    await setThemeMode(mode);
    if (scheme != null) await setSchemeId(scheme);
    await setBaseCurrency(currency);
    await setUserName(name);
    if (onboarded) await markOnboarded();
  }
}
