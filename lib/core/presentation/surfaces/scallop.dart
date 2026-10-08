import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import '../components/press_scale.dart';

/// Builds a rounded rectangle whose **top edge is scooped** by one or more
/// shallow concave curves.
///
/// This is Midnight's one piece of non-rectangular geometry, and it is load
/// bearing rather than decorative. A scoop is a *negative* shape: it says
/// something is tucked in behind this edge, the way a card pocket does. That
/// lets two surfaces overlap and read as one assembly — accounts slid in
/// behind the balance panel, an icon nested in the mouth of its own button —
/// where two plain rectangles would just read as two rectangles.
///
/// ⚠️ Width and depth are **independent**, and the curve is a pair of cubics
/// rather than an arc. A circular notch ties depth to width, so any scoop wide
/// enough to look like a pocket mouth is also deep enough to look like a bite
/// taken out of the panel. Separating them is the whole difference between
/// "something slides in here" and Pac-Man.
///
/// [notchCenters] are fractions of the width, ascending.
Path scoopedRRectPath({
  required Size size,
  required double radius,
  required List<double> notchCenters,
  required double notchWidth,
  required double notchDepth,
}) {
  final w = size.width;
  final h = size.height;
  final r = radius.clamp(0.0, math.min(w, h) / 2);
  final halfW = (notchWidth / 2).clamp(0.0, w / 2);
  final depth = notchDepth.clamp(0.0, h / 2);

  final path = Path()..moveTo(r, 0);

  if (halfW > 0 && depth > 0) {
    // Sorted and de-overlapped, because an unsorted or overlapping pair
    // produces a self-intersecting path that the rasteriser fills with the
    // even-odd rule — which renders as a hole in the *middle* of the panel
    // rather than a scoop in its edge.
    final centers = [for (final f in notchCenters) f.clamp(0.0, 1.0) * w]
      ..sort();
    var lastEdge = r;
    for (final cx in centers) {
      final left = cx - halfW;
      final right = cx + halfW;
      if (left < lastEdge || right > w - r) continue;
      path.lineTo(left, 0);
      // Control points at 45% of the half-width keep the shoulders tangent to
      // the straight edge, so the scoop joins the top without a visible kink.
      path.cubicTo(left + halfW * 0.45, 0, cx - halfW * 0.45, depth, cx, depth);
      path.cubicTo(cx + halfW * 0.45, depth, right - halfW * 0.45, 0, right, 0);
      lastEdge = right;
    }
  }

  path.lineTo(w - r, 0);
  path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
  path.lineTo(w, h - r);
  path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
  path.lineTo(r, h);
  path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
  path.lineTo(0, r);
  path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

  return path..close();
}

/// [scoopedRRectPath] as a clipper.
class ScoopedBorderClipper extends CustomClipper<Path> {
  const ScoopedBorderClipper({
    required this.radius,
    required this.notchCenters,
    required this.notchWidth,
    required this.notchDepth,
  });

  final double radius;
  final List<double> notchCenters;
  final double notchWidth;
  final double notchDepth;

  @override
  Path getClip(Size size) => scoopedRRectPath(
    size: size,
    radius: radius,
    notchCenters: notchCenters,
    notchWidth: notchWidth,
    notchDepth: notchDepth,
  );

  @override
  bool shouldReclip(ScoopedBorderClipper old) =>
      old.radius != radius ||
      old.notchWidth != notchWidth ||
      old.notchDepth != notchDepth ||
      !listEquals(old.notchCenters, notchCenters);
}

/// A surface with scooped top edge, filled flat or with a gradient.
///
/// ⚠️ The fill is clipped, not shadowed. On a near-black page a drop shadow is
/// worth almost nothing — there is no light for it to subtract — so this
/// surface separates from the page by **fill** alone, which is exactly what
/// the four-step surface ramp in `BudgyPalette` exists to make possible.
class ScoopedSurface extends StatelessWidget {
  const ScoopedSurface({
    super.key,
    required this.child,
    required this.color,
    this.gradient,
    this.radius = 28,
    this.notchCenters = const [],
    this.notchWidth = 0,
    this.notchDepth = 0,
    this.padding = EdgeInsets.zero,
    this.blur = 0,
    this.specular = 0,
    this.underlay,
  });

  final Widget child;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final List<double> notchCenters;
  final double notchWidth;
  final double notchDepth;
  final EdgeInsetsGeometry padding;

  /// Backdrop blur sigma. Non-zero turns this into **glass**: the fill should
  /// then be translucent, and there must be something behind it worth
  /// refracting (see `AmbientGlow` — frosting a flat black page produces a
  /// flat black panel and an expensive saveLayer).
  final double blur;

  /// Strength of the light that catches along the scooped edge. Not a border:
  /// it traces the actual silhouette, scoops included, and fades out well
  /// before the sides.
  final double specular;

  /// Painted **inside the clip**, beneath the fill — the light this surface is
  /// lit by.
  ///
  /// ⚠️ Pass the glow here rather than stacking it behind the surface. A glow
  /// placed behind is clipped by nothing: it bleeds past the rounded corners
  /// and, wherever the surface turns out narrower than its parent, straight
  /// out across the page as a visible rectangle of light. Inside, it is bound
  /// by the same silhouette as everything else.
  final Widget? underlay;

  @override
  Widget build(BuildContext context) {
    final clipper = ScoopedBorderClipper(
      radius: radius,
      notchCenters: notchCenters,
      notchWidth: notchWidth,
      notchDepth: notchDepth,
    );

    // ⚠️ Width-greedy, and it has to be *this* widget rather than a wrapper
    // outside the clip. A `Stack` hands its non-positioned children loose
    // constraints, so a bare `DecoratedBox` here shrinks to the width of its
    // own text — which leaves the underlay showing down one side as a raw
    // rectangle of light, and the panel looking like a layout bug.
    final fill = SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    Widget surface = underlay == null
        ? fill
        : Stack(
            children: [
              Positioned.fill(child: underlay!),
              fill,
            ],
          );

    if (blur > 0) {
      surface = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }

    // ⚠️ Width-greedy. A `Stack` hands its non-positioned children *loose*
    // constraints, so without this a panel silently shrinks to the width of
    // its own text — which looks like a layout bug and, with an underlay
    // behind it, exposes the glow down one side of the page.
    Widget clipped = ClipPath(clipper: clipper, child: surface);

    if (specular > 0) {
      clipped = CustomPaint(
        foregroundPainter: _ScoopEdgePainter(
          clipper: clipper,
          strength: specular,
        ),
        child: clipped,
      );
    }
    return clipped;
  }
}

/// Traces the scooped silhouette in light.
///
/// Budgy draws no borders, and this is not one: it is a **specular** — the
/// highlight a raised glass edge catches from the light behind it — and it
/// fades to nothing a third of the way down, so it never closes around the
/// shape. Tracing the real path rather than a rounded rect is the whole
/// point: it is what makes the scoops read as a lip you could slide a card
/// under.
class _ScoopEdgePainter extends CustomPainter {
  _ScoopEdgePainter({required this.clipper, required this.strength});

  final ScoopedBorderClipper clipper;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawPath(
      clipper.getClip(size),
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
  bool shouldRepaint(_ScoopEdgePainter old) =>
      old.strength != strength || old.clipper != clipper;
}

/// One of the home screen's primary actions: a filled pill with a single
/// scoop at the top, and its icon sitting **in** the scoop.
///
/// The icon is not inside the button. It sits on the page, in the mouth the
/// button's own edge opens for it — which is what makes three of these read as
/// one row of instruments rather than three separate buttons with pictures on
/// them. It is also the only reason the label can sit dead centre at this
/// height without the pair looking top-heavy.
class ScoopButton extends StatelessWidget {
  const ScoopButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.fill,
    required this.ink,
    this.iconInk,
    this.height = 66,
    this.radius = 22,
    // ⚠️ Wide and shallow, and the ratio matters more than either number. A
    // narrow deep scoop on a 110pt pill is a bite out of a biscuit; the same
    // area spread across two thirds of the width is a dip the glyph rests in.
    this.notchWidth = 58,
    this.notchDepth = 16,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// The pill's own fill — `primary`, which on dark is white.
  final Color fill;

  /// The foreground on [fill].
  final Color ink;

  /// The glyph's colour. It sits on the **page**, not on [fill], so it takes
  /// page ink — defaulting to it here rather than letting a caller reach for
  /// [ink] and silently paint a white glyph on a near-black page.
  final Color? iconInk;

  final double height;
  final double radius;
  final double notchWidth;
  final double notchDepth;

  /// How far the glyph sits above the pill's top edge. It nests in the mouth
  /// the scoop opens, straddling the rim — far enough up to clear the curve,
  /// close enough that the pair reads as one object.
  static const double _iconLift = 15;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.medium,
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height + _iconLift,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height,
              child: ScoopedSurface(
                color: fill,
                radius: radius,
                notchCenters: const [0.5],
                notchWidth: notchWidth,
                notchDepth: notchDepth,
                child: Align(
                  alignment: const Alignment(0, 0.55),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelLarge?.copyWith(color: ink),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Icon(
                icon,
                size: 19,
                color: iconInk ?? context.budgyColors.text100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
