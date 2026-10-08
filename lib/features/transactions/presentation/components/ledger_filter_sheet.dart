import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../accounts/presentation/state/controllers/accounts_controller.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../../domain/enum/transaction_type.dart';
import '../state/controllers/ledger_filter_controller.dart';

/// The ledger's filter panel.
///
/// Every control is a chip and every chip is a toggle, so the whole sheet
/// reads as one grammar — there is no mode where a tap means something
/// different. Filters apply **live** as they are tapped, with no Apply
/// button: the list behind the sheet is the preview, and an Apply button
/// would hide the effect of the thing you just tapped.
class LedgerFilterSheet extends ConsumerWidget {
  const LedgerFilterSheet({super.key});

  static Future<void> show(BuildContext context) => BudgySheet.show<void>(
    context,
    builder: (_) => const LedgerFilterSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final filter = ref.watch(ledgerFilterControllerProvider);
    final controller = ref.read(ledgerFilterControllerProvider.notifier);
    final categories = ref.watch(categoriesControllerProvider);
    final accounts = ref.watch(accountsControllerProvider);
    final count = ref.watch(filteredCountProvider);

    return BudgySheet(
      title: 'Narrow it down',
      subtitle: '$count ${count == 1 ? 'entry' : 'entries'} match right now',
      scrollable: true,
      trailing: filter.isActive
          ? BudgyChip(
              label: 'Reset',
              icon: LucideIcons.rotateCcw,
              dense: true,
              onTap: controller.clearFilters,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Group(
            label: 'Direction',
            children: [
              for (final type in TransactionType.values)
                BudgyChip(
                  label: type.label,
                  icon: switch (type) {
                    TransactionType.expense => LucideIcons.arrowUpRight,
                    TransactionType.income => LucideIcons.arrowDownLeft,
                    TransactionType.transfer => LucideIcons.arrowLeftRight,
                  },
                  selected: filter.types.contains(type),
                  onTap: () => controller.toggleType(type),
                ),
            ],
          ),

          _Group(
            label: 'Kind',
            children: [
              for (final nature in TransactionNature.values)
                BudgyChip(
                  label: nature.label,
                  selected: filter.natures.contains(nature),
                  onTap: () => controller.toggleNature(nature),
                  dense: true,
                ),
            ],
          ),

          _Group(
            label: 'Status',
            children: [
              BudgyChip(
                label: 'Not settled yet',
                icon: LucideIcons.clock,
                selected: filter.onlyUnsettled,
                onTap: () =>
                    controller.setOnlyUnsettled(!filter.onlyUnsettled),
              ),
            ],
          ),

          _Group(
            label: 'When',
            children: [
              for (final preset in _DatePreset.values)
                BudgyChip(
                  label: preset.label,
                  dense: true,
                  selected: preset.matches(filter.from, filter.to),
                  onTap: () {
                    final range = preset.range();
                    controller.setRange(range?.$1, range?.$2);
                  },
                ),
            ],
          ),

          _Group(
            label: 'Categories',
            children: [
              for (final category in [
                ...categories.expense,
                ...categories.income,
              ])
                BudgyChip(
                  label: category.name,
                  emoji: category.emoji,
                  dense: true,
                  // The chip wears the category's own colour when selected,
                  // so the filter row and the ledger rows below it speak the
                  // same colour language.
                  tint: c.categoryAt(category.colorIndex),
                  selected: filter.categoryIds.contains(category.id),
                  onTap: () => controller.toggleCategory(category.id),
                ),
            ],
          ),

          _Group(
            label: 'Wallets',
            children: [
              for (final account in accounts.live)
                BudgyChip(
                  label: account.name,
                  dense: true,
                  tint: c.categoryAt(account.colorIndex),
                  selected: filter.accountIds.contains(account.id),
                  onTap: () => controller.toggleAccount(account.id),
                ),
            ],
          ),

          const SizedBox(height: 10),
          BudgyFilledButton(
            label: 'Show $count',
            width: double.infinity,
            onTap: () async => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 11),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

/// The date ranges worth one tap. Anything else is the full picker, which
/// this sheet deliberately does not have — a filter panel that opens a
/// calendar dialog is two modals deep for a question usually answered by
/// "this month".
enum _DatePreset { any, thisWeek, thisMonth, lastMonth, thisYear }

extension on _DatePreset {
  String get label => switch (this) {
    _DatePreset.any => 'Any time',
    _DatePreset.thisWeek => 'This week',
    _DatePreset.thisMonth => 'This month',
    _DatePreset.lastMonth => 'Last month',
    _DatePreset.thisYear => 'This year',
  };

  /// `(from, to)`, or null for no constraint.
  (DateTime, DateTime)? range() {
    final now = DateTime.now();
    // ⚠️ Each `to` is the last microsecond of its last day, not midnight on
    // it. `TransactionFilter` compares with `isAfter`, so a `to` at midnight
    // silently excludes everything logged on the final day of the range —
    // including, for "this month", everything from today.
    return switch (this) {
      _DatePreset.any => null,
      _DatePreset.thisWeek => (
        now.startOfWeek,
        _endOfDay(
          DateTime(
            now.startOfWeek.year,
            now.startOfWeek.month,
            now.startOfWeek.day + 6,
          ),
        ),
      ),
      _DatePreset.thisMonth => (now.startOfMonth, now.endOfMonth),
      _DatePreset.lastMonth => (
        DateTime(now.year, now.month - 1),
        _endOfDay(DateTime(now.year, now.month, 0)),
      ),
      _DatePreset.thisYear => (
        now.startOfYear,
        _endOfDay(DateTime(now.year, 12, 31)),
      ),
    };
  }

  static DateTime _endOfDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999, 999);

  bool matches(DateTime? from, DateTime? to) {
    final mine = range();
    if (mine == null) return from == null && to == null;
    if (from == null) return false;
    return from.isSameDay(mine.$1);
  }
}
