import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/theme/budgy_shadows.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';
import 'wallet_card.dart';

/// The wallet deck: a swipeable stack of [WalletCard]s with the neighbours
/// peeking out behind the live one.
///
/// ## Why a deck rather than a rail
///
/// A horizontal rail of equal cards says "here is a list, scroll it". A deck
/// — one card forward, its neighbours scaled back, tilted and dropped a few
/// points — says "here is the one you are holding, and there are others
/// behind it". That is how a wallet actually works, and it is the single
/// cheapest way to give a flat screen depth, because the depth is carried by
/// the layout rather than by a drop shadow pretending.
///
/// The neighbour transform is computed from the controller's **fractional**
/// page rather than from the settled index, so the cards rise and fall
/// continuously under the thumb instead of snapping when the page commits.
class WalletDeck extends StatefulWidget {
  const WalletDeck({
    super.key,
    required this.balances,
    required this.base,
    required this.onOpen,
    required this.onAdd,
    this.viewportFraction = 0.84,
    this.onIndexChanged,
  });

  final List<AccountBalance> balances;
  final Currency base;
  final ValueChanged<AccountBalance> onOpen;
  final VoidCallback onAdd;
  final double viewportFraction;
  final ValueChanged<int>? onIndexChanged;

  /// How tall the deck renders for a given available width. Exposed so a
  /// parent that has to reserve space (an overlapping header, a sliver) can
  /// ask rather than hard-code a number that silently stops matching.
  static double heightFor(double available, {double viewportFraction = 0.84}) =>
      WalletCard.heightFor(available * viewportFraction - _gap * 2) +
      _indicatorBand;

  static const double _gap = 7;
  static const double _indicatorBand = 30;

  @override
  State<WalletDeck> createState() => _WalletDeckState();
}

class _WalletDeckState extends State<WalletDeck> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The controller's fractional page, safe to read before first layout.
  ///
  /// ⚠️ `PageController.page` throws until the view has dimensions, and the
  /// very first build of a deck inside a sliver is exactly that moment.
  double get _page {
    if (!_controller.hasClients) return _index.toDouble();
    final position = _controller.position;
    if (!position.hasContentDimensions) return _index.toDouble();
    return _controller.page ?? _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // One trailing slot for "add a wallet", so an empty state and a full deck
    // are the same widget — a user with no wallets gets the add card centred
    // in the deck rather than a different screen.
    final count = widget.balances.length + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth * widget.viewportFraction -
            WalletDeck._gap * 2;
        final cardHeight = WalletCard.heightFor(cardWidth);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                padEnds: true,
                itemCount: count,
                onPageChanged: (value) {
                  setState(() => _index = value);
                  widget.onIndexChanged?.call(value);
                },
                itemBuilder: (context, index) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final distance = (index - _page);
                    final magnitude = distance.abs().clamp(0.0, 1.0);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translateByDouble(0, magnitude * 12, 0, 1)
                        ..rotateZ(distance.clamp(-1.0, 1.0) * -0.035)
                        ..scaleByDouble(
                          1 - magnitude * 0.11,
                          1 - magnitude * 0.11,
                          1,
                          1,
                        ),
                      child: Opacity(
                        // Never to zero. A neighbour fading out entirely
                        // leaves the live card alone on the page and the deck
                        // reads as a single card again.
                        opacity: 1 - magnitude * 0.35,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WalletDeck._gap,
                    ),
                    child: index < widget.balances.length
                        ? WalletCard(
                            balance: widget.balances[index],
                            base: widget.base,
                            width: cardWidth,
                            seed: index,
                            onTap: () =>
                                widget.onOpen(widget.balances[index]),
                          )
                        : _AddWalletCard(
                            width: cardWidth,
                            height: cardHeight,
                            onTap: widget.onAdd,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: WalletDeck._indicatorBand,
              child: Center(
                child: AnimatedSmoothIndicator(
                  activeIndex: _index,
                  count: count,
                  effect: ExpandingDotsEffect(
                    dotHeight: 5,
                    dotWidth: 5,
                    expansionFactor: 3.4,
                    spacing: 5,
                    activeDotColor: context.budgyColors.accent,
                    dotColor: context.budgyColors.text300.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The deck's terminal slot. Card-shaped like its neighbours so the row never
/// changes height, but deliberately *empty* — a flat tonal panel with no
/// field, which is what makes it read as a slot waiting to be filled rather
/// than as a wallet with no money in it.
class _AddWalletCard extends StatelessWidget {
  const _AddWalletCard({
    required this.width,
    required this.height,
    required this.onTap,
  });

  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final radius = BorderRadius.circular(width * 0.075);

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.medium,
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.surface200,
          borderRadius: radius,
          boxShadow: BudgyShadows.soft(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.plus, color: c.accent, size: 23),
            ),
            const SizedBox(height: 11),
            Text('Add a wallet', style: context.textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              'Cash, M-Pesa, a bank account',
              style: context.textTheme.bodySmall?.copyWith(color: c.text300),
            ),
          ],
        ),
      ),
    );
  }
}
