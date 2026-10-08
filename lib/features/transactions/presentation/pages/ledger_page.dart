import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/domain/currency.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/model/transaction_model.dart';
import '../components/transaction_row.dart';
import '../components/ledger_filter_sheet.dart';
import '../state/controllers/ledger_filter_controller.dart';
import '../state/controllers/transactions_controller.dart';

/// The whole ledger: searchable, filterable, day-grouped, multi-selectable.
class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  final _searchController = TextEditingController();

  /// Non-empty puts the page in multi-select mode. Held here rather than in a
  /// provider because it is pure screen state — leaving the page should end
  /// the selection, and a `keepAlive` provider would resurrect it.
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final ids = _selected.toList();
    setState(_selected.clear);
    final ok = await ref
        .read(transactionsControllerProvider.notifier)
        .deleteMany(ids);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Deleted $count ${count == 1 ? 'entry' : 'entries'}.'
              : 'That didn’t go through. Give it another go?',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final groups = ref.watch(filteredLedgerProvider);
    final filter = ref.watch(ledgerFilterControllerProvider);
    final totals = ref.watch(filteredTotalsProvider);
    final count = ref.watch(filteredCountProvider);
    final base = ref.watch(baseCurrencyProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            BudgyConstants.gutter,
            context.viewPadding.top + 14,
            BudgyConstants.gutter,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: BudgyMasthead(
              eyebrow: _selecting ? '${_selected.length} selected' : 'Ledger',
              title: _selecting ? 'Pick and choose' : 'Everything',
              actions: _selecting
                  ? [
                      BudgyIconButton(
                        icon: LucideIcons.trash2,
                        iconColor: c.errorMain,
                        onTap: _deleteSelected,
                      ),
                      BudgyIconButton(
                        icon: LucideIcons.x,
                        onTap: () => setState(_selected.clear),
                      ),
                    ]
                  : [
                      BudgyIconButton(
                        icon: LucideIcons.listFilter,
                        badge: filter.activeCount > 0,
                        iconColor: filter.isActive ? c.accent : null,
                        onTap: () => LedgerFilterSheet.show(context),
                      ),
                    ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Search + the summary of what is currently matched.
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => ref
                      .read(ledgerFilterControllerProvider.notifier)
                      .setQuery(value),
                ),
                if (filter.isActive) ...[
                  const SizedBox(height: 14),
                  _FilterSummary(
                    count: count,
                    currency: base,
                    inflow: totals.inflowMinor,
                    outflow: totals.outflowMinor,
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(ledgerFilterControllerProvider.notifier)
                          .clear();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        if (groups.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: filter.isActive
                ? EmptyState(
                    iconKey: 'target',
                    title: 'Nothing matches',
                    message:
                        'Loosen the filters a little and we’ll find it again.',
                    actionLabel: 'Clear filters',
                    onAction: () {
                      _searchController.clear();
                      ref
                          .read(ledgerFilterControllerProvider.notifier)
                          .clear();
                    },
                  )
                : EmptyState(
                    iconKey: 'receipt',
                    title: 'Your ledger is empty',
                    message:
                        'Log the first thing you spent today — it takes about '
                        'four seconds.',
                    actionLabel: 'Add a transaction',
                    onAction: () => context.pushNamed('new-transaction'),
                  ),
          )
        else
          for (var g = 0; g < groups.length; g++)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                0,
                BudgyConstants.gutter,
                16,
              ),
              sliver: SliverToBoxAdapter(
                child: _DayGroup(
                  day: groups[g].day,
                  rows: groups[g].rows,
                  net: groups[g].totals.netMinor,
                  base: base,
                  selected: _selecting ? _selected : null,
                  onToggle: _toggle,
                  onLongPress: _toggle,
                ).animate(delay: (g.clamp(0, 6) * 40).ms).fadeIn(
                  duration: 280.ms,
                ),
              ),
            ),

        const SliverToBoxAdapter(
          child: SizedBox(height: BudgyConstants.navReserve),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search titles, notes, tags…',
        prefixIcon: Icon(LucideIcons.search, size: 18, color: c.text300),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(LucideIcons.x, size: 16, color: c.text300),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.count,
    required this.currency,
    required this.inflow,
    required this.outflow,
    required this.onClear,
  });

  final int count;
  final Currency currency;
  final int inflow;
  final int outflow;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return BudgyCard(
      tone: BudgyCardTone.wash,
      elevated: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'entry' : 'entries'}',
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      LucideIcons.arrowDownLeft,
                      size: 12,
                      color: c.inflow,
                    ),
                    const SizedBox(width: 3),
                    MoneyText(
                      inflow,
                      currency: currency,
                      size: MoneySize.small,
                      color: c.text200,
                      showDecimals: false,
                      showSymbol: false,
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      LucideIcons.arrowUpRight,
                      size: 12,
                      color: c.outflow,
                    ),
                    const SizedBox(width: 3),
                    MoneyText(
                      outflow,
                      currency: currency,
                      size: MoneySize.small,
                      color: c.text200,
                      showDecimals: false,
                      showSymbol: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          BudgyChip(label: 'Clear', icon: LucideIcons.x, onTap: onClear, dense: true),
        ],
      ),
    );
  }
}

/// One day's rows, under a header carrying the day's net.
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.rows,
    required this.net,
    required this.base,
    required this.onToggle,
    required this.onLongPress,
    this.selected,
  });

  final DateTime day;
  final List<TransactionModel> rows;
  final int net;
  final Currency base;
  final Set<String>? selected;
  final void Function(String id) onToggle;
  final void Function(String id) onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
          child: Row(
            children: [
              Text(
                day.relativeDayLabel.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const Spacer(),
              // The day's net, so scrolling the ledger reads as a sequence of
              // days rather than an undifferentiated list of rows.
              //
              // ⚠️ Suppressed at exactly zero. A day holding only *unsettled*
              // rows — a scheduled rent, a bill due next month — nets to zero
              // because plans do not count, and rendering that as a green
              // "KSh 0" says "nothing happened" directly above a 45,000
              // shilling row.
              if (net != 0)
                MoneyText(
                  net,
                  currency: base,
                  size: MoneySize.small,
                  color: net > 0 ? c.inflow : c.text300,
                  showDecimals: false,
                  signed: net > 0,
                ),
            ],
          ),
        ),
        BudgyCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final t in rows)
                TransactionRow(
                  transaction: t,
                  selected: selected?.contains(t.id),
                  onTap: selected != null
                      ? () => onToggle(t.id)
                      : () => context.pushNamed(
                          'transaction',
                          pathParameters: {'id': t.id},
                        ),
                  onLongPress: () => onLongPress(t.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
