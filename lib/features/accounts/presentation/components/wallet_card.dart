import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/domain/currency.dart';
import '../../../../core/presentation/budgy_icons.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/presentation/components/press_scale.dart';
import '../../../../core/presentation/surfaces/glow.dart';
import '../../../../core/presentation/surfaces/grain.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../modules/ledger/domain/ledger_values.dart';

/// A wallet, as an object you could pick up.
///
/// ## Why this is a card and not a row
///
/// A wallet list rendered as `[icon] [name] ......... [amount]` is a
/// spreadsheet, and it makes every wallet the same thing with a different
/// label. People do not experience their money that way: the salary account,
/// the M-Pesa float and the holiday stash are different *places*. The one
/// interface convention that already carries "a distinct place where money
/// lives" is the payment card — so a wallet gets card proportions (ISO 7810,
/// the ratio every physical card in a pocket already has) and becomes a thing
/// you recognise at a glance rather than a row you read.
///
/// ## Why it is dark rather than its own colour
///
/// An earlier pass filled each card edge to edge with a saturated field keyed
/// to its colour slot. Five of those in a list is a paint chart: every card
/// shouts, so none of them leads, and the balances — the only thing on a card
/// anyone is actually looking for — have to compete with their own background.
/// So the card is near-black like everything else, and the slot hue arrives as
/// a **bloom behind the glass** plus the icon tile. Identity is still
/// unmistakable at a glance; it just stops being the loudest thing in the
/// frame.
///
/// The balance is in the wallet's **own** currency. A dollar account shown in
/// shillings is a different fact; the base-currency figure rides underneath as
/// an approximation when the two differ.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.balance,
    required this.base,
    this.width = 300,
    this.onTap,
    this.seed = 0,
  });

  final AccountBalance balance;
  final Currency base;
  final double width;
  final VoidCallback? onTap;

  /// Varies the bloom anchors so a list is not the same picture repeated.
  final int seed;

  /// Wider than a physical card.
  ///
  /// ⚠️ Deliberately **not** ISO 7810 ID-1 (1.586), which is what a credit
  /// card in a pocket actually is. At full width that ratio makes a 220pt
  /// slab, and a column of them reads as heavy and boxy next to the header's
  /// accounts — which are the same material but sleek. Stretching the aspect
  /// keeps every card cue that matters (rounded corners, contactless mark,
  /// chrome band) while bringing the silhouette into the same family as the
  /// pocket. The card metaphor survives the 20pt; the aesthetic did not
  /// survive the boxiness.
  static const double aspect = 1.92;

  static double heightFor(double width) => width / aspect;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final account = balance.account;
    final tint = c.categoryAt(account.colorIndex);
    final ink = c.heroInk;
    final foreign = account.currencyCode != base.code;
    // Softer than a payment card's, to match the pocket's own corners. On a
    // shorter card the same proportional radius reads tighter, so it goes up
    // rather than staying put.
    final radius = BorderRadius.circular(width * 0.088);
    final flip = seed.isOdd;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.medium,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: width,
          height: heightFor(width),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.surface200),
              // ⚠️ **Both** blooms are the wallet's own hue. An earlier pass
              // used the brand accent for the second one, which put the same
              // blue cast on every card in the list and quietly undid the
              // thing the colour slot exists for — a blue wallet became
              // indistinguishable from the net-worth panel above it. The
              // second bloom is the slot hue thrown ~35°, which keeps the
              // field from being one flat colour without borrowing anyone
              // else's.
              AmbientGlow(
                blooms: [
                  AmbientBloom(
                    color: tint,
                    // Mirrored on alternate cards, so a column of them does
                    // not read as one image printed five times.
                    center: Alignment(flip ? -0.75 : 0.8, -0.7),
                    radius: 0.85,
                    strength: 0.52,
                  ),
                  AmbientBloom(
                    color: _throwHue(tint, 35),
                    center: Alignment(flip ? 0.7 : -0.7, 0.9),
                    radius: 1.0,
                    strength: 0.20,
                  ),
                ],
              ),
              // The pane. A wash over the blooms, which is what turns two
              // coloured smudges into a surface with a direction to its light.
              //
              // ⚠️ Top-to-bottom at the same weights as the balance panel, not
              // a weaker diagonal. The card and the panel are the same
              // material seen in two places; a card lit from a different angle
              // and half as brightly reads as a different component that
              // happens to share a palette.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
              GrainOverlay(intensity: 0.06),
              CustomPaint(
                painter: _CardEdgePainter(
                  radius: width * 0.088,
                  strength: 0.30,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(width * 0.055),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Identity ──────────────────────────────────────
                    Row(
                      children: [
                        // ⚠️ Glass with a coloured glyph, **not** a solid
                        // chip of the slot hue. A saturated 40pt square is the
                        // brightest object on the card by a distance, so it
                        // wins the eye from the balance — the one thing anyone
                        // opens this screen to read. The hue still carries
                        // identity twice over: in the glyph, and in the bloom
                        // behind the glass.
                        Container(
                          width: width * 0.115,
                          height: width * 0.115,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(width * 0.038),
                          ),
                          child: Icon(
                            BudgyIcons.resolve(account.iconKey),
                            size: width * 0.058,
                            color: tint,
                          ),
                        ),
                        SizedBox(width: width * 0.04),
                        Expanded(
                          child: Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleLarge?.copyWith(
                              color: ink,
                            ),
                          ),
                        ),
                        SizedBox(width: width * 0.03),
                        CustomPaint(
                          size: Size.square(width * 0.06),
                          painter: _ContactlessPainter(
                            color: ink.withValues(alpha: 0.32),
                          ),
                        ),
                      ],
                    ),

                    // ── The figure ────────────────────────────────────
                    //
                    // Takes the slack rather than being pushed to the bottom
                    // by a `Spacer`. A card is a fixed aspect, so at full
                    // width there is a lot of slack — parked at one end it
                    // reads as a mis-set layout; centred it reads as the thing
                    // the card is *for*.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BALANCE',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: ink.withValues(alpha: 0.5),
                            ),
                          ),
                          SizedBox(height: width * 0.015),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: MoneyText(
                              balance.minor,
                              currency: account.currency,
                              // Hero, and the unit trailing — the same read as
                              // the balance panel. A card's figure *is* its
                              // composition, so it follows the panel's rule
                              // rather than the ledger-row one.
                              size: MoneySize.hero,
                              symbolTrailing: true,
                              showDecimals: false,
                              // Never the error red, even overdrawn. On a
                              // dark card a red figure reads as a rendering
                              // fault, and the minus sign already carries it.
                              color: ink,
                            ),
                          ),
                          if (foreign) ...[
                            SizedBox(height: width * 0.012),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '≈ ',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: ink.withValues(alpha: 0.5),
                                  ),
                                ),
                                MoneyText(
                                  balance.baseMinor,
                                  currency: base,
                                  size: MoneySize.small,
                                  color: ink.withValues(alpha: 0.5),
                                  showDecimals: false,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Chrome band ───────────────────────────────────
                    //
                    // The slot a real card spends on its number. Budgy has no
                    // number to print, so it carries the currency code — the
                    // other thing permanently true about a wallet — and
                    // anchors the bottom edge so the figure is not left
                    // floating in the lower half.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          account.currencyCode.split('').join(' '),
                          style: context.textTheme.labelMedium?.copyWith(
                            color: ink.withValues(alpha: 0.45),
                            letterSpacing: 1.6,
                          ),
                        ),
                        const Spacer(),
                        if (account.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: ink.withValues(alpha: 0.85),
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rotates a hue while holding saturation and lightness — a second bloom that
/// is recognisably the same wallet, lit from a different side.
Color _throwHue(Color color, double degrees) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

/// The light a raised edge catches. Not a border — it fades out before the
/// shoulders and never closes around the shape.
class _CardEdgePainter extends CustomPainter {
  _CardEdgePainter({required this.radius, required this.strength});

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
            Colors.white.withValues(alpha: strength * 0.22),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.18, 0.40],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_CardEdgePainter old) =>
      old.strength != strength || old.radius != radius;
}

/// The three-arc contactless mark. Painted rather than taken from the icon set
/// because it has to sit at an exact optical weight beside the card's own
/// glyph, and the packaged version is a different stroke at every size.
class _ContactlessPainter extends CustomPainter {
  _ContactlessPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.085;

    // The arcs radiate from off the left edge, so the mark reads as waves
    // leaving the card rather than as three nested brackets.
    final origin = Offset(-size.width * 0.35, size.height / 2);
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: size.width * 0.33 * i),
        -math.pi / 4.4,
        math.pi / 2.2,
        false,
        paint..color = color.withValues(alpha: color.a * (1 - (i - 1) * 0.18)),
      );
    }
  }

  @override
  bool shouldRepaint(_ContactlessPainter old) => old.color != color;
}
