import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_meter.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/theme/budgy_shadows.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';

/// **What is genuinely left to spend**, and at what daily rate that lasts to
/// the end of the window.
///
/// Budgy's answer to the question a person actually opens a budget app with —
/// *can I buy this?* A balance can't answer it (yes, but rent is due) and a
/// month-to-date total can't either (is 54,000 a lot?). One number, one rate,
/// one honest caveat.
///
/// ## Why this is no longer the dark hero card
///
/// It used to be a deep emerald gradient slab, which was right when it was the
/// first thing on the screen. The header band is that now, and two deep
/// surfaces on one page is none — the eye has to choose, and whichever it
/// picks the other one looks like a mistake. So the pulse keeps the page's
/// card language and earns its prominence from **scale and position** instead:
/// it is the first card below the fold, it carries the largest figure outside
/// the band, and it is the only card with a meter running its full width.
class PulseCard extends ConsumerWidget {
  const PulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final pulse = ref.watch(spendingPulseProvider);
    final base = ref.watch(baseCurrencyProvider);
    final perDay = pulse.perDayMinor;
    final radius = BorderRadius.circular(28);

    final meterTint = pulse.isOverspent
        ? c.errorMain
        : pulse.isAheadOfPace
        ? c.warningMain
        : c.accent;

    return PressScale(
      onTap: () => pulse.source == null
          ? context.pushNamed('new-budget')
          : context.pushNamed(
              'budget',
              pathParameters: {'id': pulse.source!.id},
            ),
      haptic: HapticLevel.medium,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: BudgyShadows.soft(context),
          // A breath of the brand in the top-right corner rather than a flat
          // fill. At this radius it is barely nameable as a colour, which is
          // the point: it stops the largest card on the page from reading as
          // an empty rectangle without turning it into a second hero.
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              c.surface200,
              Color.lerp(c.surface200, c.accentSoft, 0.75)!,
            ],
            stops: const [0.45, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: meterTint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      pulse.isOverspent
                          ? LucideIcons.triangleAlert
                          : LucideIcons.target,
                      size: 15,
                      color: meterTint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pulse.isOverspent ? 'OVER BY' : 'SAFE TO SPEND',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ),
                  _WindowChip(label: pulse.window.label),
                ],
              ),

              const SizedBox(height: 14),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MoneyText(
                  pulse.remainingMinor.abs(),
                  currency: base,
                  size: MoneySize.display,
                  color: pulse.isOverspent ? c.errorMain : c.text100,
                  showDecimals: false,
                  roll: true,
                ),
              ),

              const SizedBox(height: 15),

              BudgyMeter(
                fraction: pulse.fraction,
                pace: pulse.paceFraction,
                color: meterTint,
                height: 9,
              ),

              const SizedBox(height: 12),

              if (pulse.isOverspent)
                Text(
                  'Past your limit with ${pulse.daysLeft} '
                  '${pulse.daysLeft == 1 ? 'day' : 'days'} to go.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.text200,
                  ),
                )
              else if (perDay != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MoneyText(
                      perDay,
                      currency: base,
                      size: MoneySize.row,
                      color: c.text100,
                      showDecimals: false,
                    ),
                    Flexible(
                      child: Text(
                        ' a day for ${pulse.daysLeft} '
                        '${pulse.daysLeft == 1 ? 'day' : 'days'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: c.text200,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Last day of the window — spend it well.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.text200,
                  ),
                ),

              const SizedBox(height: 8),
              const _Footnote(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, end: 0);
  }
}

/// The caveat line. Two facts the headline deliberately folded in, spelled out
/// so the number is not magic: what has gone, and what is already promised.
class _Footnote extends ConsumerWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final pulse = ref.watch(spendingPulseProvider);
    final base = ref.watch(baseCurrencyProvider);
    final style = context.textTheme.bodySmall?.copyWith(color: c.text300);

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.arrowUpRight, size: 12, color: c.text300),
            const SizedBox(width: 3),
            Text('Spent ', style: style),
            MoneyText(
              pulse.spentMinor,
              currency: base,
              size: MoneySize.small,
              color: c.text300,
              showDecimals: false,
              showSymbol: false,
            ),
          ],
        ),
        if (pulse.committedUpcomingMinor > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 12, color: c.text300),
              const SizedBox(width: 3),
              Text('Due ', style: style),
              MoneyText(
                pulse.committedUpcomingMinor,
                currency: base,
                size: MoneySize.small,
                color: c.text300,
                showDecimals: false,
                showSymbol: false,
              ),
            ],
          ),
        // Says out loud when the allowance was inferred rather than set, so a
        // user without a budget is never shown a guess dressed as a limit.
        if (!pulse.isDerivedFromBudget)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.info, size: 12, color: c.text300),
              const SizedBox(width: 3),
              Text('From this month’s income', style: style),
            ],
          ),
      ],
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendar, size: 12, color: c.text300),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(color: c.text200),
          ),
        ],
      ),
    );
  }
}
