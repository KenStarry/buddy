import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/budgy_sheet.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/presentation/surfaces/glow.dart';
import '../../../../core/presentation/surfaces/grain.dart';
import '../../../../core/presentation/surfaces/scallop.dart';
import '../../../../core/utils/budgy_constants.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../accounts/domain/model/account_model.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import '../../../../modules/ledger/state/providers/ledger_providers.dart';
import '../../../settings/presentation/state/controllers/settings_controller.dart';
import '../../../transactions/domain/enum/transaction_type.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart';
import '../../../transactions/presentation/state/controllers/transactions_controller.dart';

/// The home screen's masthead: a wordmark row, the **balance pocket**, and
/// three primary actions hanging off its bottom edge.
///
/// ## The pocket
///
/// The balance panel's top edge is scooped, and the wallet cards are slid in
/// behind it so only a strip of each shows. That one move does most of the
/// work on this screen: it establishes depth without a single shadow (which is
/// just as well — a shadow on a near-black page is nothing), it makes the
/// wallets *physically* part of the balance rather than a list somewhere else,
/// and it gives the panel a silhouette, so the screen's main object is
/// recognisable before any of its content is read.
///
/// ## Why everything in the panel is centred
///
/// The rest of Budgy is left-aligned, because the rest of Budgy is lists and
/// lists are read along their left edge. The panel is not a list — it is one
/// figure with its labels stacked above it — and a centred stack has a single
/// axis the eye can sit on. Left-aligning it would hang the whole composition
/// off the same edge as the transaction rows below and flatten the two into
/// one undifferentiated column.
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  /// Null means "every wallet", which is the net-worth read. A wallet id
  /// otherwise.
  ///
  /// ⚠️ Held as an **id**, not an `AccountBalance`. The balances list is
  /// rebuilt from the ledger on every entry, so a captured object would be a
  /// stale snapshot the moment the user logged anything.
  String? _walletId;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final balances = ref.watch(accountBalancesProvider);
    final base = ref.watch(baseCurrencyProvider);
    final net = ref.watch(netWorthProvider);

    final selected = _walletId == null
        ? null
        : balances.where((b) => b.account.id == _walletId).firstOrNull;
    // A wallet that has since been deleted falls back to the whole position
    // rather than rendering an empty panel.
    if (_walletId != null && selected == null) _walletId = null;

    return Stack(
      children: [
        // ⚠️ `Positioned.fill` with a bottom fade, **not** a fixed-height
        // box. Everything above this is frosted glass, and glass on a flat
        // near-black page refracts nothing — this is the light the glass is
        // made of. But a bloom is still well above zero alpha when it reaches
        // the edge of its box, so a box that ends anywhere visible *clips* the
        // gradient and draws a hard line across the page. Filling the header
        // and dissolving over the bottom third means the light dies into the
        // page instead of stopping against it.
        Positioned.fill(
          child: IgnorePointer(
            child: AmbientGlow(
              fadeBottom: 0.42,
              blooms: [
                AmbientBloom(
                  color: c.accent,
                  // Centred behind the **panel**, not the ghosts above it.
                  // Pushed higher, the light lands on the slivers and the
                  // panel — the one surface that has to read as a thick pane
                  // of glass — goes grey.
                  center: const Alignment(0.60, -0.14),
                  radius: 0.78,
                  strength: 0.48,
                ),
                AmbientBloom(
                  color: c.accentPop,
                  center: const Alignment(-0.78, 0.12),
                  radius: 0.88,
                  strength: 0.28,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            BudgyConstants.gutter,
            context.viewPadding.top + 6,
            BudgyConstants.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandRow(),
              const SizedBox(height: 20),
              _Pocket(
                balances: balances,
                selected: selected,
                netMinor: net,
                base: base,
                onPick: _pickWallet,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ScoopButton(
                      icon: LucideIcons.arrowUpRight,
                      label: 'Spend',
                      fill: c.surface200,
                      ink: c.text100,
                      onTap: () => context.pushNamed(
                        'new-transaction',
                        extra: TransactionPrefill(
                          type: TransactionType.expense,
                          accountId: _walletId,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: ScoopButton(
                      icon: LucideIcons.arrowDownLeft,
                      label: 'Income',
                      fill: c.surface200,
                      ink: c.text100,
                      onTap: () => context.pushNamed(
                        'new-transaction',
                        extra: TransactionPrefill(
                          type: TransactionType.income,
                          accountId: _walletId,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: ScoopButton(
                      icon: LucideIcons.arrowLeftRight,
                      label: 'Move',
                      fill: c.surface200,
                      ink: c.text100,
                      onTap: () => context.pushNamed(
                        'new-transaction',
                        extra: TransactionPrefill(
                          type: TransactionType.transfer,
                          accountId: _walletId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 380.ms);
  }

  Future<void> _pickWallet() async {
    final balances = ref.read(accountBalancesProvider);
    final chosen = await BudgySheet.show<String?>(
      context,
      builder: (sheetContext) =>
          _WalletPickerSheet(balances: balances, selectedId: _walletId),
    );
    // ⚠️ `null` is both "every wallet" and "the sheet was dismissed", so the
    // sheet returns a sentinel for the former and this only writes when the
    // user actually chose. Treating a dismiss as a choice would silently
    // reset the panel every time someone swiped the sheet away.
    if (chosen == null || !mounted) return;
    setState(() => _walletId = chosen == _allWalletsSentinel ? null : chosen);
  }
}

const _allWalletsSentinel = '__all__';

// ───────────────────── Brand row ─────────────────────────────────────────────

class _BrandRow extends ConsumerWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final settings = ref.watch(settingsControllerProvider);
    final overdue = ref.watch(overdueTransactionsProvider);
    final name = settings.userName?.trim();

    return Row(
      children: [
        // The one solid accent on the screen. A logo is the one place a flat
        // chip of brand colour is doing its job rather than competing with a
        // figure, so it stays filled while everything else turns to glass.
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(LucideIcons.wallet, size: 17, color: c.surface100),
        ),
        const SizedBox(width: 10),
        Text(
          'Budgy',
          style: context.textTheme.headlineMedium?.copyWith(color: c.text100),
        ),
        const Spacer(),
        _Chrome(
          icon: settings.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
          active: settings.hideAmounts,
          onTap: () =>
              ref.read(settingsControllerProvider.notifier).toggleHideAmounts(),
        ),
        const SizedBox(width: 8),
        _Chrome(
          icon: LucideIcons.bell,
          badge: overdue.isNotEmpty,
          onTap: () => context.pushNamed('upcoming'),
        ),
        const SizedBox(width: 8),
        PressScale(
          onTap: () => context.pushNamed('settings'),
          haptic: HapticLevel.selection,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.heroInk.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: name == null || name.isEmpty
                ? Icon(
                    LucideIcons.user,
                    size: 18,
                    color: c.heroInk.withValues(alpha: 0.75),
                  )
                : Text(
                    name.characters.first.toUpperCase(),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: c.heroInk,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// A top-bar button.
///
/// ⚠️ Glass, not `surface300`. An opaque dark circle sitting on a lit header
/// reads as a **hole punched through it** — the one place on the screen where
/// the glow visibly stops. Translucent white lets the light behind carry
/// through, so the button sits on the header rather than in it.
class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: active ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? c.accent : ink.withValues(alpha: 0.75),
            ),
          ),
          if (badge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.errorMain,
                  shape: BoxShape.circle,
                  // Ringed in the PAGE colour so the dot reads as sitting on
                  // top of the button rather than as part of its glyph. This
                  // is a mark separator, not an outline.
                  border: Border.all(color: c.surface100, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────── The pocket ────────────────────────────────────────────

class _Pocket extends StatelessWidget {
  const _Pocket({
    required this.balances,
    required this.selected,
    required this.netMinor,
    required this.base,
    required this.onPick,
  });

  final List<AccountBalance> balances;
  final AccountBalance? selected;
  final int netMinor;
  final Currency base;
  final VoidCallback onPick;

  /// How much of each ghost shows above the one in front of it. Enough to
  /// carry a name and a figure — below about 20 a strip stops reading as a
  /// card you could pull out and starts reading as a seam in the panel.
  static const double peek = 28;

  /// At most two. A third ghost is a third of the panel's width in bands
  /// before you reach the number everything here exists to show.
  static const int _maxGhosts = 2;

  @override
  Widget build(BuildContext context) {
    // Largest first, so the account on show is the one most worth seeing
    // rather than whichever happened to be created first.
    final ordered = [...balances]
      ..sort((a, b) => b.baseMinor.compareTo(a.baseMinor));
    // Never the selected wallet: it is already the headline figure, and
    // seeing it twice makes the ghost look like a second, smaller account
    // with the same name.
    final ghosts = [
      for (final b in ordered)
        if (b.account.id != selected?.account.id) b,
    ].take(_maxGhosts).toList();

    final inset = ghosts.length * peek;

    return Stack(
      children: [
        for (var i = ghosts.length - 1; i >= 0; i--)
          Positioned(
            top: (ghosts.length - 1 - i) * peek,
            left: (i + 1) * 16,
            right: (i + 1) * 16,
            height: peek + 42,
            child: _GhostAccount(balance: ghosts[i], depth: i),
          ),
        Padding(
          padding: EdgeInsets.only(top: inset),
          child: _BalancePanel(
            selected: selected,
            netMinor: netMinor,
            base: base,
            onPick: onPick,
            walletCount: balances.length,
          ),
        ),
      ],
    );
  }
}

/// An account seen as the sliver of it that is not inside the pocket.
///
/// Frosted rather than filled. A solid strip is a list row that happens to be
/// behind something; glass reads as a *card* — the ambient light bends through
/// it, the scooped panel in front occludes it, and the stack gets depth from
/// physics rather than from a drop shadow (which on near-black would do
/// nothing anyway).
class _GhostAccount extends StatelessWidget {
  const _GhostAccount({required this.balance, required this.depth});

  final AccountBalance balance;

  /// 0 is the card nearest the panel. Deeper cards are thinner glass and
  /// catch less edge light, so the stack recedes.
  final int depth;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final account = balance.account;
    final tint = c.categoryAt(account.colorIndex);
    final front = depth == 0;
    final radius = BorderRadius.circular(26);

    // ⚠️ The pane is tinted toward the wallet's own slot, not pure white. A
    // stack of colourless glass slivers is three identical grey bars, which
    // throws away the one thing that makes them *accounts* rather than rows —
    // and leaves the 16pt tile doing all the identifying on its own.
    final pane = Color.lerp(Colors.white, tint, 0.38)!;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pane.withValues(alpha: front ? 0.16 : 0.10),
                pane.withValues(alpha: front ? 0.06 : 0.04),
              ],
            ),
          ),
          child: CustomPaint(
            foregroundPainter: _GhostEdgePainter(
              radius: 26,
              strength: front ? 0.34 : 0.20,
            ),
            // ⚠️ Top-aligned, not centred. The card is taller than the strip
            // that shows — the rest is inside the pocket — so content left to
            // centre itself lands behind the panel and only its top sliver
            // appears, which reads as a rendering fault rather than a card.
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: _Pocket.peek,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: front ? 0.9 : 0.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          BudgyIcons.resolve(account.iconKey),
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: c.heroInk.withValues(
                              alpha: front ? 0.78 : 0.55,
                            ),
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        balance.minor,
                        currency: account.currency,
                        size: MoneySize.small,
                        showDecimals: false,
                        color: c.heroInk.withValues(alpha: front ? 0.78 : 0.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The light a raised glass edge catches. Not a border — it fades out before
/// the shoulders and never closes around the shape.
class _GhostEdgePainter extends CustomPainter {
  _GhostEdgePainter({required this.radius, required this.strength});

  final double radius;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.55, 0.55, size.width - 1.1, size.height - 1.1),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: strength),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.55],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GhostEdgePainter old) =>
      old.strength != strength || old.radius != radius;
}

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({
    required this.selected,
    required this.netMinor,
    required this.base,
    required this.onPick,
    required this.walletCount,
  });

  final AccountBalance? selected;
  final int netMinor;
  final Currency base;
  final VoidCallback onPick;
  final int walletCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.budgyColors;
    final account = selected?.account;
    final minor = selected?.minor ?? netMinor;
    final currency = selected?.account.currency ?? base;
    final foreign =
        selected != null && selected!.account.currencyCode != base.code;

    return ScoopedSurface(
      radius: 32,
      // Two scoops rather than one: a single central notch reads as a tab or a
      // handle, where a pair reads as a mouth with something in it — which is
      // the whole point, since there are cards behind this edge.
      notchCenters: const [0.26, 0.74],
      // Wide and shallow. The mouth has to be broad enough to look like
      // something slid in through it and shallow enough that it never eats
      // into the row of content below.
      notchWidth: 124,
      notchDepth: 11,
      color: Colors.transparent,
      // Denser glass than the ghosts — it has to carry a 48pt figure and two
      // tiers of muted label, and translucency is contrast you are spending.
      blur: 34,
      specular: 0.3,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.17),
          Colors.white.withValues(alpha: 0.06),
        ],
      ),
      child: GrainOverlay(
        intensity: 0.05,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 26),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Balance',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: c.heroInk.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  PressScale(
                    onTap: () => ref
                        .read(transactionsControllerProvider.notifier)
                        .load(),
                    haptic: HapticLevel.selection,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.refreshCw,
                        size: 17,
                        color: c.heroInk.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _WalletPill(account: account, count: walletCount, onTap: onPick),

              const SizedBox(height: 20),

              Text(
                account == null ? 'Across every wallet' : 'Available balance',
                style: context.textTheme.bodySmall?.copyWith(
                  color: c.heroInk.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: MoneyText(
                  minor,
                  currency: currency,
                  size: MoneySize.hero,
                  color: c.heroInk,
                  // No decimals on the aggregate. Two more glyphs at
                  // satellite scale on the end of a six-figure total is a
                  // precision nobody reads and a ragged right edge on the one
                  // line that is meant to be the screen's anchor.
                  showDecimals: false,
                  symbolTrailing: true,
                  roll: true,
                ),
              ),

              if (foreign) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '≈ ',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: c.heroInk.withValues(alpha: 0.5),
                      ),
                    ),
                    MoneyText(
                      selected!.baseMinor,
                      currency: base,
                      size: MoneySize.small,
                      color: c.heroInk.withValues(alpha: 0.5),
                      showDecimals: false,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The wallet selector. Shows what the figure below it is counting.
class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.account,
    required this.count,
    required this.onTap,
  });

  final AccountModel? account;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final isAll = account == null;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 6, 13, 6),
        decoration: BoxDecoration(
          color: c.heroInk.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isAll
                    ? c.heroInk.withValues(alpha: 0.12)
                    : c.categoryAt(account!.colorIndex).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAll
                    ? LucideIcons.layers
                    : BudgyIcons.resolve(account!.iconKey),
                size: 12,
                color: isAll ? c.heroInk : Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAll ? 'All wallets ($count)' : account!.name,
              style: context.textTheme.titleSmall?.copyWith(color: c.heroInk),
            ),
            const SizedBox(width: 5),
            Icon(
              LucideIcons.chevronDown,
              size: 15,
              color: c.heroInk.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({required this.balances, required this.selectedId});

  final List<AccountBalance> balances;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return BudgySheet(
      title: 'Show the balance of',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickerRow(
            icon: LucideIcons.layers,
            tint: c.accent,
            label: 'All wallets',
            selected: selectedId == null,
            onTap: () => Navigator.of(context).pop(_allWalletsSentinel),
          ),
          for (final balance in balances)
            _PickerRow(
              icon: BudgyIcons.resolve(balance.account.iconKey),
              tint: c.categoryAt(balance.account.colorIndex),
              label: balance.account.name,
              selected: selectedId == balance.account.id,
              onTap: () => Navigator.of(context).pop(balance.account.id),
            ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surface300,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 15, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: context.textTheme.titleMedium)),
            if (selected) Icon(LucideIcons.check, size: 18, color: c.accent),
          ],
        ),
      ),
    );
  }
}
