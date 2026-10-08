import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/budgy_meter.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../transactions/domain/enum/transaction_type.dart';
import '../../../transactions/presentation/components/transaction_row.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../domain/model/goal_model.dart';
import '../state/controllers/goals_controller.dart';

/// One goal, in full: the ring, the pace, and every contribution.
class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final progress = ref.watch(goalProgressProvider(goalId));

    if (progress == null) {
      return Scaffold(
        backgroundColor: c.surface100,
        body: SafeArea(
          child: Column(
            children: [
              _Chrome(onBack: () => context.pop()),
              const Expanded(
                child: EmptyState(
                  iconKey: 'circle-dashed',
                  title: 'That goal is gone',
                  message: 'It looks like it was deleted.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final goal = progress.goal;
    final tint = c.categoryAt(goal.colorIndex);
    final contributions = [
      for (final t in ref.watch(ledgerProvider))
        if (t.goalId == goal.id) t,
    ];

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Chrome(
                onBack: () => context.pop(),
                isPinned: goal.isPinned,
                onPin: () => ref
                    .read(goalsControllerProvider.notifier)
                    .togglePin(goalId),
                onEdit: () => context.pushNamed(
                  'edit-goal',
                  pathParameters: {'id': goalId},
                ),
                onDelete: () => _confirmDelete(context, ref),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  eyebrow: goal.kind.label,
                  title: goal.emoji == null
                      ? goal.name
                      : '${goal.emoji}  ${goal.name}',
                  subtitle: goal.note,
                  titleStyle: context.textTheme.headlineLarge,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      BudgyRing(
                        fraction: progress.fraction,
                        size: 158,
                        thickness: 13,
                        color: tint,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress.fraction * 100).round()}%',
                              style: context.textTheme.displayMedium,
                            ),
                            Text(
                              progress.isComplete ? 'there' : 'of the way',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: c.text300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MoneyText(
                            progress.savedMinor,
                            currency: goal.currency,
                            size: MoneySize.display,
                            showDecimals: false,
                            roll: true,
                          ),
                          Text(
                            '  of  ',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: c.text300,
                            ),
                          ),
                          MoneyText(
                            goal.targetMinor,
                            currency: goal.currency,
                            size: MoneySize.row,
                            color: c.text300,
                            showDecimals: false,
                            showSymbol: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _PaceStrip(progress: progress),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scaleXY(
                  begin: 0.98,
                  end: 1,
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: BudgyFilledButton(
                        label: 'Put money in',
                        icon: LucideIcons.plus,
                        width: double.infinity,
                        onTap: () async => context.pushNamed(
                          'new-transaction',
                          extra: TransactionPrefill(
                            goalId: goal.id,
                            // A contribution is a transfer by default: money
                            // moving into savings is not income, and logging
                            // it as income would inflate every month's
                            // in-figure with money you already had.
                            type: TransactionType.transfer,
                            title: goal.name,
                          ),
                        ),
                      ),
                    ),
                    if (goal.kind == GoalKind.spending &&
                        progress.isComplete) ...[
                      const SizedBox(width: 12),
                      BudgyTonalButton(
                        label: 'Spend it',
                        icon: LucideIcons.shoppingBag,
                        onTap: () => context.pushNamed(
                          'new-transaction',
                          extra: TransactionPrefill(
                            goalId: goal.id,
                            type: TransactionType.expense,
                            amountMinor: goal.targetMinor,
                            title: goal.name,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      eyebrow: 'Contributions',
                      title: contributions.isEmpty
                          ? 'Nothing yet'
                          : '${contributions.length} so far',
                    ),
                    const SizedBox(height: 12),
                    if (contributions.isEmpty)
                      BudgyCard(
                        tone: BudgyCardTone.wash,
                        elevated: false,
                        child: const EmptyState(
                          compact: true,
                          iconKey: 'piggy-bank',
                          title: 'The first one is the hardest',
                          message:
                              'Tag a transfer or a deposit to this goal and '
                              'it’ll start climbing.',
                        ),
                      )
                    else
                      BudgyCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            for (final t in contributions)
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this goal?'),
        content: const Text(
          'The transactions you tagged to it stay in your ledger — they just '
          'stop counting toward anything.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.budgyColors.errorMain),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(goalsControllerProvider.notifier).delete(goalId);
    if (context.mounted) context.pop();
  }
}

class _PaceStrip extends ConsumerWidget {
  const _PaceStrip({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final goal = progress.goal;
    final onPace = progress.isOnPace;
    final pace = progress.dailyPaceMinor;
    final complete = progress.isComplete;

    return Column(
      children: [
        if (complete)
          StatusPill(
            label: goal.kind == GoalKind.spending
                ? 'Funded — go and get it'
                : 'Reached. Well done.',
            tint: c.successMain,
            icon: LucideIcons.partyPopper,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPace == true)
                StatusPill(label: 'On pace', tint: c.successMain)
              else if (onPace == false)
                StatusPill(label: 'Behind pace', tint: c.warningMain)
              else
                StatusPill(label: 'No deadline set', tint: c.text300),
              if (pace != null && pace > 0) ...[
                const SizedBox(width: 10),
                Row(
                  children: [
                    MoneyText(
                      pace,
                      currency: goal.currency,
                      size: MoneySize.small,
                      color: c.text200,
                      showDecimals: false,
                    ),
                    Text(
                      '/day to land it',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        if (goal.targetDate != null) ...[
          const SizedBox(height: 9),
          Text(
            goal.isOverdue && !complete
                ? 'Was due ${goal.targetDate!.fullLabel}'
                : 'Due ${goal.targetDate!.fullLabel}',
            style: context.textTheme.bodySmall?.copyWith(
              color: goal.isOverdue && !complete ? c.errorMain : c.text300,
            ),
          ),
        ],
      ],
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.onBack,
    this.onEdit,
    this.onPin,
    this.onDelete,
    this.isPinned = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BudgyConstants.gutter,
        8,
        BudgyConstants.gutter,
        0,
      ),
      child: Row(
        children: [
          BudgyIconButton(icon: LucideIcons.arrowLeft, onTap: onBack),
          const Spacer(),
          if (onPin != null)
            BudgyIconButton(
              icon: isPinned ? LucideIcons.pinOff : LucideIcons.pin,
              iconColor: isPinned ? c.accent : null,
              onTap: onPin,
            ),
          if (onEdit != null) ...[
            const SizedBox(width: 9),
            BudgyIconButton(icon: LucideIcons.pencil, onTap: onEdit),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 9),
            BudgyIconButton(
              icon: LucideIcons.trash2,
              iconColor: c.errorMain,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
