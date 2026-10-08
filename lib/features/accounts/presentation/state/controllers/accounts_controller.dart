import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/model/account_model.dart';
import '../providers/accounts_providers.dart';

part 'accounts_controller.g.dart';

@immutable
class AccountsState {
  const AccountsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AccountModel> items;
  final bool isLoading;
  final String? error;

  List<AccountModel> get live => [
    for (final a in items) if (!a.isArchived) a,
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  AccountModel? byId(String? id) =>
      id == null ? null : items.where((a) => a.id == id).firstOrNull;

  /// The wallet new entries default to. Falls through to the first live
  /// wallet, because a ledger with wallets but no primary must still be able
  /// to accept a transaction.
  AccountModel? get primary =>
      live.where((a) => a.isPrimary).firstOrNull ?? live.firstOrNull;

  AccountsState copyWith({
    List<AccountModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => AccountsState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class AccountsController extends _$AccountsController {
  @override
  AccountsState build() {
    Future.microtask(load);
    return const AccountsState(isLoading: true);
  }

  Future<void> load() async {
    final result = await ref.read(accountsRepositoryProvider).getAll();
    result.fold(
      (error) => state = state.copyWith(isLoading: false, error: error),
      (items) => state = AccountsState(items: items),
    );
  }

  Future<bool> save(AccountModel account) async {
    final previous = state;
    // ⚠️ Primary is exclusive, and it is demoted here rather than in the
    // form. Saving a second wallet with `isPrimary: true` from an edit screen
    // that doesn't know about the others leaves two primaries, and
    // `AccountsState.primary` then returns whichever sorts first — so the
    // default wallet changes depending on an unrelated reorder.
    final others = [
      for (final a in state.items)
        if (a.id != account.id)
          account.isPrimary ? a.copyWith(isPrimary: false) : a,
    ];
    state = state.copyWith(items: [...others, account], clearError: true);

    final repo = ref.read(accountsRepositoryProvider);
    final result = await repo.save(account);
    return result.fold((error) {
      state = previous.copyWith(error: error);
      return false;
    }, (_) async {
      if (account.isPrimary) await repo.saveAll(others);
      return true;
    });
  }

  Future<void> reorder(List<AccountModel> ordered) async {
    final renumbered = [
      for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(sortOrder: i),
    ];
    state = state.copyWith(
      items: [
        for (final a in state.items)
          renumbered.firstWhere((r) => r.id == a.id, orElse: () => a),
      ],
    );
    await ref.read(accountsRepositoryProvider).saveAll(renumbered);
  }

  /// Archives a wallet. Never hard-deletes: a wallet's id is on every
  /// transaction ever made in it, and a ledger row with no wallet has no
  /// balance to belong to.
  Future<bool> archive(String id) async {
    final existing = state.items.firstWhere(
      (a) => a.id == id,
      orElse: () => throw StateError('No wallet $id'),
    );
    return save(existing.copyWith(isArchived: true, isPrimary: false));
  }
}
