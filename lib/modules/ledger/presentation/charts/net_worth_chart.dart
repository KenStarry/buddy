import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/functions/money_format.dart';
import '../../domain/ledger_values.dart';

/// Net worth over time. A single-series line with an area wash underneath.
///
/// Trend over time → line. One series, so **no legend**: the section title
/// names it, and a legend box for one thing is chrome. A crosshair tooltip
/// ships by default, because an interactive chart that cannot be interrogated
/// is a picture of a chart.
class NetWorthChart extends StatelessWidget {
  const NetWorthChart({
    super.key,
    required this.points,
    required this.currency,
    this.height = 170,
  });

  final List<SeriesPoint> points;
  final Currency currency;
  final double height;

  /// Rounds a raw interval up to the nearest 1 / 2 / 2.5 / 5 × 10ⁿ — the
  /// steps people actually read an axis in.
  static double _niceStep(double raw) {
    if (raw <= 0 || raw.isNaN || raw.isInfinite) return 1;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalised = raw / magnitude;
    final snapped = normalised <= 1
        ? 1.0
        : normalised <= 2
        ? 2.0
        : normalised <= 2.5
        ? 2.5
        : normalised <= 5
        ? 5.0
        : 10.0;
    return snapped * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough history yet — give it a few days.',
            style: context.textTheme.bodySmall?.copyWith(color: c.text300),
          ),
        ),
      );
    }

    final values = [for (final p in points) p.minor.toDouble()];
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);

    // ⚠️ Snapped to round numbers, not just padded.
    //
    // Padding the raw extremes gives ticks like 301.6k / 332.3k / 498.4k —
    // values nobody thinks in, and the bottom two land close enough together
    // to collide into a grey smudge, because fl_chart draws a label at `minY`
    // *and* at every interval from it. Rounding the band outward to a whole
    // step puts every tick on a number a person would say out loud and
    // guarantees the labels are one full step apart.
    //
    // The band is also never allowed to collapse: a flat series gives
    // min == max, which makes the interval zero and renders nothing at all.
    final rawSpan = (rawMax - rawMin).abs();
    final step = _niceStep(
      (rawSpan < 1 ? (rawMax.abs() * 0.2 + 100) : rawSpan) / 3,
    );
    final minY = (rawMin / step).floor() * step;
    final maxY = (rawMax / step).ceil() * step +
        // Keeps a flat series from producing minY == maxY.
        (rawSpan < 1 ? step : 0);

    final line = Color.lerp(c.accent, c.accentPop, 0.1)!;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          // Recessive chrome: horizontal guides only, in the divider colour,
          // no vertical grid and no border box.
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) => FlLine(
              color: c.divider,
              strokeWidth: 1,
              dashArray: const [4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: step,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    MoneyFormat.compact(value.round(), currency),
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
                reservedSize: 26,
                // Four ticks regardless of the range's length, so a 30-day
                // and a 365-day view both read cleanly instead of one of them
                // collapsing into overlapping labels.
                interval: ((points.length - 1) / 3).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('d MMM').format(points[index].date),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: c.text300,
                        fontSize: 9.5,
                        letterSpacing: 0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => c.text100,
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 8,
              ),
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${DateFormat('d MMM').format(points[spot.x.round()].date)}\n'
                    '${MoneyFormat.amount(spot.y.round(), currency, showDecimals: false)}',
                    context.textTheme.labelMedium!.copyWith(
                      color: c.surface200,
                    ),
                  ),
              ],
            ),
            getTouchedSpotIndicator: (barData, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(color: c.text300, strokeWidth: 1),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 5,
                          color: line,
                          // A 2px surface ring, so the marker reads as
                          // sitting on the line rather than merging with it.
                          strokeColor: c.surface200,
                          strokeWidth: 2,
                        ),
                  ),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].minor.toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.22,
              // Curves overshoot on a series with a step in it — a salary
              // day — and an overshooting net-worth line dips below a value
              // it never had.
              preventCurveOverShooting: true,
              barWidth: 2.5,
              isStrokeCapRound: true,
              color: line,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    line.withValues(alpha: 0.26),
                    line.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
