import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/glass_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../budgets/presentation/components/budget_card.dart';
import '../../../goals/presentation/components/goal_card.dart';

/// Budgets and goals, under one roof.
///
/// They are kept together rather than given a tab each because they are the
/// same idea at two time scales — a budget is a ceiling this month, a goal is
/// a target by some month — and a five-tab nav bar on a phone is one tab too
/// many. The segmented control costs one tap and buys the whole fifth slot
/// back.
class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key, this.initialTab});

  /// `budgets` or `goals`, from the route's query string.
  final String? initialTab;

  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  late int _tab = widget.initialTab == 'goals' ? 1 : 0;

  @override
  void didUpdateWidget(covariant PlansPage old) {
    super.didUpdateWidget(old);
    // Honours a later deep link (the home screen's "See all" on goals), but
    // only when the query actually changed — otherwise every rebuild would
    // yank the user back to the tab the URL names.
    if (widget.initialTab != old.initialTab && widget.initialTab != null) {
      _tab = widget.initialTab == 'goals' ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final budgets = ref.watch(budgetProgressListProvider);
    final goals = ref.watch(goalProgressListProvider);
    final base = ref.watch(baseCurrencyProvider);
    final onBudgets = _tab == 0;

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
              eyebrow: 'Plans',
              title: onBudgets ? 'Budgets' : 'Goals',
              actions: [
                BudgyIconButton(
                  icon: LucideIcons.plus,
                  tone: c.accentSoft,
                  iconColor: c.accent,
                  onTap: () =>
                      context.pushNamed(onBudgets ? 'new-budget' : 'new-goal'),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          sliver: SliverToBoxAdapter(
            child: SegmentedPillTabs(
              labels: ['Budgets ${budgets.length}', 'Goals ${goals.length}'],
              index: _tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 22)),

        // A roll-up of the tab's own numbers, so the page says something
        // before you read a single card.
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          sliver: SliverToBoxAdapter(
            child: onBudgets
                ? _BudgetRollup(progress: budgets, currency: base)
                : _GoalRollup(progress: goals, currency: base),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 22)),

        if (onBudgets && budgets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              iconKey: 'piggy-bank',
              title: 'No budgets yet',
              message:
                  'A budget is just a number you’ve agreed with yourself. '
                  'Budgy does the watching.',
              actionLabel: 'Create your first',
              onAction: () => context.pushNamed('new-budget'),
            ),
          )
        else if (!onBudgets && goals.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              iconKey: 'flag',
              title: 'Nothing on the horizon',
              message:
                  'Name something you’re saving for. It’s much easier to '
                  'keep going when it has a name.',
              actionLabel: 'Set a goal',
              onAction: () => context.pushNamed('new-goal'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: BudgyConstants.gutter,
            ),
            sliver: SliverList.separated(
              itemCount: onBudgets ? budgets.length : goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final card = onBudgets
                    ? BudgetCard(progress: budgets[index])
                    : GoalCard(progress: goals[index]);
                return card
                    .animate(delay: (index.clamp(0, 8) * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.03, end: 0);
              },
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: BudgyConstants.navReserve),
        ),
      ],
    );
  }
}

class _BudgetRollup extends StatelessWidget {
  const _BudgetRollup({required this.progress, required this.currency});

  final List<BudgetProgress> progress;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) return const SizedBox.shrink();
    final c = context.budgyColors;
    final totalLimit = progress.fold<int>(0, (s, p) => s + p.limitMinor);
    final totalSpent = progress.fold<int>(0, (s, p) => s + p.spentMinor);
    final overCount = progress.where((p) => p.isOver).length;

    // Glass, like the cards it is summarising — a flat panel above a column
    // of lit ones reads as a different component that wandered in.
    return GlassCard(
      tint: c.accent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACROSS EVERY BUDGET',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: c.text300,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MoneyText(
                      totalLimit - totalSpent,
                      currency: currency,
                      size: MoneySize.display,
                      showDecimals: false,
                      symbolTrailing: true,
                    ),
                    Text(
                      ' left',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (overCount > 0)
            StatusPill(label: '$overCount over', tint: c.errorMain),
        ],
      ),
    );
  }
}

class _GoalRollup extends StatelessWidget {
  const _GoalRollup({required this.progress, required this.currency});

  final List<GoalProgress> progress;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) return const SizedBox.shrink();
    final c = context.budgyColors;
    final saved = progress.fold<int>(0, (s, p) => s + p.savedMinor);
    final target = progress.fold<int>(0, (s, p) => s + p.targetMinor);
    final done = progress.where((p) => p.isComplete).length;

    // Glass, like the cards it is summarising — a flat panel above a column
    // of lit ones reads as a different component that wandered in.
    return GlassCard(
      tint: c.accent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUT AWAY SO FAR',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: c.text300,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MoneyText(
                      saved,
                      currency: currency,
                      size: MoneySize.display,
                      showDecimals: false,
                      symbolTrailing: true,
                    ),
                    Text(
                      ' of ',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: c.text300,
                      ),
                    ),
                    MoneyText(
                      target,
                      currency: currency,
                      size: MoneySize.small,
                      color: c.text300,
                      showDecimals: false,
                      showSymbol: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (done > 0)
            StatusPill(
              label: '$done reached',
              tint: c.successMain,
              icon: LucideIcons.check,
            ),
        ],
      ),
    );
  }
}
