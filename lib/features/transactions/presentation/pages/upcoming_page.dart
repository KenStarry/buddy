import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/enum/transaction_type.dart';
import '../../domain/model/transaction_model.dart';
import '../components/transaction_row.dart';
import '../state/controllers/transactions_controller.dart';

/// Bills due, bills missed, and everything that repeats.
class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final overdue = ref.watch(overdueTransactionsProvider);
    final upcoming = ref.watch(upcomingTransactionsProvider(withinDays: 60));
    final recurring = ref.watch(recurringTransactionsProvider);
    final base = ref.watch(baseCurrencyProvider);

    final dueSoon = overdue.length + upcoming.length;

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    BudgyIconButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                18,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  eyebrow: 'Coming up',
                  title: dueSoon == 0 ? 'All clear' : 'What’s due',
                  subtitle: dueSoon == 0
                      ? null
                      : '$dueSoon ${dueSoon == 1 ? 'thing' : 'things'} waiting on you',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            if (overdue.isNotEmpty)
              _Group(
                eyebrow: 'Overdue',
                title: 'These slipped past',
                tint: c.errorMain,
                rows: overdue,
                base: base,
              ),

            if (upcoming.isNotEmpty)
              _Group(
                eyebrow: 'Scheduled',
                title: 'On the way',
                tint: c.infoMain,
                rows: upcoming,
                base: base,
              ),

            if (overdue.isEmpty && upcoming.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgyConstants.gutter,
                  ),
                  child: BudgyCard(
                    tone: BudgyCardTone.wash,
                    elevated: false,
                    child: const EmptyState(
                      compact: true,
                      iconKey: 'sparkles',
                      title: 'Nothing hanging over you',
                      message: 'No bills due and nothing overdue. Enjoy it.',
                    ),
                  ),
                ),
              ),

            if (recurring.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  BudgyConstants.gutter,
                  26,
                  BudgyConstants.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        eyebrow: 'Repeating',
                        title: 'Comes round again',
                        subtitle: 'Subscriptions and anything on a schedule',
                        trailing: _MonthlyTotal(rows: recurring, base: base),
                      ),
                      const SizedBox(height: 12),
                      BudgyCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            for (final t in recurring)
                              _RecurringRow(transaction: t),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: 40 + context.viewPadding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({
    required this.eyebrow,
    required this.title,
    required this.tint,
    required this.rows,
    required this.base,
  });

  final String eyebrow;
  final String title;
  final Color tint;
  final List<TransactionModel> rows;
  final Currency base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = rows.fold<int>(0, (sum, t) => sum + t.amountMinor);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        BudgyConstants.gutter,
        0,
        BudgyConstants.gutter,
        26,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              eyebrow: eyebrow,
              title: title,
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.budgyColors.text300,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    total,
                    currency: base,
                    size: MoneySize.title,
                    color: tint,
                    showDecimals: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BudgyCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Column(
                children: [
                  for (final t in rows)
                    _SettleableRow(transaction: t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A due row with a one-tap settle. Dismissible to the right so the common
/// case — "yes, I paid that" — is a single gesture rather than a trip into
/// the form.
class _SettleableRow extends ConsumerWidget {
  const _SettleableRow({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    return Dismissible(
      key: ValueKey('settle-${transaction.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          children: [
            Icon(LucideIcons.check, size: 18, color: c.successMain),
            const SizedBox(width: 8),
            Text(
              'Mark as paid',
              style: context.textTheme.labelLarge?.copyWith(
                color: c.successMain,
              ),
            ),
          ],
        ),
      ),
      // ⚠️ `confirmDismiss` returning false, not `onDismissed`. Settling does
      // not remove the row from the ledger — it changes it — so letting the
      // Dismissible actually dismiss would animate away a widget whose data
      // is still in the list, and Flutter would then assert on the duplicate
      // key when the list rebuilds.
      confirmDismiss: (_) async {
        await ref
            .read(transactionsControllerProvider.notifier)
            .settle(transaction.id);
        return false;
      },
      child: TransactionRow(
        transaction: transaction,
        showDate: true,
        dense: true,
        onTap: () => context.pushNamed(
          'transaction',
          pathParameters: {'id': transaction.id},
        ),
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final next = transaction.nextOccurrence;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          TransactionRow(
            transaction: transaction,
            dense: true,
            onTap: () => context.pushNamed(
              'transaction',
              pathParameters: {'id': transaction.id},
            ),
          ),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(left: 53, bottom: 6),
              child: Row(
                children: [
                  Icon(LucideIcons.repeat, size: 11, color: c.text300),
                  const SizedBox(width: 5),
                  Text(
                    '${transaction.recurrence?.label ?? 'Repeats'} · next '
                    '${next.relativeDayLabel}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.text300,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What the repeating set costs per month.
///
/// Normalises every cadence to a month, because a list mixing weekly and
/// yearly charges has no meaningful total otherwise — and "KSh 48,000" of
/// annual insurance sitting beside a KSh 650 weekly shop would read as the
/// insurance being the problem.
class _MonthlyTotal extends StatelessWidget {
  const _MonthlyTotal({required this.rows, required this.base});

  final List<TransactionModel> rows;
  final Currency base;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    var monthly = 0.0;
    for (final t in rows) {
      if (!t.type.isExpense) continue;
      final recurrence = t.recurrence;
      if (recurrence == null) continue;
      final interval = recurrence.interval < 1 ? 1 : recurrence.interval;
      final perMonth = switch (recurrence.cadence) {
        RecurrenceCadence.daily => 30.44 / interval,
        RecurrenceCadence.weekly => 4.35 / interval,
        RecurrenceCadence.monthly => 1 / interval,
        RecurrenceCadence.yearly => 1 / (12 * interval),
      };
      monthly += t.amountMinor * perMonth;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'A MONTH',
          style: context.textTheme.labelSmall?.copyWith(color: c.text300),
        ),
        const SizedBox(height: 2),
        MoneyText(
          monthly.round(),
          currency: base,
          size: MoneySize.title,
          showDecimals: false,
        ),
      ],
    );
  }
}
