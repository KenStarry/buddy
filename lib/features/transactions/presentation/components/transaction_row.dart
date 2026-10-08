import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../accounts/presentation/state/controllers/accounts_controller.dart';
import '../../../categories/presentation/state/controllers/categories_controller.dart';
import '../../domain/enum/transaction_type.dart';
import '../../domain/model/transaction_model.dart';

/// One line in the ledger.
///
/// ## Why expenses are not red
///
/// The amount wears `text100` with a leading `−`; only income is tinted. In a
/// ledger where nine rows in ten are expenses, colouring them all red makes
/// the list read as a list of errors and burns the alarm colour on the normal
/// case — so when something genuinely needs attention (overdue, over budget)
/// there is no louder colour left to say it with. Direction is carried by the
/// sign, which is unambiguous and works in greyscale.
class TransactionRow extends ConsumerWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.showDate = false,
    this.selected,
    this.dense = false,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Append the date to the subtitle. For lists that are not day-grouped.
  final bool showDate;

  /// Non-null puts the row in multi-select mode.
  final bool? selected;

  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final t = transaction;
    final categories = ref.watch(categoriesControllerProvider);
    final accounts = ref.watch(accountsControllerProvider);

    final category = categories.byId(t.subcategoryId ?? t.categoryId);
    final parent = categories.parentOf(t.categoryId);
    final account = accounts.byId(t.accountId);
    final destination = accounts.byId(t.destinationAccountId);

    final amountColor = switch (t.type) {
      TransactionType.income => c.inflow,
      TransactionType.transfer => c.text300,
      TransactionType.expense => c.text100,
    };

    final subtitle = <String>[
      if (t.type.isTransfer)
        '${account?.name ?? 'Wallet'} → ${destination?.name ?? 'Wallet'}'
      else ...[
        if (category != null) category.name,
        if (account != null) account.name,
      ],
      if (showDate) t.date.relativeDayLabel,
    ].join(' · ');

    // ⚠️ Colour from the PARENT, mark from the most specific category — and
    // the mark is taken as a unit, never mixed.
    //
    // The colour is the parent's because a subcategory inherits its parent's
    // slot; reading the subcategory's own index would let "Coffee" and
    // "Groceries" drift to different hues inside one category's own slice.
    //
    // The mark is `display`'s own emoji *or* its own icon — falling through
    // to the parent's **emoji** when the subcategory merely lacked one put a
    // 🍜 on every cup of coffee and a 🚗 on every matatu, because the parent's
    // emoji outranked the subcategory's perfectly good icon.
    final display = category ?? parent;
    final glyph = t.type.isTransfer
        ? _TransferGlyph(size: dense ? 40 : 44)
        : CategoryGlyph(
            colorIndex: parent?.colorIndex ?? display?.colorIndex ?? 0,
            iconKey: display?.iconKey,
            emoji: display?.emoji,
            size: dense ? 40 : 44,
          );

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: HapticLevel.selection,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 7 : 9),
        child: Row(
          children: [
            if (selected != null) ...[
              _SelectionDot(selected: selected!),
              const SizedBox(width: 12),
            ],
            glyph,
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.title.isEmpty
                              ? (category?.name ?? 'Untitled')
                              : t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      if (t.nature != TransactionNature.standard) ...[
                        const SizedBox(width: 6),
                        _NatureBadge(nature: t.nature, settled: t.isSettled),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: c.text300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  // Transfers render unsigned: the money did not leave, it
                  // moved, and a `−` on one would read as a loss.
                  t.type.isTransfer ? t.amountMinor : t.signedMinor,
                  currency: t.currency,
                  color: amountColor,
                  signed: t.type.isIncome,
                  showDecimals: false,
                ),
                if (!t.isSettled) ...[
                  const SizedBox(height: 3),
                  Text(
                    t.isOverdue ? 'Overdue' : t.date.relativeDayLabel,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: t.isOverdue ? c.errorMain : c.text300,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferGlyph extends StatelessWidget {
  const _TransferGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.transfer.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(
        LucideIcons.arrowLeftRight,
        size: size * 0.44,
        color: c.transfer,
      ),
    );
  }
}

class _NatureBadge extends StatelessWidget {
  const _NatureBadge({required this.nature, required this.settled});

  final TransactionNature nature;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    // An unsettled loan or bill is the information; a settled one is just
    // history and its badge recedes to a neutral tint.
    final tint = !settled
        ? (nature.isLoan ? c.warningMain : c.infoMain)
        : c.text300;

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(_icon(nature), size: 11, color: tint),
    );
  }

  static IconData _icon(TransactionNature nature) => switch (nature) {
    TransactionNature.standard => LucideIcons.receipt,
    TransactionNature.subscription => LucideIcons.repeat,
    TransactionNature.repeating => LucideIcons.rotateCw,
    TransactionNature.upcoming => LucideIcons.clock,
    TransactionNature.debt => LucideIcons.handCoins,
    TransactionNature.credit => LucideIcons.handshake,
  };
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? c.accent : Colors.transparent,
        shape: BoxShape.circle,
        // The checkbox's own ring — it IS the control, not a decoration
        // around one.
        border: Border.all(
          color: selected ? c.accent : c.divider,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}
