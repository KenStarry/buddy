import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../transactions/presentation/state/controllers/transactions_controller.dart';
import '../../../domain/model/budget_model.dart';
import '../providers/budgets_providers.dart';

part 'budgets_controller.g.dart';

@immutable
class BudgetsState {
  const BudgetsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<BudgetModel> items;
  final bool isLoading;
  final String? error;

  /// Pinned first, then by creation. Pinned budgets are what the home screen
  /// shows, so the order is the user's own answer to "which of these matter".
  List<BudgetModel> get ordered {
    final list = [...items];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final ac = a.createdAt, bc = b.createdAt;
      if (ac != null && bc != null) return ac.compareTo(bc);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<BudgetModel> get pinned => [for (final b in ordered) if (b.isPinned) b];

  BudgetModel? byId(String? id) =>
      id == null ? null : items.where((b) => b.id == id).firstOrNull;

  /// Budgets a transaction can be hand-added to.
  List<BudgetModel> get addable => [for (final b in ordered) if (b.isAddedOnly) b];

  BudgetsState copyWith({
    List<BudgetModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => BudgetsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class BudgetsController extends _$BudgetsController {
  @override
  BudgetsState build() {
    Future.microtask(load);
    return const BudgetsState(isLoading: true);
  }

  Future<void> load() async {
    final result = await ref.read(budgetsRepositoryProvider).getAll();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (items) => state = BudgetsState(items: items),
    );
  }

  Future<bool> save(BudgetModel budget) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final b in state.items) if (b.id != budget.id) b,
        budget,
      ],
      clearError: true,
    );
    final result = await ref.read(budgetsRepositoryProvider).save(budget);
    return result.fold((error) {
      state = previous.copyWith(error: error);
      return false;
    }, (_) => true);
  }

  Future<bool> togglePin(String id) {
    final existing = state.items.firstWhere((b) => b.id == id);
    return save(existing.copyWith(isPinned: !existing.isPinned));
  }

  Future<bool> delete(String id) async {
    final previous = state;
    state = state.copyWith(
      items: [for (final b in state.items) if (b.id != id) b],
      clearError: true,
    );
    final result = await ref.read(budgetsRepositoryProvider).delete(id);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) async {
        // Strip the budget id from every row that was hand-added to it, or
        // the ids pile up invisibly and a later budget reusing that id
        // inherits a stranger's transactions.
        await ref
            .read(transactionsControllerProvider.notifier)
            .cascadeRemoveBudget(id);
        return true;
      },
    );
  }
}
