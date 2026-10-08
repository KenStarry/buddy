import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/model/transaction_model.dart';
import '../providers/transactions_providers.dart';

part 'transactions_controller.g.dart';

@immutable
class TransactionsState {
  const TransactionsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  /// **Newest first.** The controller keeps this invariant on every mutation
  /// so no screen has to re-sort, and two screens cannot disagree about the
  /// order of the same ledger.
  final List<TransactionModel> items;
  final bool isLoading;
  final String? error;

  bool get isEmpty => items.isEmpty && !isLoading;

  TransactionsState copyWith({
    List<TransactionModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => TransactionsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class TransactionsController extends _$TransactionsController {
  @override
  TransactionsState build() {
    Future.microtask(load);
    return const TransactionsState(isLoading: true);
  }

  Future<void> load() async {
    final result = await ref.read(transactionsRepositoryProvider).getAll();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (items) => state = TransactionsState(items: _sorted(items)),
    );
  }

  /// Insert or replace, then persist.
  ///
  /// ⚠️ State is updated **before** the await and rolled back if the write
  /// fails. Awaiting first means a tap on "Save" leaves the sheet dismissed
  /// and the list unchanged for however long the disk takes, which reads as
  /// the save having silently failed.
  Future<bool> save(TransactionModel transaction) async {
    final previous = state;
    final next = [
      for (final t in state.items) if (t.id != transaction.id) t,
      transaction,
    ];
    state = state.copyWith(items: _sorted(next), clearError: true);

    final result = await ref
        .read(transactionsRepositoryProvider)
        .save(transaction);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> delete(String id) async {
    final previous = state;
    state = state.copyWith(
      items: [for (final t in state.items) if (t.id != id) t],
      clearError: true,
    );

    final result = await ref.read(transactionsRepositoryProvider).delete(id);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> deleteMany(Iterable<String> ids) async {
    final previous = state;
    final set = ids.toSet();
    state = state.copyWith(
      items: [for (final t in state.items) if (!set.contains(t.id)) t],
      clearError: true,
    );

    final result = await ref
        .read(transactionsRepositoryProvider)
        .deleteAll(set);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) => true,
    );
  }

  /// Marks an upcoming bill paid / a loan repaid, dating it today.
  ///
  /// ⚠️ Re-dates the row to **now** rather than leaving it on its due date.
  /// Settling a bill that was due three days ago is an event that happened
  /// today; leaving the old date backdates real money into a window the user
  /// has already reviewed, and silently changes last week's totals.
  Future<bool> settle(String id, {bool settled = true}) async {
    final existing = state.items.firstWhere(
      (t) => t.id == id,
      orElse: () => throw StateError('No transaction $id'),
    );
    return save(
      existing.copyWith(
        isSettled: settled,
        date: settled ? DateTime.now() : existing.date,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Adds or removes this row from an "added" budget.
  Future<bool> setBudgetMembership(
    String id,
    String budgetId, {
    required bool member,
  }) async {
    final existing = state.items.firstWhere((t) => t.id == id);
    final ids = existing.budgetIds.toSet();
    member ? ids.add(budgetId) : ids.remove(budgetId);
    return save(
      existing.copyWith(budgetIds: ids.toList(), updatedAt: DateTime.now()),
    );
  }

  /// Drops a category reference from every row that pointed at it, so a
  /// deleted category leaves no dangling ids behind.
  Future<void> cascadeRemoveCategory(String categoryId) async {
    final touched = [
      for (final t in state.items)
        if (t.categoryId == categoryId)
          t.copyWith(clearCategory: true, clearSubcategory: true)
        else if (t.subcategoryId == categoryId)
          t.copyWith(clearSubcategory: true),
    ];
    if (touched.isEmpty) return;
    await ref.read(transactionsRepositoryProvider).saveAll(touched);
    await load();
  }

  /// Same, for a deleted budget.
  Future<void> cascadeRemoveBudget(String budgetId) async {
    final touched = [
      for (final t in state.items)
        if (t.budgetIds.contains(budgetId))
          t.copyWith(
            budgetIds: [for (final b in t.budgetIds) if (b != budgetId) b],
          ),
    ];
    if (touched.isEmpty) return;
    await ref.read(transactionsRepositoryProvider).saveAll(touched);
    await load();
  }

  /// Same, for a deleted goal.
  Future<void> cascadeRemoveGoal(String goalId) async {
    final touched = [
      for (final t in state.items)
        if (t.goalId == goalId) t.copyWith(clearGoal: true),
    ];
    if (touched.isEmpty) return;
    await ref.read(transactionsRepositoryProvider).saveAll(touched);
    await load();
  }

  static List<TransactionModel> _sorted(List<TransactionModel> items) =>
      [...items]..sort((a, b) => b.date.compareTo(a.date));
}
