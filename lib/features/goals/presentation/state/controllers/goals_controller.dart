import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../transactions/presentation/state/controllers/transactions_controller.dart';
import '../../../domain/model/goal_model.dart';
import '../providers/goals_providers.dart';

part 'goals_controller.g.dart';

@immutable
class GoalsState {
  const GoalsState({this.items = const [], this.isLoading = false, this.error});

  final List<GoalModel> items;
  final bool isLoading;
  final String? error;

  List<GoalModel> get live {
    final list = [for (final g in items) if (!g.isArchived) g];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      // Soonest deadline first; undated goals sink to the bottom rather than
      // sorting as "year zero" and jumping to the top.
      final ad = a.targetDate, bd = b.targetDate;
      if (ad == null && bd == null) return a.name.compareTo(b.name);
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return list;
  }

  GoalModel? byId(String? id) =>
      id == null ? null : items.where((g) => g.id == id).firstOrNull;

  GoalsState copyWith({
    List<GoalModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => GoalsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class GoalsController extends _$GoalsController {
  @override
  GoalsState build() {
    Future.microtask(load);
    return const GoalsState(isLoading: true);
  }

  Future<void> load() async {
    final result = await ref.read(goalsRepositoryProvider).getAll();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (items) => state = GoalsState(items: items),
    );
  }

  Future<bool> save(GoalModel goal) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final g in state.items) if (g.id != goal.id) g,
        goal,
      ],
      clearError: true,
    );
    final result = await ref.read(goalsRepositoryProvider).save(goal);
    return result.fold((error) {
      state = previous.copyWith(error: error);
      return false;
    }, (_) => true);
  }

  Future<bool> togglePin(String id) {
    final existing = state.items.firstWhere((g) => g.id == id);
    return save(existing.copyWith(isPinned: !existing.isPinned));
  }

  Future<bool> archive(String id) {
    final existing = state.items.firstWhere((g) => g.id == id);
    return save(existing.copyWith(isArchived: true, isPinned: false));
  }

  Future<bool> delete(String id) async {
    final previous = state;
    state = state.copyWith(
      items: [for (final g in state.items) if (g.id != id) g],
      clearError: true,
    );
    final result = await ref.read(goalsRepositoryProvider).delete(id);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) async {
        await ref
            .read(transactionsControllerProvider.notifier)
            .cascadeRemoveGoal(id);
        return true;
      },
    );
  }
}
