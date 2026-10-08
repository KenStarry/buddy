import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/amount_keypad.dart';
import '../../../../core/presentation/components/budgy_button.dart';
import '../../../../core/presentation/components/budgy_card.dart';
import '../../../../core/presentation/components/budgy_chip.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/look_picker.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/budgy_masthead.dart';
import '../../../../core/presentation/surfaces/glow.dart';
import '../../../../core/presentation/surfaces/scallop.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../domain/model/account_model.dart';
import '../components/wallet_card.dart';
import '../state/controllers/accounts_controller.dart';

/// Every wallet, its balance, and the net across them.
///
/// Rendered as a column of full-width [WalletCard]s rather than a list of
/// rows: this is the screen where "a wallet is a place, not a line item" has
/// to be most obviously true, and a row list here would undo the card language
/// the moment anyone tapped through to it.
///
/// ⚠️ Opens with a plain masthead, **not** the home screen's pocket. The
/// scooped panel with accounts tucked behind it is home's signature, and a
/// signature repeated on every screen is wallpaper. Secondary screens stay
/// calm so the one that is meant to land, lands.
class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final balances = ref.watch(accountBalancesProvider);
    final base = ref.watch(baseCurrencyProvider);
    final net = ref.watch(netWorthProvider);
    final cardWidth = context.screenSize.width - BudgyConstants.gutter * 2;

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
                      // A step up the ladder from the back button beside it,
                      // which is how this row says which of the two matters —
                      // rather than by being the only white block on a dark
                      // page. White is reserved for a screen's single primary
                      // action (see `BudgyFilledButton`), and "add a wallet"
                      // is chrome on a list, not that.
                      tone: c.surface300,
                      iconColor: c.text100,
                      onTap: () => WalletSheet.show(context, null),
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
                  eyebrow: 'Wallets',
                  title: 'Where your money lives',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverToBoxAdapter(
                child: _NetWorthPanel(net: net, base: base),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BudgyConstants.gutter,
              ),
              sliver: SliverList.separated(
                itemCount: balances.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => WalletCard(
                  balance: balances[index],
                  base: base,
                  width: cardWidth,
                  seed: index,
                  onTap: () => context.pushNamed(
                    'wallet',
                    pathParameters: {'id': balances[index].account.id},
                  ),
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

/// The total, as one pane of glass lit from behind.
class _NetWorthPanel extends StatelessWidget {
  const _NetWorthPanel({required this.net, required this.base});

  final int net;
  final Currency base;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return ScoopedSurface(
      underlay: AmbientGlow(
        blooms: [
          AmbientBloom(
            color: c.accent,
            center: const Alignment(0.7, -0.4),
            radius: 0.9,
            strength: 0.34,
          ),
          AmbientBloom(
            color: c.accentPop,
            center: const Alignment(-0.7, 0.8),
            radius: 1.0,
            strength: 0.18,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET WORTH',
            style: context.textTheme.labelSmall?.copyWith(
              color: c.heroInk.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              net,
              currency: base,
              size: MoneySize.hero,
              color: c.heroInk,
              showDecimals: false,
              symbolTrailing: true,
              roll: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Across every wallet, converted to ${base.code}',
            style: context.textTheme.bodySmall?.copyWith(
              color: c.heroInk.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Add or edit a wallet.
class WalletSheet extends ConsumerStatefulWidget {
  const WalletSheet({super.key, this.existing});

  final AccountModel? existing;

  static Future<void> show(BuildContext context, AccountModel? existing) =>
      BudgySheet.show<void>(
        context,
        builder: (_) => WalletSheet(existing: existing),
      );

  @override
  ConsumerState<WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends ConsumerState<WalletSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _iconKey = widget.existing?.iconKey ?? 'wallet';
  late int _colorIndex = widget.existing?.colorIndex ?? 0;
  late Currency _currency = widget.existing?.currency ?? CurrencyRegistry.base;
  late bool _isPrimary = widget.existing?.isPrimary ?? false;
  late bool _excludeFromNetWorth =
      widget.existing?.excludeFromNetWorth ?? false;
  late String _openingText = AmountKeypad.fromMinor(
    widget.existing?.openingBalanceMinor ?? 0,
    widget.existing?.currency ?? CurrencyRegistry.base,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existing = widget.existing;
    final account = AccountModel(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Wallet'
          : _nameController.text.trim(),
      currencyCode: _currency.code,
      iconKey: _iconKey,
      colorIndex: _colorIndex,
      openingBalanceMinor: AmountKeypad.toMinor(_openingText, _currency),
      isPrimary:
          _isPrimary ||
          // The very first wallet is the default whether or not the switch
          // was touched: a ledger with no default wallet cannot accept a
          // transaction.
          ref.read(accountsControllerProvider).live.isEmpty,
      excludeFromNetWorth: _excludeFromNetWorth,
      sortOrder:
          existing?.sortOrder ??
          ref.read(accountsControllerProvider).live.length,
    );
    await ref.read(accountsControllerProvider.notifier).save(account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return BudgySheet(
      title: widget.existing == null ? 'New wallet' : 'Edit wallet',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: context.textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'M-Pesa, Equity, Cash…',
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'CURRENCY',
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final currency in CurrencyRegistry.all)
                BudgyChip(
                  label: '${currency.symbol} ${currency.code}',
                  dense: true,
                  selected: _currency.code == currency.code,
                  onTap: () => setState(() {
                    // ⚠️ The opening balance is re-read through the NEW
                    // currency's precision. Switching from KES (2 decimals)
                    // to JPY (0) while holding the raw string "1200.50"
                    // would otherwise bank 120,050 minor units as ¥120,050.
                    final minor = AmountKeypad.toMinor(_openingText, _currency);
                    _currency = currency;
                    _openingText = AmountKeypad.fromMinor(minor, currency);
                  }),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'WHAT’S IN IT NOW',
            style: context.textTheme.labelSmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 6),
          Text(
            'Budgy adds every entry on top of this.',
            style: context.textTheme.bodySmall?.copyWith(color: c.text300),
          ),
          const SizedBox(height: 12),
          MoneyText(
            AmountKeypad.toMinor(_openingText, _currency),
            currency: _currency,
            size: MoneySize.display,
            showDecimals: _openingText.contains('.'),
          ),
          const SizedBox(height: 16),
          AmountKeypad(
            text: _openingText,
            currency: _currency,
            onChanged: (value) => setState(() => _openingText = value),
          ),

          const SizedBox(height: 20),
          LookPicker(
            iconKey: _iconKey,
            colorIndex: _colorIndex,
            onIcon: (key) => setState(() => _iconKey = key),
            onColor: (index) => setState(() => _colorIndex = index),
          ),

          const SizedBox(height: 20),
          BudgyCard(
            tone: BudgyCardTone.band,
            elevated: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPrimary,
                  activeTrackColor: c.accent,
                  title: Text(
                    'Use this by default',
                    style: context.textTheme.titleSmall,
                  ),
                  onChanged: (value) => setState(() => _isPrimary = value),
                ),
                Divider(height: 1, color: c.divider),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _excludeFromNetWorth,
                  activeTrackColor: c.accent,
                  title: Text(
                    'Leave out of net worth',
                    style: context.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'For a credit card or a loan — money that isn’t yours.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: c.text300,
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _excludeFromNetWorth = value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          BudgyFilledButton(
            label: 'Save wallet',
            width: double.infinity,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}
