import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/functions/money_format.dart';
import '../../domain/ledger_values.dart';

/// Income and spending per month, as **diverging columns** around zero.
///
/// ## Why diverging and not grouped
///
/// Income beside spending looks like two series to tell apart, which would
/// make it a grouped bar in a categorical palette. It isn't: in and out are
/// *poles* of one quantity, and the thing the reader wants is the gap between
/// them and its sign. That is polarity — so the form is a diverging bar
/// around a baseline, with a warm pole, a cool pole, and a neutral zero line
/// between them. The month you earned less than you spent is then visible as
/// a shape, not as an arithmetic exercise.
///
/// Two series, so a legend is present; both are also direct-labeled by the
/// axis itself (up is in, down is out), so identity never rests on colour.
class InOutChart extends StatelessWidget {
  const InOutChart({
    super.key,
    required this.months,
    required this.currency,
    this.height = 210,
  });

  final List<({DateTime month, PeriodTotals totals})> months;
  final Currency currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    if (months.isEmpty) {
      return SizedBox(height: height);
    }

    final peak = months.fold<int>(0, (max, m) {
      final local = m.totals.inflowMinor > m.totals.outflowMinor
          ? m.totals.inflowMinor
          : m.totals.outflowMinor;
      return local > max ? local : max;
    });
    // A symmetric scale, so a month's bar height means the same thing above
    // and below the line. Asymmetric axes make a diverging chart lie.
    final bound = (peak <= 0 ? 1000 : peak) * 1.18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LegendDotFixed(color: c.inflow, label: 'Money in'),
            const SizedBox(width: 16),
            LegendDotFixed(color: c.outflow, label: 'Money out'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: -bound,
              maxY: bound,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: bound,
                getDrawingHorizontalLine: (value) => FlLine(
                  // The zero line is the neutral midpoint of the diverging
                  // scale and reads stronger than the guides either side.
                  color: value.abs() < 1 ? c.text300 : c.divider,
                  strokeWidth: value.abs() < 1 ? 1.2 : 1,
                  dashArray: value.abs() < 1 ? null : const [4, 6],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: bound,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.abs() < 1
                            ? '0'
                            : MoneyFormat.compact(value.round().abs(), currency),
                        textAlign: TextAlign.right,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: c.text300,
                          fontSize: 9.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= months.length) {
                        return const SizedBox.shrink();
                      }
                      final month = months[index].month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          DateFormat('MMM').format(month),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: month.month == DateTime.now().month
                                ? c.text100
                                : c.text300,
                            fontSize: 10,
                            letterSpacing: 0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => c.text100,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final m = months[group.x];
                    final isInflow = rod.toY >= 0;
                    return BarTooltipItem(
                      '${DateFormat('MMMM').format(m.month)}\n'
                      '${isInflow ? 'In' : 'Out'} '
                      '${MoneyFormat.amount(rod.toY.round().abs(), currency, showDecimals: false)}',
                      context.textTheme.labelMedium!.copyWith(
                        color: c.surface200,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    // 2px of surface between the two rods of a group, so the
                    // in and out bars of one month do not read as one bar
                    // crossing the axis.
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].totals.inflowMinor.toDouble(),
                        width: 9,
                        color: c.inflow,
                        borderRadius: const BorderRadius.vertical(
                          // 4px rounded data-end, square against the
                          // baseline — the bar grows from zero, so only the
                          // far end is rounded.
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: -months[i].totals.outflowMinor.toDouble(),
                        width: 9,
                        color: c.outflow,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A legend entry sized to its own content, for use in a `Row`.
///
/// Separate from [LegendDot], which expands to fill a column in a vertical
/// legend list.
class LegendDotFixed extends StatelessWidget {
  const LegendDotFixed({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(color: c.text200),
        ),
      ],
    );
  }
}
