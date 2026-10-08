import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/glass_card.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/wavy_meter.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../domain/model/goal_model.dart';

/// A goal, as an object card.
///
/// ⚠️ Same [WavyMeter] as a budget, but **without** a pace marker, and that
/// absence is the whole distinction. A budget is a quantity racing a clock, so
/// 60% spent is fine on day 25 and alarming on day 5 — it needs the notch. A
/// goal is an amount filling up, with a deadline that is advisory rather than
/// a reset: there is no pace to be behind on, only a rate to keep up.
///
/// This replaces the old ring. The ring made the same point, but it made it in
/// a *different component*, which meant two progress languages in one app and
/// a card that carried a ring and a bar showing the same fraction twice.
class GoalCard extends ConsumerWidget {
  const GoalCard({
    super.key,
    required this.progress,
    this.compact = false,
    this.onTap,
    this.index = 0,
  });

  final GoalProgress progress;
  final bool compact;
  final VoidCallback? onTap;

  /// Position in its rail or list — mirrors the card's blooms so a row of them
  /// is not one image repeated.
  final int index;

  /// Shared with the budget rail so the home page has one rhythm.
  static const double railHeight = 224;
  static const double railWidth = 268;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final goal = progress.goal;
    final tint = c.categoryAt(goal.colorIndex);
    final ink = c.heroInk;
    final onPace = progress.isOnPace;
    final overdue = goal.isOverdue && !progress.isComplete;

    return GlassCard(
      tint: tint,
      flip: index.isOdd,
      width: compact ? railWidth : null,
      padding: const EdgeInsets.all(18),
      onTap:
          onTap ??
          () => context.pushNamed('goal', pathParameters: {'id': goal.id}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassGlyph(
                tint: tint,
                emoji: goal.emoji,
                icon: BudgyIcons.resolve(goal.iconKey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _deadlineLabel(goal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: overdue
                            ? c.errorMain
                            : ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress.fraction * 100).round()}%',
                style: context.textTheme.titleSmall?.copyWith(
                  fontFamily: 'Sora',
                  color: ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // A `Spacer` only where the height is bounded — see the note on
          // `BudgetCard`.
          if (compact) const Spacer() else const SizedBox(height: 20),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              progress.savedMinor,
              currency: goal.currency,
              size: compact ? MoneySize.display : MoneySize.hero,
              color: ink,
              showDecimals: false,
              symbolTrailing: true,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                'of ',
                style: context.textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
              Flexible(
                child: MoneyText(
                  goal.targetMinor,
                  currency: goal.currency,
                  size: MoneySize.small,
                  color: ink.withValues(alpha: 0.55),
                  showDecimals: false,
                  showSymbol: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          WavyMeter(
            fraction: progress.fraction,
            color: progress.isComplete ? c.successMain : tint,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              if (progress.isComplete)
                StatusPill(
                  label: goal.kind == GoalKind.spending
                      ? 'Ready to buy'
                      : 'Reached',
                  tint: c.successMain,
                  icon: LucideIcons.partyPopper,
                )
              else if (onPace == true)
                StatusPill(label: 'On pace', tint: c.successMain)
              else if (onPace == false)
                StatusPill(label: 'Behind', tint: c.warningMain)
              else
                StatusPill(label: 'No deadline', tint: c.text300),
              const Spacer(),
              if (!progress.isComplete) _PaceNote(progress: progress),
            ],
          ),
        ],
      ),
    );
  }

  static String _deadlineLabel(GoalModel goal) {
    final target = goal.targetDate;
    if (target == null) return 'No deadline';
    final days = goal.daysRemaining ?? 0;
    if (days < 0) return 'Was due ${target.fullLabel}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 31) return '$days days to go';
    final months = (days / 30).round();
    return '~$months ${months == 1 ? 'month' : 'months'} to go';
  }
}

class _PaceNote extends StatelessWidget {
  const _PaceNote({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final muted = c.heroInk.withValues(alpha: 0.55);
    final pace = progress.dailyPaceMinor;

    if (pace == null || pace <= 0) {
      return Row(
        children: [
          MoneyText(
            progress.remainingMinor,
            currency: progress.goal.currency,
            size: MoneySize.small,
            color: muted,
            showDecimals: false,
            showSymbol: false,
          ),
          Text(
            ' to go',
            style: context.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      );
    }
    return Row(
      children: [
        MoneyText(
          pace,
          currency: progress.goal.currency,
          size: MoneySize.small,
          color: muted,
          showDecimals: false,
          showSymbol: false,
        ),
        Text(
          '/day',
          style: context.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
