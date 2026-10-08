import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../transactions/presentation/state/controllers/transactions_controller.dart';
import '../../../domain/enum/category_kind.dart';
import '../../../domain/model/category_model.dart';
import '../providers/categories_providers.dart';

part 'categories_controller.g.dart';

@immutable
class CategoriesState {
  const CategoriesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<CategoryModel> items;
  final bool isLoading;
  final String? error;

  /// Live categories of a kind, in the user's order. Archived ones are
  /// filtered here rather than at every call site: they must stay resolvable
  /// by id (historical rows point at them) while being absent from pickers.
  List<CategoryModel> ofKind(CategoryKind kind) => [
    for (final c in items)
      if (c.kind == kind && !c.isArchived) c,
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<CategoryModel> get expense => ofKind(CategoryKind.expense);
  List<CategoryModel> get income => ofKind(CategoryKind.income);

  /// Resolves a category OR a subcategory by id — subcategories are nested,
  /// so a flat `firstWhere` over [items] silently misses them and every
  /// subcategorised row renders as "Uncategorised".
  CategoryModel? byId(String? id) {
    if (id == null) return null;
    for (final c in items) {
      if (c.id == id) return c;
      for (final sub in c.subcategories) {
        if (sub.id == id) return sub;
      }
    }
    return null;
  }

  /// The top-level parent of a subcategory id, or the category itself.
  CategoryModel? parentOf(String? id) {
    if (id == null) return null;
    for (final c in items) {
      if (c.id == id) return c;
      if (c.subcategories.any((s) => s.id == id)) return c;
    }
    return null;
  }

  CategoriesState copyWith({
    List<CategoryModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => CategoriesState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class CategoriesController extends _$CategoriesController {
  @override
  CategoriesState build() {
    Future.microtask(load);
    return const CategoriesState(isLoading: true);
  }

  Future<void> load() async {
    final result = await ref.read(categoriesRepositoryProvider).getAll();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (items) => state = CategoriesState(items: items),
    );
  }

  Future<bool> save(CategoryModel category) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final c in state.items) if (c.id != category.id) c,
        category,
      ],
      clearError: true,
    );
    final result = await ref
        .read(categoriesRepositoryProvider)
        .save(category);
    return result.fold((error) {
      state = previous.copyWith(error: error);
      return false;
    }, (_) => true);
  }

  Future<void> reorder(List<CategoryModel> ordered) async {
    final renumbered = [
      for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(sortOrder: i),
    ];
    state = state.copyWith(
      items: [
        for (final c in state.items)
          renumbered.firstWhere((r) => r.id == c.id, orElse: () => c),
      ],
    );
    await ref.read(categoriesRepositoryProvider).saveAll(renumbered);
  }

  /// Archives rather than deletes when the category is in use.
  ///
  /// ⚠️ Hard-deleting a category orphans every transaction that referenced
  /// it, which turns a year of a user's ledger into "Uncategorised" with no
  /// way back. Archiving keeps history intact and removes it from the
  /// pickers, which is what "delete this category" actually means to someone
  /// who has been using it for months. The caller decides via [force] — the
  /// delete sheet offers the hard delete explicitly, and says what it costs.
  Future<bool> remove(String id, {bool force = false}) async {
    if (!force) {
      final existing = state.items.firstWhere(
        (c) => c.id == id,
        orElse: () => throw StateError('No category $id'),
      );
      return save(existing.copyWith(isArchived: true));
    }

    final previous = state;
    state = state.copyWith(
      items: [for (final c in state.items) if (c.id != id) c],
      clearError: true,
    );
    final result = await ref.read(categoriesRepositoryProvider).delete(id);
    return result.fold(
      (error) {
        state = previous.copyWith(error: error);
        return false;
      },
      (_) async {
        await ref
            .read(transactionsControllerProvider.notifier)
            .cascadeRemoveCategory(id);
        return true;
      },
    );
  }
}
