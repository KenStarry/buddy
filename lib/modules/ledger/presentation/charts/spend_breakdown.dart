import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_meter.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../features/categories/domain/model/category_model.dart';
import '../../../../features/categories/presentation/state/controllers/categories_controller.dart';
import '../../domain/ledger_math.dart';
import '../../domain/ledger_values.dart';

/// Spend by category: a part-to-whole strip over a ranked bar list.
///
/// ## Why this and not a pie
///
/// The job here is **compare magnitude by identity**, and the default form for
/// that is a bar — not a pie. A donut also has a correctness problem Budgy
/// cannot design around: any two arcs can be compared at a glance, which puts
/// it on the all-pairs colour-separation list, where the validated palette is
/// only safe for *three* slots. Eight categories in a donut means pairs that
/// a colour-blind reader (and, for yellow-vs-orange, a full-colour reader)
/// genuinely cannot tell apart.
///
/// Ranked bars stack vertically, so only *adjacent* pairs touch — which is
/// the pairlist the palette was validated on — and every row carries its
/// glyph, its name, its amount and its share. Identity never rests on colour.
///
/// The strip on top is the one part-to-whole mark, horizontal, capped at six
/// segments with the tail folded into "Other", separated by 2px surface gaps.
class SpendBreakdown extends ConsumerWidget {
  const SpendBreakdown({
    super.key,
    required this.spend,
    required this.currency,
    this.maxRows = 8,
    this.stripSegments = 6,
    this.onCategoryTap,
  });

  final List<CategorySpend> spend;
  final Currency currency;

  /// Rows shown before the tail folds into "Other".
  final int maxRows;

  /// Segments in the strip before the tail folds.
  final int stripSegments;

  final void Function(String categoryId)? onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    if (spend.isEmpty) {
      return Text(
        'Nothing spent in this window yet.',
        style: context.textTheme.bodyMedium?.copyWith(color: c.text300),
      );
    }

    final categories = ref.watch(categoriesControllerProvider);
    final total = spend.fold<int>(0, (sum, s) => sum + s.minor);
    // Bars are scaled to the LARGEST slice, not to the total: scaled to the
    // total, a healthy spread of eight categories renders eight stubs and the
    // chart says nothing. Against the max, the ranking is legible.
    final maxSlice = spend.first.minor;

    final rows = _fold(spend, maxRows);
    final segments = _fold(spend, stripSegments);

    Color tintFor(CategorySpend s) {
      if (s.categoryId == _otherId) return c.text300;
      if (s.categoryId == LedgerMath.uncategorisedId) return c.text300;
      final category = categories.parentOf(s.categoryId);
      return c.categoryAt(category?.colorIndex ?? 0);
    }

    String nameFor(CategorySpend s) {
      if (s.categoryId == _otherId) return 'Everything else';
      if (s.categoryId == LedgerMath.uncategorisedId) return 'Uncategorised';
      return categories.byId(s.categoryId)?.name ?? 'Uncategorised';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoneyText(
          total,
          currency: currency,
          size: MoneySize.display,
          showDecimals: false,
        ),
        const SizedBox(height: 16),

        BudgyStackedMeter(
          height: 15,
          segments: [
            for (final s in segments)
              MeterSegment(
                fraction: s.minor.toDouble(),
                color: tintFor(s),
                label: nameFor(s),
              ),
          ],
        ),

        const SizedBox(height: 20),

        for (var i = 0; i < rows.length; i++)
          _RankRow(
            name: nameFor(rows[i]),
            spend: rows[i],
            tint: tintFor(rows[i]),
            currency: currency,
            fractionOfMax: maxSlice == 0 ? 0 : rows[i].minor / maxSlice,
            category: rows[i].categoryId == _otherId
                ? null
                : categories.parentOf(rows[i].categoryId),
            onTap:
                onCategoryTap == null || rows[i].categoryId == _otherId
                ? null
                : () => onCategoryTap!(rows[i].categoryId),
          ).animate(delay: (i * 55).ms).fadeIn(duration: 300.ms).slideX(
            begin: -0.015,
            end: 0,
          ),
      ],
    );
  }

  static const _otherId = '__other__';

  /// Keeps the top [limit] − 1 slices and folds the rest into one "Other".
  ///
  /// ⚠️ Folds rather than truncating. Dropping the tail leaves the segments
  /// adding up to less than the total printed directly above them, which is
  /// the chart contradicting itself in the same glance.
  static List<CategorySpend> _fold(List<CategorySpend> spend, int limit) {
    if (spend.length <= limit) return spend;
    final head = spend.take(limit - 1).toList();
    final tail = spend.skip(limit - 1);
    final tailTotal = tail.fold<int>(0, (sum, s) => sum + s.minor);
    final tailShare = tail.fold<double>(0, (sum, s) => sum + s.share);
    final tailCount = tail.fold<int>(0, (sum, s) => sum + s.transactionCount);
    return [
      ...head,
      CategorySpend(
        categoryId: _otherId,
        minor: tailTotal,
        share: tailShare,
        transactionCount: tailCount,
      ),
    ];
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.name,
    required this.spend,
    required this.tint,
    required this.currency,
    required this.fractionOfMax,
    required this.category,
    this.onTap,
  });

  final String name;
  final CategorySpend spend;
  final Color tint;
  final Currency currency;
  final double fractionOfMax;
  final CategoryModel? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryGlyph(
                  colorIndex: category?.colorIndex ?? 0,
                  iconKey: category?.iconKey,
                  emoji: category?.emoji,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Label ink, never the series colour — a tinted legend is
                    // harder to read and makes the colour do two jobs.
                    style: context.textTheme.titleSmall?.copyWith(
                      color: c.text100,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MoneyText(
                  spend.minor,
                  currency: currency,
                  size: MoneySize.row,
                  showDecimals: false,
                  showSymbol: false,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${(spend.share * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: c.text300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Padding(
              // Indented to the glyph's text column, so the bar reads as
              // belonging to the label above it rather than to the row.
              padding: const EdgeInsets.only(left: 40),
              child: _ThinBar(fraction: fractionOfMax, tint: tint),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 6px bar with a 3px rounded data-end, anchored to the baseline.
class _ThinBar extends StatelessWidget {
  const _ThinBar({required this.fraction, required this.tint});

  final double fraction;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: c.surface300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: 6,
            width: math.max(
              6,
              constraints.maxWidth * fraction.clamp(0.0, 1.0),
            ),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
