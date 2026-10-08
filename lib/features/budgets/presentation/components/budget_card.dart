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
import '../../domain/enum/budget_period.dart';

/// A budget, as an object card.
///
/// The hierarchy is deliberate and the same in both layouts: **what's left** is
/// the big number, the meter carries the pace, and the limit is a footnote.
/// Most budget UIs lead with "spent / limit", which asks the reader to do the
/// subtraction that was the only thing they wanted.
///
/// ⚠️ The meter is a [WavyMeter] **with** a pace marker, and that marker is
/// what separates a budget from a goal in this design language. A budget is a
/// quantity racing a clock, so 60% spent is fine on day 25 and alarming on day
/// 5; a goal is simply accumulating. Same component, and the presence of the
/// notch carries the whole distinction.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({
    super.key,
    required this.progress,
    this.compact = false,
    this.onTap,
    this.index = 0,
  });

  final BudgetProgress progress;

  /// Fixed-width, for the home rail.
  final bool compact;

  final VoidCallback? onTap;

  /// Position in its rail or list — mirrors the card's blooms so a row of them
  /// is not one image repeated.
  final int index;

  /// Height the home rail must reserve. Here rather than at the call site so
  /// the card and the rail cannot drift apart.
  static const double railHeight = 224;
  static const double railWidth = 268;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final budget = progress.budget;
    final tint = c.categoryAt(budget.colorIndex);
    final ink = c.heroInk;
    final health = progress.health;

    final healthTint = switch (health) {
      BudgetHealth.onTrack => c.successMain,
      BudgetHealth.ahead => c.warningMain,
      BudgetHealth.tight => c.warningMain,
      BudgetHealth.over => c.errorMain,
    };

    return GlassCard(
      tint: tint,
      flip: index.isOdd,
      width: compact ? railWidth : null,
      padding: const EdgeInsets.all(18),
      onTap:
          onTap ??
          () => context.pushNamed('budget', pathParameters: {'id': budget.id}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassGlyph(
                tint: tint,
                icon: BudgyIcons.resolve(budget.iconKey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compact
                          ? budget.period.label
                          : '${budget.period.label} · ${progress.window.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact && budget.isPinned)
                Icon(
                  LucideIcons.pin,
                  size: 14,
                  color: ink.withValues(alpha: 0.5),
                ),
            ],
          ),

          // ⚠️ A `Spacer` only where the height is actually bounded. The rail
          // card is sized by the rail, so flex works there; the full-width
          // card sits in a list with unbounded height, where a flex child
          // throws rather than degrading.
          if (compact) const Spacer() else const SizedBox(height: 20),

          // What's left — the number the card exists for.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              progress.remainingMinor.abs(),
              currency: budget.currency,
              size: compact ? MoneySize.display : MoneySize.hero,
              color: progress.isOver ? c.errorMain : ink,
              showDecimals: false,
              symbolTrailing: true,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                progress.isOver ? 'over, of ' : 'left of ',
                style: context.textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
              Flexible(
                child: MoneyText(
                  progress.limitMinor,
                  currency: budget.currency,
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
            pace: progress.paceFraction,
            color: progress.isOver ? c.errorMain : tint,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              StatusPill(label: health.label, tint: healthTint),
              const Spacer(),
              Text(
                progress.window.remainingDays == 1
                    ? '1 day left'
                    : '${progress.window.remainingDays} days left',
                style: context.textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),

          // The forecast only appears when there is one worth making — see
          // `BudgetProgress.runsOutOn`.
          if (!compact && progress.runsOutOn != null) ...[
            const SizedBox(height: 14),
            _Forecast(runsOut: progress.runsOutOn!),
          ],
        ],
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.runsOut});

  final DateTime runsOut;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final days = runsOut.daysFromNow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.heroInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.trendingUp, size: 15, color: c.warningMain),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'At this rate it runs out '),
                  TextSpan(
                    text: days <= 0
                        ? 'today'
                        : days == 1
                        ? 'tomorrow'
                        : 'on ${runsOut.dayLabel}',
                    style: TextStyle(color: c.warningMain),
                  ),
                ],
              ),
              style: context.textTheme.bodySmall?.copyWith(
                color: c.heroInk.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
