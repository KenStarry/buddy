import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import '../surfaces/glow.dart';
import '../surfaces/grain.dart';
import 'press_scale.dart';

/// Budgy's **object card**: a pane of glass lit from behind by its own colour.
///
/// The one surface every nameable thing in the app wears — a wallet, a budget,
/// a goal. Three near-identical implementations of this existed before it did,
/// which is exactly how a design language rots: each copy drifts a few percent
/// on the gradient, a point on the radius, a different falloff on the edge, and
/// within a release the cards no longer look related.
///
/// The recipe, in order: a near-black base, two blooms of the object's own hue,
/// a white pane gradient, grain, an edge specular. Everything above the base is
/// translucent, which is why the blooms read *through* the pane rather than
/// beside it.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    required this.tint,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.flip = false,
  });

  final Widget child;

  /// The object's identity colour — a slot from the validated categorical
  /// ramp via `categoryAt`, never a free-form hex.
  final Color tint;

  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;

  /// Mirrors the blooms, so a rail or a column of these does not read as one
  /// image printed five times. Feed it the item's index parity.
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final border = BorderRadius.circular(radius);

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: HapticLevel.medium,
      borderRadius: border,
      child: ClipRRect(
        borderRadius: border,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: c.surface200)),
              // ⚠️ **Both** blooms are the object's own hue, the second thrown
              // ~35°. Using the brand accent for the second one puts the same
              // cast on every card in a list and quietly undoes the thing the
              // colour slot exists for.
              Positioned.fill(
                child: AmbientGlow(
                  blooms: [
                    AmbientBloom(
                      color: tint,
                      center: Alignment(flip ? -0.75 : 0.8, -0.7),
                      radius: 0.85,
                      strength: 0.52,
                    ),
                    AmbientBloom(
                      // ⚠️ A short throw, and faint. At 35° a tangerine card's
                      // second bloom lands on yellow, and yellow at low
                      // luminance over near-black is olive — which reads as
                      // the card being dirty rather than lit.
                      color: throwHue(tint, 20),
                      center: Alignment(flip ? 0.7 : -0.7, 0.9),
                      radius: 1.0,
                      strength: 0.16,
                    ),
                  ],
                ),
              ),
              // The pane. What turns two coloured smudges into a surface with
              // a direction to its light.
              Positioned.fill(
                child: DecoratedBox(
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
              ),
              const Positioned.fill(child: GrainOverlay(intensity: 0.06)),
              Positioned.fill(
                child: CustomPaint(
                  painter: _EdgePainter(radius: radius, strength: 0.30),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The glyph tile that leads an object card.
///
/// ⚠️ Glass with a **coloured glyph**, not a solid chip of the identity hue. A
/// saturated 40pt square is the brightest object on a near-black card by a
/// distance, so it wins the eye from the figure — the one thing anyone opened
/// the card to read. The hue still lands twice: in the glyph, and in the bloom
/// behind the pane.
class GlassGlyph extends StatelessWidget {
  const GlassGlyph({
    super.key,
    required this.tint,
    this.icon,
    this.emoji,
    this.size = 40,
  });

  final Color tint;
  final IconData? icon;
  final String? emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.heroInk.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.46, height: 1))
          : Icon(icon, size: size * 0.50, color: tint),
    );
  }
}

/// Rotates a hue while holding saturation and lightness — a second bloom that
/// is recognisably the same object, lit from a different side.
Color throwHue(Color color, double degrees) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

/// The light a raised edge catches. Not a border — it fades out before the
/// shoulders and never closes around the shape.
class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.radius, required this.strength});

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
  bool shouldRepaint(_EdgePainter old) =>
      old.strength != strength || old.radius != radius;
}
