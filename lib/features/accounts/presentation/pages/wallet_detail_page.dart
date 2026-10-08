import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/components/category_glyph.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/surfaces/glow.dart';
import '../../../../core/presentation/surfaces/scallop.dart';
import '../../../../core/presentation/components/empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/section_header.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../transactions/presentation/components/transaction_row.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../state/controllers/accounts_controller.dart';
import 'wallets_page.dart';

/// One wallet: its balance and everything that has moved through it.
class WalletDetailPage extends ConsumerWidget {
  const WalletDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final account = ref.watch(accountsControllerProvider).byId(accountId);
    final balance = ref
        .watch(accountBalancesProvider)
        .where((b) => b.account.id == accountId)
        .firstOrNull;
    final base = ref.watch(baseCurrencyProvider);

    if (account == null || balance == null) {
      return Scaffold(
        backgroundColor: c.surface100,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(BudgyConstants.gutter),
                child: Row(
                  children: [
                    BudgyIconButton(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => context.pop(),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: EmptyState(
                  iconKey: 'circle-dashed',
                  title: 'That wallet is gone',
                  message: 'It looks like it was removed.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Every row that touched this wallet — including the far leg of a
    // transfer, which `signedMinorFor` is the only honest test for.
    final rows = [
      for (final t in ref.watch(ledgerProvider))
        if (t.accountId == accountId || t.destinationAccountId == accountId) t,
    ];

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
                      icon: LucideIcons.pencil,
                      onTap: () => WalletSheet.show(context, account),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BudgyConstants.gutter,
                20,
                BudgyConstants.gutter,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: BudgyMasthead(
                  leading: CategoryGlyph(
                    colorIndex: account.colorIndex,
                    iconKey: account.iconKey,
                    size: 50,
                    solid: true,
                  ),
                  eyebrow: account.currency.name,
                  title: account.name,
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
                child: ScoopedSurface(
                  underlay: AmbientGlow(
                    blooms: [
                      AmbientBloom(
                        color: c.categoryAt(account.colorIndex),
                        center: const Alignment(0.7, -0.4),
                        radius: 0.9,
                        strength: 0.36,
                      ),
                      AmbientBloom(
                        color: c.accent,
                        center: const Alignment(-0.7, 0.85),
                        radius: 1.0,
                        strength: 0.16,
                      ),
                    ],
                  ),
                  radius: 28,
                  color: Colors.transparent,
                  blur: 0,
                  specular: 0.28,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BALANCE',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: c.heroInk.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MoneyText(
                          balance.minor,
                          currency: account.currency,
                          size: MoneySize.hero,
                          showDecimals: false,
                          symbolTrailing: true,
                          roll: true,
                          color: c.heroInk,
                        ),
                      ),
                      if (account.currencyCode != base.code) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Text(
                              '≈ ',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: c.heroInk.withValues(alpha: 0.55),
                              ),
                            ),
                            MoneyText(
                              balance.baseMinor,
                              currency: base,
                              size: MoneySize.small,
                              color: c.heroInk.withValues(alpha: 0.55),
                              showDecimals: false,
                            ),
                            Text(
                              // Says out loud that the conversion is an
                              // estimate — the rate table is static.
                              '  ·  at a stored rate',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: c.heroInk.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      BudgyFilledButton(
                        label: 'Add an entry',
                        icon: LucideIcons.plus,
                        height: 48,
                        width: double.infinity,
                        onTap: () => context.pushNamed(
                          'new-transaction',
                          extra: TransactionPrefill(accountId: account.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      eyebrow: 'Movement',
                      title:
                          '${rows.length} ${rows.length == 1 ? 'entry' : 'entries'}',
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      BudgyCard(
                        tone: BudgyCardTone.wash,
                        elevated: false,
                        child: const EmptyState(
                          compact: true,
                          iconKey: 'receipt',
                          title: 'Nothing through here yet',
                          message: 'Log something against this wallet.',
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
                            for (final t in rows.take(50))
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
}
