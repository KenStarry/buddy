import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/presentation/state/controllers/accounts_controller.dart';
import '../../features/budgets/presentation/state/controllers/budgets_controller.dart';
import '../../features/categories/presentation/state/controllers/categories_controller.dart';
import '../../features/goals/presentation/state/controllers/goals_controller.dart';
import '../../features/transactions/presentation/state/controllers/transactions_controller.dart';
import '../utils/budgy_constants.dart';
import 'hive_service.dart';
import 'ledger_seed.dart';

/// Gets the ledger into memory **before** the first frame.
///
/// The controllers all kick a `Future.microtask(load)` from `build()`, which
/// is the house pattern and correct — but it means the first frame renders
/// against an empty ledger, so the home screen opens on skeletons and every
/// chart pops in a beat later. Awaiting the first load here costs a handful
/// of milliseconds against an already-open Hive box and buys an app that is
/// simply *there* when it appears.
class LedgerBootstrap {
  LedgerBootstrap._();

  /// Seeds the demo ledger on a genuinely fresh install, then warms every
  /// controller.
  static Future<void> run(ProviderContainer container) async {
    await _seedIfNeeded();

    // Read each controller to construct it, then await its first load. Order
    // matters only in that transactions is the biggest — kicking them all off
    // and awaiting together keeps the total at the slowest, not the sum.
    final transactions = container.read(
      transactionsControllerProvider.notifier,
    );
    final categories = container.read(categoriesControllerProvider.notifier);
    final accounts = container.read(accountsControllerProvider.notifier);
    final budgets = container.read(budgetsControllerProvider.notifier);
    final goals = container.read(goalsControllerProvider.notifier);

    await Future.wait([
      transactions.load(),
      categories.load(),
      accounts.load(),
      budgets.load(),
      goals.load(),
    ]);
  }

  /// ⚠️ Gated on a **flag**, not on emptiness. Keying off "are the boxes
  /// empty" re-seeds the demo month every time a user deletes their last
  /// transaction — which is exactly when someone is clearing the demo out to
  /// start for real, and watching it grow back is the worst possible first
  /// impression.
  static Future<void> _seedIfNeeded() async {
    if (HiveService.hasSeeded) return;
    await HiveService.markSeeded();
    if (!BudgyConstants.seedDemoData) return;

    await Future.wait([
      HiveService.categories.putAll(LedgerSeed.categories()),
      HiveService.accounts.putAll(LedgerSeed.accounts()),
      HiveService.budgets.putAll(LedgerSeed.budgets()),
      HiveService.goals.putAll(LedgerSeed.goals()),
      HiveService.transactions.putAll(LedgerSeed.transactions()),
    ]);
  }

  /// Re-seeds from scratch. Wired to Settings → "Load the demo month".
  static Future<void> reseed(ProviderContainer container) async {
    await HiveService.wipeLedger();
    await HiveService.markSeeded();
    await Future.wait([
      HiveService.categories.putAll(LedgerSeed.categories()),
      HiveService.accounts.putAll(LedgerSeed.accounts()),
      HiveService.budgets.putAll(LedgerSeed.budgets()),
      HiveService.goals.putAll(LedgerSeed.goals()),
      HiveService.transactions.putAll(LedgerSeed.transactions()),
    ]);
    await run(container);
  }

  /// Empties the ledger and leaves it empty, keeping device preferences.
  static Future<void> clear(ProviderContainer container) async {
    await HiveService.wipeLedger();
    await HiveService.markSeeded();
    await run(container);
  }
}
