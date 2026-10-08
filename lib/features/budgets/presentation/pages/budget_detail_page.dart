import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/budgy_meter.dart';
import '../../../../core/presentation/components/wavy_meter.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_math.dart';
import '../../domain/enum/budget_period.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../modules/ledger/presentation/charts/spend_breakdown.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../categories/domain/model/category_model.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../../../transactions/presentation/components/transaction_row.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../state/controllers/budgets_controller.dart';

/// One budget, in full: the window's standing, its sub-limits, what landed in
/// it, and how the last six periods went.
class BudgetDetailPage extends ConsumerWidget {
  const BudgetDetailPage({super.key, required this.budgetId});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final progress = ref.watch(budgetProgressProvider(budgetId));

    // ⚠️ The deleted case is handled rather than asserted. The delete button
    // on this very page removes the budget, and for the frame between the
    // state update and the pop this widget rebuilds against a budget that no
    // longer exists.
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
                  title: 'That budget is gone',
                  message: 'It looks like it was deleted.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final budget = progress.budget;
    final ledger = ref.watch(ledgerProvider);
    final rows = [
      for (final t in ledger)
        if (LedgerMath.budgetCounts(budget, t, progress.window)) t,
    ];
    final spend = LedgerMath.spendByCategory(rows, budget.currency);
    final history = ref.watch(budgetHistoryProvider(budgetId));

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
                onEdit: () => context.pushNamed(
                  'edit-budget',
                  pathParameters: {'id': budgetId},
                ),
                isPinned: budget.isPinned,
                onPin: () => ref
                    .read(budgetsControllerProvider.notifier)
                    .togglePin(budgetId),
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
                  leading: CategoryGlyph(
                    colorIndex: budget.colorIndex,
                    iconKey: budget.iconKey,
                    size: 52,
                    solid: true,
                  ),
                  eyebrow: '${budget.period.label} · ${progress.window.label}',
                  title: budget.name,
                  titleStyle: context.textTheme.headlineLarge,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: _StandingCard(progress: progress)
                    .animate()
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.03, end: 0),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            if (budget.hasSubLimits)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgyConstants.gutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        eyebrow: 'Inside this budget',
                        title: 'Category limits',
                        subtitle: progress.budget.isOverCommitted
                            ? 'These add up to more than the budget itself.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _SubLimits(progress: progress),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

            if (spend.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BudgyConstants.gutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'Where it went',
                        title: 'This period',
                      ),
                      const SizedBox(height: 14),
                      BudgyCard(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                        child: SpendBreakdown(
                          spend: spend,
                          currency: budget.currency,
                          maxRows: 6,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      eyebrow: 'History',
                      title: 'How past periods went',
                    ),
                    const SizedBox(height: 14),
                    BudgyCard(
                      child: _HistoryBars(history: history),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      eyebrow: 'Entries',
                      title:
                          '${rows.length} ${rows.length == 1 ? 'entry' : 'entries'}',
                      trailing: budget.isAddedOnly
                          ? BudgyChip(
                              label: 'Add one',
                              icon: LucideIcons.plus,
                              dense: true,
                              onTap: () => context.pushNamed(
                                'new-transaction',
                                extra: TransactionPrefill(
                                  budgetId: budget.id,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      BudgyCard(
                        tone: BudgyCardTone.wash,
                        elevated: false,
                        child: EmptyState(
                          compact: true,
                          iconKey: 'receipt',
                          title: 'Nothing in here yet',
                          message: budget.isAddedOnly
                              ? 'This budget only counts what you hand it.'
                              : 'Spend something in scope and it’ll appear.',
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
                            for (final t in rows)
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
        title: const Text('Delete this budget?'),
        content: const Text(
          'Your transactions stay exactly where they are — only the budget '
          'goes.',
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
    await ref.read(budgetsControllerProvider.notifier).delete(budgetId);
    if (context.mounted) context.pop();
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

/// The hero: what's left, the meter with its pace marker, and the three facts
/// that explain the number.
class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final budget = progress.budget;
    final over = progress.isOver;
    final perDay = progress.perDayRemainingMinor;

    return BudgyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                over ? 'OVER BY' : 'LEFT TO SPEND',
                style: context.textTheme.labelSmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: progress.health.label,
                tint: switch (progress.health) {
                  BudgetHealth.onTrack => c.successMain,
                  BudgetHealth.ahead || BudgetHealth.tight => c.warningMain,
                  BudgetHealth.over => c.errorMain,
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          MoneyText(
            progress.remainingMinor.abs(),
            currency: budget.currency,
            size: MoneySize.hero,
            showDecimals: false,
            roll: true,
            color: over ? c.errorMain : c.text100,
          ),
          const SizedBox(height: 18),
          // ⚠️ The same wave as the card that opened this page. Tapping a
          // budget must not change the progress language mid-flow — the user
          // is looking at the same number, so it has to be drawn the same way.
          // The per-category rows further down stay on the flat `BudgyMeter`
          // on purpose: at 7pt in a nested list a wave is noise, and those
          // rows are a breakdown rather than the page's subject.
          WavyMeter(
            fraction: progress.fraction,
            pace: progress.paceFraction,
            color: over ? c.errorMain : c.categoryAt(budget.colorIndex),
            thickness: 10,
            amplitude: 3,
            wavelength: 28,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${(progress.rawFraction * 100).round()}% of your limit',
                style: context.textTheme.bodySmall?.copyWith(
                  color: c.text300,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress.paceFraction * 100).round()}% through the period',
                style: context.textTheme.bodySmall?.copyWith(
                  color: c.text300,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: c.divider),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _Fact(
                  label: 'Spent',
                  minor: progress.spentMinor,
                  currency: budget.currency,
                ),
              ),
              Expanded(
                child: _Fact(
                  label: 'Limit',
                  minor: progress.limitMinor,
                  currency: budget.currency,
                ),
              ),
              Expanded(
                child: perDay == null
                    ? _TextFact(
                        label: 'Days left',
                        value: '${progress.window.remainingDays}',
                      )
                    : _Fact(
                        label: 'Per day left',
                        minor: perDay,
                        currency: budget.currency,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.minor,
    required this.currency,
  });

  final String label;
  final int minor;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: c.text300,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 5),
        MoneyText(
          minor,
          currency: currency,
          size: MoneySize.row,
          showDecimals: false,
          showSymbol: false,
        ),
      ],
    );
  }
}

class _TextFact extends StatelessWidget {
  const _TextFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: c.text300,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(value, style: context.textTheme.headlineSmall),
      ],
    );
  }
}

class _SubLimits extends ConsumerWidget {
  const _SubLimits({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final categories = ref.watch(categoriesControllerProvider);
    final budget = progress.budget;
    final entries = budget.categoryLimits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BudgyCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _SubLimitRow(
              category: categories.byId(entries[i].key),
              limitMinor: entries[i].value,
              spentMinor: progress.perCategoryMinor[entries[i].key] ?? 0,
              currency: budget.currency,
              fallbackColor: c.text300,
            ),
          ],
        ],
      ),
    );
  }
}

class _SubLimitRow extends StatelessWidget {
  const _SubLimitRow({
    required this.category,
    required this.limitMinor,
    required this.spentMinor,
    required this.currency,
    required this.fallbackColor,
  });

  final CategoryModel? category;
  final int limitMinor;
  final int spentMinor;
  final Currency currency;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final local = category;
    final tint = local == null
        ? fallbackColor
        : c.categoryAt(local.colorIndex);
    final fraction = limitMinor <= 0 ? 0.0 : spentMinor / limitMinor;
    final over = spentMinor > limitMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategoryGlyph(
              colorIndex: local?.colorIndex ?? 0,
              iconKey: local?.iconKey,
              emoji: local?.emoji,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                local?.name ?? 'Uncategorised',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall,
              ),
            ),
            MoneyText(
              spentMinor,
              currency: currency,
              size: MoneySize.small,
              color: over ? c.errorMain : c.text100,
              showDecimals: false,
              showSymbol: false,
            ),
            Text(
              ' / ',
              style: context.textTheme.bodySmall?.copyWith(color: c.text300),
            ),
            MoneyText(
              limitMinor,
              currency: currency,
              size: MoneySize.small,
              color: c.text300,
              showDecimals: false,
              showSymbol: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: BudgyMeter(
            fraction: fraction,
            color: over ? c.errorMain : tint,
            height: 7,
          ),
        ),
      ],
    );
  }
}

/// Past periods as columns against a shared scale.
///
/// ⚠️ All bars are scaled to the **limit**, not to the biggest period's
/// spend. Scaled to the max, every period's bar is relative to the worst one
/// and the limit line moves — which makes "did I stay under?" unanswerable,
/// which is the only question this chart is for.
class _HistoryBars extends StatelessWidget {
  const _HistoryBars({required this.history});

  final List<BudgetProgress> history;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    if (history.isEmpty) {
      return Text(
        'No history yet.',
        style: context.textTheme.bodySmall?.copyWith(color: c.text300),
      );
    }

    // Oldest on the left, which is how time reads.
    final ordered = history.reversed.toList();
    final limit = ordered.first.limitMinor;
    final peak = ordered.fold<int>(
      limit,
      (max, p) => p.spentMinor > max ? p.spentMinor : max,
    );
    const chartHeight = 108.0;
    final limitY = peak <= 0 ? 0.0 : (limit / peak) * chartHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              // The limit, as a dashed rule the bars are read against.
              Positioned(
                left: 0,
                right: 0,
                bottom: limitY,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashedLinePainter(color: c.text300),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'limit',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: c.text300,
                        fontSize: 9,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final p in ordered)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Tooltip(
                          message:
                              '${p.window.label} · '
                              '${(p.rawFraction * 100).round()}% of limit',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: peak <= 0
                                ? 2
                                : math.max(
                                    3,
                                    (p.spentMinor / peak) * chartHeight,
                                  ),
                            decoration: BoxDecoration(
                              color: p.isOver
                                  ? c.errorMain
                                  : p.isCurrent
                                  ? c.accent
                                  : c.accent.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final p in ordered)
              Expanded(
                child: Text(
                  p.isCurrent ? 'Now' : _shortLabel(p),
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: p.isCurrent ? c.text100 : c.text300,
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _shortLabel(BudgetProgress p) {
    final start = p.window.start;
    return '${start.day}/${start.month}';
  }
}

extension on BudgetProgress {
  bool get isCurrent => window.isCurrent;
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
