import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/enum/transaction_type.dart';
import '../../domain/model/transaction_model.dart';
import '../components/transaction_row.dart';
import '../state/controllers/transactions_controller.dart';
import 'transaction_form_page.dart';

/// Money lent and money borrowed, with a one-tap settle.
class LoansPage extends ConsumerWidget {
  const LoansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final open = ref.watch(openLoansProvider);
    final position = ref.watch(loanPositionProvider);
    final base = ref.watch(baseCurrencyProvider);

    // A credit is money you handed over (an expense) coming back; a debt is
    // money you received (income) going back.
    final owedToYou = [for (final t in open) if (t.type.isExpense) t];
    final youOwe = [for (final t in open) if (!t.type.isExpense) t];

    return Scaffold(
      backgroundColor: c.surface100,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                8,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    BudgyIconButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    BudgyIconButton(
                      icon: LucideIcons.plus,
                      tone: c.accentSoft,
                      iconColor: c.accent,
                      onTap: () => context.pushNamed(
                        'new-transaction',
                        extra: const TransactionPrefill(
                          nature: TransactionNature.credit,
                          type: TransactionType.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                18,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  eyebrow: 'Lent & borrowed',
                  title: 'Between you and other people',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.netMinor >= 0
                            ? 'NET — OWED TO YOU'
                            : 'NET — YOU OWE',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: c.text300,
                        ),
                      ),
                      const SizedBox(height: 10),
                      MoneyText(
                        position.netMinor.abs(),
                        currency: base,
                        size: MoneySize.hero,
                        showDecimals: false,
                        color: position.netMinor >= 0
                            ? c.successMain
                            : c.warningMain,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Leg(
                              label: 'Owed to you',
                              minor: position.inflowMinor,
                              currency: base,
                              tint: c.successMain,
                            ),
                          ),
                          Container(width: 1, height: 38, color: c.divider),
                          Expanded(
                            child: _Leg(
                              label: 'You owe',
                              minor: position.outflowMinor,
                              currency: base,
                              tint: c.warningMain,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            if (open.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BudgyConstants.gutter,
                  ),
                  child: BudgyCard(
                    tone: BudgyCardTone.wash,
                    elevated: false,
                    child: EmptyState(
                      compact: true,
                      iconKey: 'handshake',
                      title: 'Nothing open',
                      message:
                          'Nobody owes you and you owe nobody. A fine place '
                          'to be.',
                      actionLabel: 'Record a loan',
                      onAction: () => context.pushNamed(
                        'new-transaction',
                        extra: const TransactionPrefill(
                          nature: TransactionNature.credit,
                          type: TransactionType.expense,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (owedToYou.isNotEmpty)
              _LoanGroup(
                eyebrow: 'Credit',
                title: 'Coming back to you',
                rows: owedToYou,
                settleLabel: 'Mark as paid back',
              ),

            if (youOwe.isNotEmpty)
              _LoanGroup(
                eyebrow: 'Debt',
                title: 'You still owe',
                rows: youOwe,
                settleLabel: 'Mark as settled',
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: 40 + context.viewPadding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({
    required this.label,
    required this.minor,
    required this.currency,
    required this.tint,
  });

  final String label;
  final int minor;
  final Currency currency;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: c.text300,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 6),
          MoneyText(
            minor,
            currency: currency,
            size: MoneySize.row,
            color: tint,
            showDecimals: false,
          ),
        ],
      ),
    );
  }
}

class _LoanGroup extends ConsumerWidget {
  const _LoanGroup({
    required this.eyebrow,
    required this.title,
    required this.rows,
    required this.settleLabel,
  });

  final String eyebrow;
  final String title;
  final List<TransactionModel> rows;
  final String settleLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      BudgyConstants.gutter,
      0,
      BudgyConstants.gutter,
      26,
    ),
    sliver: SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: eyebrow, title: title),
          const SizedBox(height: 12),
          BudgyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final t in rows)
                  Dismissible(
                    key: ValueKey('loan-${t.id}'),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 6),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 18,
                            color: context.budgyColors.successMain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            settleLabel,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.budgyColors.successMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Settling changes the row rather than removing it, so
                    // the dismiss is always refused after the write — see the
                    // same note on the upcoming list.
                    confirmDismiss: (_) async {
                      await ref
                          .read(transactionsControllerProvider.notifier)
                          .settle(t.id);
                      return false;
                    },
                    child: TransactionRow(
                      transaction: t,
                      showDate: true,
                      dense: true,
                      onTap: () => context.pushNamed(
                        'transaction',
                        pathParameters: {'id': t.id},
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
