import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/utils/functions/money_format.dart';
import '../../domain/ledger_values.dart';

/// Twelve weeks of spending, one square a day.
///
/// A heatmap is the right form for *magnitude across a grid*, and its colour
/// job is **sequential** — one hue, light to dark — not categorical. The
/// emerald ramp in `BudgyPalette.sequential` is monotonic in lightness with
/// ≥0.06 ΔL between steps, so the gradations are separable without relying on
/// hue at all.
///
/// ## Scaled to a percentile, not the maximum
///
/// ⚠️ Scaling to the single biggest day is how a heatmap becomes one dark
/// square in a field of near-white: rent, once a month, is 15× a normal day,
/// so every ordinary day lands in the bottom 7% of the ramp and the pattern
/// the chart exists to show disappears. Budgy scales to the **90th
/// percentile** of non-zero days and clamps above it, so the top of the ramp
/// means "a heavy day" and the texture of ordinary spending stays visible.
/// The outliers still read as the darkest squares; they just stop flattening
/// everything else.
class SpendHeatmap extends StatelessWidget {
  const SpendHeatmap({
    super.key,
    required this.days,
    required this.currency,
    this.onDayTap,
    this.cell = 15,
    this.gap = 4,
  });

  /// Daily spend, oldest first, zero-filled.
  final List<SeriesPoint> days;

  final Currency currency;
  final void Function(SeriesPoint point)? onDayTap;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    if (days.isEmpty) {
      return Text(
        'No spending yet.',
        style: context.textTheme.bodySmall?.copyWith(color: c.text300),
      );
    }

    final scale = _percentileScale(days);

    // Columns are weeks, Monday at the top. The first column is padded so the
    // rows line up with real weekdays — without the offset, every row label
    // is wrong for the first partial week and the whole grid is off by a day.
    final first = days.first.date;
    final leadingBlanks = first.weekday - DateTime.monday;
    final cells = <SeriesPoint?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      ...days,
    ];
    final weeks = (cells.length / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  for (var row = 0; row < 7; row++)
                    SizedBox(
                      height: cell + gap,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: gap + 2),
                          child: Text(
                            // Only alternate rows are labelled; seven stacked
                            // 9pt labels in a 15pt rhythm is a grey smear.
                            row.isEven ? _weekdayInitial(row) : '',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: c.text300,
                              fontSize: 9,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (var week = 0; week < weeks; week++)
                Column(
                  children: [
                    for (var row = 0; row < 7; row++)
                      _Cell(
                        point: _at(cells, week * 7 + row),
                        scale: scale,
                        size: cell,
                        gap: gap,
                        currency: currency,
                        onTap: onDayTap,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Legend(scale: scale, currency: currency, cell: cell, gap: gap),
      ],
    );
  }

  static SeriesPoint? _at(List<SeriesPoint?> cells, int index) =>
      index < cells.length ? cells[index] : null;

  static String _weekdayInitial(int row) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][row];

  /// The 90th percentile of non-zero days, with a floor so a quiet fortnight
  /// does not make a single 200-bob coffee render as the darkest possible day.
  static int _percentileScale(List<SeriesPoint> days) {
    final nonZero = [for (final d in days) if (d.minor > 0) d.minor]..sort();
    if (nonZero.isEmpty) return 1;
    final index = ((nonZero.length - 1) * 0.9).round();
    return nonZero[index].clamp(1, 1 << 62);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.point,
    required this.scale,
    required this.size,
    required this.gap,
    required this.currency,
    this.onTap,
  });

  final SeriesPoint? point;
  final int scale;
  final double size;
  final double gap;
  final Currency currency;
  final void Function(SeriesPoint point)? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final p = point;

    if (p == null) {
      return SizedBox(width: size + gap, height: size + gap);
    }

    // A zero day is the surface's tonal band, not the ramp's lightest step:
    // "nothing happened" and "a very small amount happened" must not look
    // like neighbours on the same scale.
    final isZero = p.minor <= 0;
    final t = (p.minor / scale).clamp(0.0, 1.0);
    final fill = isZero ? c.surface300 : c.sequentialAt(0.18 + t * 0.82);

    final tooltip =
        '${DateFormat('EEE d MMM').format(p.date)}'
        '${isZero ? ' · nothing spent' : ' · ${MoneyFormat.amount(p.minor, currency, showDecimals: false)}'}';

    return Padding(
      padding: EdgeInsets.only(right: gap, bottom: gap),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: onTap == null ? null : () => onTap!(p),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(size * 0.28),
              // Today gets a ring rather than a different fill, so it is
              // locatable without lying about its magnitude.
              border: p.date.isToday
                  ? Border.all(color: c.text100, width: 1.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.scale,
    required this.currency,
    required this.cell,
    required this.gap,
  });

  final int scale;
  final Currency currency;
  final double cell;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Row(
      children: [
        Text(
          'Quiet',
          style: context.textTheme.labelSmall?.copyWith(
            color: c.text300,
            letterSpacing: 0,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 7),
        for (final t in const [0.0, 0.25, 0.5, 0.75, 1.0])
          Padding(
            padding: EdgeInsets.only(right: gap),
            child: Container(
              width: cell * 0.8,
              height: cell * 0.8,
              decoration: BoxDecoration(
                color: t == 0
                    ? c.surface300
                    : c.sequentialAt(0.18 + t * 0.82),
                borderRadius: BorderRadius.circular(cell * 0.22),
              ),
            ),
          ),
        const SizedBox(width: 3),
        Text(
          'Heavy',
          style: context.textTheme.labelSmall?.copyWith(
            color: c.text300,
            letterSpacing: 0,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        // States the scale's top explicitly. A heatmap whose darkest shade is
        // unlabelled is a picture, not a chart.
        Text(
          'Heavy ≈ ${MoneyFormat.compact(scale, currency)}',
          style: context.textTheme.labelSmall?.copyWith(
            color: c.text300,
            letterSpacing: 0,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
