import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../modules/ledger/presentation/charts/in_out_chart.dart';
import '../../../../modules/ledger/presentation/charts/net_worth_chart.dart';
import '../../../../modules/ledger/presentation/charts/spend_breakdown.dart';
import '../../../../modules/ledger/presentation/charts/spend_heatmap.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';

/// Reports.
///
/// ## One form per question
///
/// Each block here was chosen by the job its data does, not by what looks
/// impressive:
///
/// * **Net worth** — trend over time → a single-series line with an area
///   wash. No legend; the heading names the series.
/// * **In vs out** — above/below a baseline → diverging columns around zero,
///   warm pole down, cool pole up, neutral zero rule.
/// * **Where it went** — magnitude by identity → a part-to-whole strip over
///   ranked bars. Explicitly *not* a pie; see [SpendBreakdown].
/// * **Rhythm** — magnitude across a grid → a heatmap on a single-hue
///   sequential ramp.
/// * **The headline row** — single current values → stat tiles, not
///   one-bar charts.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  _Range _range = _Range.ninetyDays;

  @override
  Widget build(BuildContext context) {
    final base = ref.watch(baseCurrencyProvider);
    final netWorth = ref.watch(netWorthProvider);
    final series = ref.watch(netWorthSeriesProvider(days: _range.days));
    final monthly = ref.watch(monthlyTotalsProvider(months: _range.months));
    final spend = ref.watch(spendByCategoryProvider(days: _range.days));
    final daily = ref.watch(dailySpendProvider(days: 84));
    final totals = ref.watch(monthTotalsProvider);

    final rangeTotals = _rangeTotals(monthly);

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
              eyebrow: 'Reports',
              title: 'The shape of it',
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // The time range, as one row of chips above everything it governs.
        SliverToBoxAdapter(
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              children: [
                for (final range in _Range.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BudgyChip(
                      label: range.label,
                      selected: _range == range,
                      onTap: () => setState(() => _range = range),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 22)),

        // ── Headline stat tiles ─────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: BudgyConstants.gutter,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Net worth',
                    minor: netWorth,
                    currency: base,
                    icon: LucideIcons.landmark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Kept in ${DateFormat('MMM').format(DateTime.now())}',
                    minor: totals.netMinor,
                    currency: base,
                    icon: LucideIcons.piggyBank,
                    tint: totals.netMinor >= 0 ? null : context.budgyColors.errorMain,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),

        // ── Net worth ───────────────────────────────────────────────────────
        _Block(
          eyebrow: 'Net worth',
          title: 'Where you stand',
          subtitle: 'Every wallet, in ${base.code}, over ${_range.label.toLowerCase()}',
          child: NetWorthChart(points: series, currency: base),
        ),

        // ── In vs out ───────────────────────────────────────────────────────
        _Block(
          eyebrow: 'In vs out',
          title: 'Month by month',
          subtitle: rangeTotals.inflowMinor == 0
              ? null
              : 'Kept ${_pct(rangeTotals)} of what came in',
          child: InOutChart(months: monthly, currency: base),
        ),

        // ── Where it went ───────────────────────────────────────────────────
        _Block(
          eyebrow: 'Where it went',
          title: 'Ranked by category',
          subtitle: _range.label,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: SpendBreakdown(spend: spend, currency: base, maxRows: 8),
        ),

        // ── Rhythm ──────────────────────────────────────────────────────────
        _Block(
          eyebrow: 'Rhythm',
          title: 'Twelve weeks, one square a day',
          subtitle: 'Darker means a heavier day',
          child: SpendHeatmap(days: daily, currency: base),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: BudgyConstants.navReserve),
        ),
      ],
    );
  }

  static PeriodTotals _rangeTotals(
    List<({DateTime month, PeriodTotals totals})> monthly,
  ) => monthly.fold(
    const PeriodTotals(),
    (sum, m) => sum + m.totals,
  );

  static String _pct(PeriodTotals totals) {
    final rate = totals.savingsRate;
    return rate == null ? '—' : '${(rate * 100).round()}%';
  }
}

/// A titled card, as a sliver. Every report block is the same shape, so the
/// page reads as one document rather than a pile of widgets.
class _Block extends StatelessWidget {
  const _Block({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.subtitle,
    this.padding = const EdgeInsets.all(18),
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      BudgyConstants.gutter,
      0,
      BudgyConstants.gutter,
      30,
    ),
    sliver: SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: eyebrow, title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          BudgyCard(padding: padding, child: child),
        ],
      ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.02, end: 0),
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.minor,
    required this.currency,
    required this.icon,
    this.tint,
  });

  final String label;
  final int minor;
  final Currency currency;
  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final accent = tint ?? c.accent;
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
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: c.text300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyText(
            minor,
            currency: currency,
            size: MoneySize.title,
            showDecimals: false,
            color: tint,
          ),
        ],
      ),
    );
  }
}

/// The time ranges the page offers.
///
/// Each carries both a day count (for the daily series) and a month count
/// (for the monthly columns), because the two charts bucket differently and
/// deriving one from the other gives a column chart with a half-empty first
/// bar.
enum _Range { thirtyDays, ninetyDays, sixMonths, year }

extension on _Range {
  String get label => switch (this) {
    _Range.thirtyDays => '30 days',
    _Range.ninetyDays => '90 days',
    _Range.sixMonths => '6 months',
    _Range.year => 'A year',
  };

  int get days => switch (this) {
    _Range.thirtyDays => 30,
    _Range.ninetyDays => 90,
    _Range.sixMonths => 182,
    _Range.year => 365,
  };

  int get months => switch (this) {
    _Range.thirtyDays => 2,
    _Range.ninetyDays => 4,
    _Range.sixMonths => 6,
    _Range.year => 12,
  };
}
