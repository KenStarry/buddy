import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/presentation/charts/spend_breakdown.dart';
import '../../../../modules/ledger/presentation/charts/spend_heatmap.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../accounts/presentation/components/wallet_deck.dart';
import '../../../budgets/presentation/components/budget_card.dart';
import '../../../goals/presentation/components/goal_card.dart';
import '../../../transactions/presentation/components/transaction_row.dart';

/// Horizontal gutter every home section shares. Rails break out of it so
/// their cards can run to the screen edge.
const _gutter = EdgeInsets.symmetric(horizontal: BudgyConstants.gutter);

/// A horizontally scrolling rail.
///
/// ⚠️ The rail itself has no horizontal padding; the gutter is applied as the
/// *list's* padding instead, so the first card lines up with the page's text
/// column and the last one can still scroll fully to the edge. Padding the
/// container clips the overscroll and the rail looks like a boxed-in list.
class _Rail extends StatelessWidget {
  const _Rail({required this.children, this.height});

  final List<Widget> children;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: _gutter,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) => children[index],
    ),
  );
}

// ───────────────────── Budgets ───────────────────────────────────────────────

class HomeBudgetsSection extends ConsumerWidget {
  const HomeBudgetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedBudgetProgressProvider);
    final all = ref.watch(budgetProgressListProvider);
    // Falls back to everything when nothing is pinned: a user who has made
    // budgets but not pinned any should see budgets, not an empty state
    // telling them to make some.
    final shown = pinned.isNotEmpty ? pinned : all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _gutter,
          child: SectionHeader(
            eyebrow: 'Budgets',
            title: pinned.isNotEmpty ? 'Pinned' : 'Your budgets',
            onAction: () => context.goNamed('plans'),
          ),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          Padding(
            padding: _gutter,
            child: BudgyCard(
              tone: BudgyCardTone.wash,
              elevated: false,
              child: EmptyState(
                compact: true,
                iconKey: 'piggy-bank',
                title: 'No budgets yet',
                message:
                    'Set one and Budgy can tell you what’s actually safe to '
                    'spend.',
                actionLabel: 'Create a budget',
                onAction: () => context.pushNamed('new-budget'),
              ),
            ),
          )
        else
          _Rail(
            // ⚠️ Owned by the card, not guessed here. Every previous value in
            // this slot was a measurement of whatever the card happened to
            // contain that week, and it stopped matching the moment the card
            // changed.
            height: BudgetCard.railHeight,
            children: [
              for (final (i, progress) in shown.indexed)
                BudgetCard(progress: progress, compact: true, index: i),
            ],
          ),
      ],
    );
  }
}

// ───────────────────── Goals ─────────────────────────────────────────────────

class HomeGoalsSection extends ConsumerWidget {
  const HomeGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedGoalProgressProvider);
    final all = ref.watch(goalProgressListProvider);
    final shown = pinned.isNotEmpty ? pinned : all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _gutter,
          child: SectionHeader(
            eyebrow: 'Goals',
            title: 'What you’re working toward',
            onAction: () =>
                context.goNamed('plans', queryParameters: {'tab': 'goals'}),
          ),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          Padding(
            padding: _gutter,
            child: BudgyCard(
              tone: BudgyCardTone.wash,
              elevated: false,
              child: EmptyState(
                compact: true,
                iconKey: 'flag',
                title: 'Nothing on the horizon',
                message: 'A goal gives the saving somewhere to go.',
                actionLabel: 'Set a goal',
                onAction: () => context.pushNamed('new-goal'),
              ),
            ),
          )
        else
          _Rail(
            height: GoalCard.railHeight,
            children: [
              for (final (i, progress) in shown.indexed)
                GoalCard(progress: progress, compact: true, index: i),
            ],
          ),
      ],
    );
  }
}

// ───────────────────── Wallets ───────────────────────────────────────────────

/// The wallet deck.
///
/// ⚠️ Carries **no** net-worth figure. It used to hang the total off the
/// section header's trailing slot, which put the single most important number
/// in the app in the smallest type on the screen, beside a subtitle, below the
/// fold. It is the header band's hero now; repeating it here would be the same
/// fact in two places, which is how two places end up disagreeing.
class HomeWalletsSection extends ConsumerWidget {
  const HomeWalletsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);
    final base = ref.watch(baseCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _gutter,
          child: SectionHeader(
            eyebrow: 'Wallets',
            title: 'Where it lives',
            onAction: () => context.pushNamed('wallets'),
          ),
        ),
        const SizedBox(height: 16),
        WalletDeck(
          balances: balances,
          base: base,
          onOpen: (balance) => context.pushNamed(
            'wallet',
            pathParameters: {'id': balance.account.id},
          ),
          onAdd: () => context.pushNamed('wallets'),
        ),
      ],
    );
  }
}

// ───────────────────── Upcoming & overdue ───────────────────────────────────

class HomeUpcomingSection extends ConsumerWidget {
  const HomeUpcomingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final overdue = ref.watch(overdueTransactionsProvider);
    final upcoming = ref.watch(upcomingTransactionsProvider(withinDays: 14));

    if (overdue.isEmpty && upcoming.isEmpty) return const SizedBox.shrink();

    // Overdue leads, always. An item that was due is strictly more urgent
    // than one that will be, and burying it under three future bills is the
    // whole reason people miss payments.
    final rows = [...overdue, ...upcoming].take(4).toList();

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Coming up',
            title: overdue.isNotEmpty ? 'Needs you' : 'On the way',
            onAction: () => context.pushNamed('upcoming'),
            trailing: overdue.isEmpty
                ? null
                : StatusPill(
                    label: '${overdue.length} overdue',
                    tint: c.errorMain,
                  ),
          ),
          const SizedBox(height: 12),
          BudgyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final t in rows)
                  TransactionRow(
                    transaction: t,
                    dense: true,
                    onTap: () => context.pushNamed(
                      'transaction',
                      pathParameters: {'id': t.id},
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

// ───────────────────── Where it went ────────────────────────────────────────

class HomeSpendSection extends ConsumerWidget {
  const HomeSpendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spend = ref.watch(pulseSpendByCategoryProvider);
    final base = ref.watch(baseCurrencyProvider);
    final pulse = ref.watch(spendingPulseProvider);

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Where it went',
            title: 'This window',
            subtitle: pulse.window.label,
            onAction: () => context.goNamed('reports'),
          ),
          const SizedBox(height: 14),
          BudgyCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: SpendBreakdown(spend: spend, currency: base, maxRows: 5),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── This month ───────────────────────────────────────────

class HomeThisMonthSection extends ConsumerWidget {
  const HomeThisMonthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final totals = ref.watch(monthTotalsProvider);
    final base = ref.watch(baseCurrencyProvider);
    final rate = totals.savingsRate;

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'This month',
            title: DateTime.now().monthLabel,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'In',
                  minor: totals.inflowMinor,
                  currency: base,
                  tint: c.inflow,
                  icon: LucideIcons.arrowDownLeft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Out',
                  minor: totals.outflowMinor,
                  currency: base,
                  tint: c.outflow,
                  icon: LucideIcons.arrowUpRight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BudgyCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totals.netMinor >= 0 ? 'KEPT' : 'SHORTFALL',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: c.text300,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MoneyText(
                        totals.netMinor,
                        currency: base,
                        size: MoneySize.display,
                        showDecimals: false,
                        color: totals.netMinor >= 0 ? c.text100 : c.errorMain,
                      ),
                    ],
                  ),
                ),
                // The savings rate only appears when there was income to take
                // it from. A "0% saved" badge on a month with no income
                // reports a failure that never had a chance to happen.
                if (rate != null) _RateBadge(rate: rate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.minor,
    required this.currency,
    required this.tint,
    required this.icon,
  });

  final String label;
  final int minor;
  final Currency currency;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return BudgyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: tint),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(color: c.text300),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyText(
            minor,
            currency: currency,
            size: MoneySize.title,
            showDecimals: false,
          ),
        ],
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final good = rate >= 0.1;
    final tint = rate < 0
        ? c.errorMain
        : good
        ? c.successMain
        : c.warningMain;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${(rate * 100).round()}%',
            style: context.textTheme.headlineSmall?.copyWith(color: tint),
          ),
          const SizedBox(height: 1),
          Text(
            'of income',
            style: context.textTheme.labelSmall?.copyWith(
              color: tint.withValues(alpha: 0.8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Rhythm (heatmap) ─────────────────────────────────────

class HomeHeatmapSection extends ConsumerWidget {
  const HomeHeatmapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(dailySpendProvider(days: 84));
    final base = ref.watch(baseCurrencyProvider);

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Rhythm',
            title: 'Twelve weeks of spending',
            subtitle: 'One square a day — darker means heavier',
          ),
          const SizedBox(height: 14),
          BudgyCard(
            child: SpendHeatmap(days: days, currency: base),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Recent ───────────────────────────────────────────────

class HomeRecentSection extends ConsumerWidget {
  const HomeRecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentTransactionsProvider(limit: 5));

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Activity',
            title: 'Lately',
            onAction: () => context.goNamed('ledger'),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            BudgyCard(
              tone: BudgyCardTone.wash,
              elevated: false,
              child: EmptyState(
                compact: true,
                iconKey: 'receipt',
                title: 'A clean slate',
                message: 'Log something and it’ll show up here.',
                actionLabel: 'Add a transaction',
                onAction: () => context.pushNamed('new-transaction'),
              ),
            )
          else
            BudgyCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (final t in recent)
                    TransactionRow(
                      transaction: t,
                      showDate: true,
                      dense: true,
                      onTap: () => context.pushNamed(
                        'transaction',
                        pathParameters: {'id': t.id},
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

// ───────────────────── Lent & borrowed ──────────────────────────────────────

class HomeLoansSection extends ConsumerWidget {
  const HomeLoansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final loans = ref.watch(openLoansProvider);
    if (loans.isEmpty) return const SizedBox.shrink();

    final position = ref.watch(loanPositionProvider);
    final base = ref.watch(baseCurrencyProvider);

    return Padding(
      padding: _gutter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'Lent & borrowed',
            title: 'Open with other people',
            onAction: () => context.pushNamed('loans'),
          ),
          const SizedBox(height: 12),
          BudgyCard(
            child: Row(
              children: [
                Expanded(
                  child: _LoanLeg(
                    label: 'Owed to you',
                    minor: position.inflowMinor,
                    currency: base,
                    tint: c.successMain,
                    iconKey: 'handshake',
                  ),
                ),
                Container(width: 1, height: 40, color: c.divider),
                Expanded(
                  child: _LoanLeg(
                    label: 'You owe',
                    minor: position.outflowMinor,
                    currency: base,
                    tint: c.warningMain,
                    iconKey: 'hand-coins',
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

class _LoanLeg extends StatelessWidget {
  const _LoanLeg({
    required this.label,
    required this.minor,
    required this.currency,
    required this.tint,
    required this.iconKey,
  });

  final String label;
  final int minor;
  final Currency currency;
  final Color tint;
  final String iconKey;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(BudgyIcons.resolve(iconKey), size: 14, color: tint),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(color: c.text300),
              ),
            ],
          ),
          const SizedBox(height: 9),
          MoneyText(
            minor,
            currency: currency,
            size: MoneySize.title,
            showDecimals: false,
          ),
        ],
      ),
    );
  }
}
