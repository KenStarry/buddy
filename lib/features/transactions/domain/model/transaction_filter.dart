import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../enum/transaction_type.dart';
import 'transaction_model.dart';

/// How the ledger is narrowed. One immutable object so the filter sheet, the
/// active-filter chips and the matching logic cannot drift apart.
@immutable
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.query = '',
    this.types = const {},
    this.natures = const {},
    this.categoryIds = const {},
    this.accountIds = const {},
    this.from,
    this.to,
    this.minMinor,
    this.maxMinor,
    this.onlyUnsettled = false,
  });

  final String query;

  /// Empty means **all** — for every one of these sets. An empty set reading
  /// as "none" would make a freshly opened filter sheet hide the whole
  /// ledger.
  final Set<TransactionType> types;
  final Set<TransactionNature> natures;
  final Set<String> categoryIds;
  final Set<String> accountIds;

  final DateTime? from;
  final DateTime? to;
  final int? minMinor;
  final int? maxMinor;

  /// Bills due and loans open — the "what needs me" view.
  final bool onlyUnsettled;

  bool get isActive =>
      query.trim().isNotEmpty ||
      types.isNotEmpty ||
      natures.isNotEmpty ||
      categoryIds.isNotEmpty ||
      accountIds.isNotEmpty ||
      from != null ||
      to != null ||
      minMinor != null ||
      maxMinor != null ||
      onlyUnsettled;

  /// How many distinct conditions are on, for the chip's badge.
  int get activeCount => [
    query.trim().isNotEmpty,
    types.isNotEmpty,
    natures.isNotEmpty,
    categoryIds.isNotEmpty,
    accountIds.isNotEmpty,
    from != null || to != null,
    minMinor != null || maxMinor != null,
    onlyUnsettled,
  ].where((on) => on).length;

  bool matches(TransactionModel t) {
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      // Searches the note and the tags too, not only the title: people write
      // "paid back Brian" in a note and then look for "Brian".
      final haystack = [
        t.title,
        t.note ?? '',
        ...t.tags,
      ].join(' ').toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    if (types.isNotEmpty && !types.contains(t.type)) return false;
    if (natures.isNotEmpty && !natures.contains(t.nature)) return false;
    if (categoryIds.isNotEmpty) {
      // A subcategory match counts as its parent matching, so filtering by
      // "Food & Drink" does not silently exclude every coffee.
      final hit =
          (t.categoryId != null && categoryIds.contains(t.categoryId)) ||
          (t.subcategoryId != null && categoryIds.contains(t.subcategoryId));
      if (!hit) return false;
    }
    if (accountIds.isNotEmpty) {
      final hit =
          accountIds.contains(t.accountId) ||
          (t.destinationAccountId != null &&
              accountIds.contains(t.destinationAccountId));
      if (!hit) return false;
    }
    if (from != null && t.date.isBefore(from!)) return false;
    if (to != null && t.date.isAfter(to!)) return false;
    if (minMinor != null && t.amountMinor < minMinor!) return false;
    if (maxMinor != null && t.amountMinor > maxMinor!) return false;
    if (onlyUnsettled && t.isSettled) return false;
    return true;
  }

  TransactionFilter copyWith({
    String? query,
    Set<TransactionType>? types,
    Set<TransactionNature>? natures,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    int? minMinor,
    bool clearMin = false,
    int? maxMinor,
    bool clearMax = false,
    bool? onlyUnsettled,
  }) => TransactionFilter(
    query: query ?? this.query,
    types: types ?? this.types,
    natures: natures ?? this.natures,
    categoryIds: categoryIds ?? this.categoryIds,
    accountIds: accountIds ?? this.accountIds,
    from: clearFrom ? null : (from ?? this.from),
    to: clearTo ? null : (to ?? this.to),
    minMinor: clearMin ? null : (minMinor ?? this.minMinor),
    maxMinor: clearMax ? null : (maxMinor ?? this.maxMinor),
    onlyUnsettled: onlyUnsettled ?? this.onlyUnsettled,
  );

  @override
  List<Object?> get props => [
    query,
    types,
    natures,
    categoryIds,
    accountIds,
    from,
    to,
    minMinor,
    maxMinor,
    onlyUnsettled,
  ];
}
