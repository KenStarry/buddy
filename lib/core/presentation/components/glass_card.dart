import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

/// A circular chrome button on a lit surface.
///
/// ⚠️ Glass, never a `surface` fill. An opaque disc sitting on a lit page
/// reads as a **hole punched through it** — the one place where the light
/// visibly stops. Translucent ink lets what is behind carry through, so the
/// button sits on the surface rather than in it.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.badge = false,
    this.iconColor,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Raises the glass a step, for a toggle that is currently on.
  final bool active;

  /// A small alarm dot in the corner — "there is something in here".
  final bool badge;

  final Color? iconColor;
  final double size;

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
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: active ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: size * 0.45,
              color:
                  iconColor ??
                  (active ? c.accent : ink.withValues(alpha: 0.75)),
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
                  // top of the button rather than as part of its glyph. A mark
                  // separator, not an outline.
                  border: Border.all(color: c.surface100, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A selectable glass pill: an optional tinted glyph, a label, an optional
/// trailing chevron. The house control for "one of these, pick one" and for
/// the row of one-tap options under an entry.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.tint,
    this.selected = false,
    this.chevron = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? emoji;

  /// The glyph's colour, and what the pill fills with when selected.
  final Color? tint;

  final bool selected;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = c.heroInk;
    final hue = tint ?? c.accent;
    final hasGlyph = icon != null || emoji != null;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(hasGlyph ? 6 : 13, 6, 13, 6),
        decoration: BoxDecoration(
          // Selection is a **fill step**, not a ring. Budgy draws no borders,
          // and on glass a ring is the one mark that cannot be told apart from
          // the edge specular the surface already has.
          //
          // ⚠️ The step is **neutral**, not the hue. A category colour laid
          // over near-black at pill alpha is mud — tangerine arrives brown —
          // and the pill ends up looking soiled rather than chosen. The hue
          // goes where it can be itself: the glyph disc below, which fills to
          // full strength on selection. Brightness says *picked*, colour says
          // *which*.
          color: ink.withValues(alpha: selected ? 0.19 : 0.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasGlyph) ...[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? hue.withValues(alpha: 0.9)
                      : ink.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 13))
                    : Icon(
                        icon,
                        size: 13,
                        color: selected
                            ? Colors.white
                            : ink.withValues(alpha: 0.8),
                      ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                color: selected ? ink : ink.withValues(alpha: 0.72),
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: ink.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
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
