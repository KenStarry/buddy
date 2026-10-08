import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';

/// A ratio against a limit — the right form for "spent X of Y".
///
/// Not a pie, not a two-slice donut: a meter on the same track reads as one
/// quantity filling one allowance, which is exactly what a budget is.
///
/// ## The pace marker
///
/// [pace] draws a notch at "how far through the window we are". It is the
/// single most useful mark on a budget card, because 60% spent means opposite
/// things on day 5 and day 25, and a bare fill cannot tell you which.
///
/// The notch is cut in the **surface** colour with a gap either side, so it
/// reads as a tick *through* the bar rather than as another segment of it —
/// the 2px-surface-gap rule from the mark spec, applied to an overlapping
/// mark instead of to adjacent fills.
class BudgyMeter extends StatelessWidget {
  const BudgyMeter({
    super.key,
    required this.fraction,
    this.pace,
    this.color,
    this.trackColor,
    this.height = 10,
    this.animated = true,
  });

  /// 0..1. Clamped — an overspend is told by colour and by the remaining
  /// figure, never by a fill running off the end of its own track.
  final double fraction;

  /// 0..1, or null for no marker.
  final double? pace;

  final Color? color;
  final Color? trackColor;
  final double height;

  /// ⚠️ `animated`, never `animate`. A bool member named `animate` shadows
  /// `flutter_animate`'s `Widget.animate()` extension on this widget, and the
  /// resulting error points at the constructor rather than at the field.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final tint = color ?? c.accent;
    final track = trackColor ?? c.surface300;
    final value = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration: animated
                    ? const Duration(milliseconds: 650)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                // ⚠️ A minimum visible width once there is any spend at all.
                // Without it, the first KSh 200 of a KSh 85,000 budget paints
                // a fill 0.2px wide, which rounds away to nothing and reads
                // as "you have spent zero" immediately after an entry.
                width: value <= 0 ? 0 : math.max(height, width * value),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // ⚠️ Lightened in the tint's OWN hue, not lerped toward
                    // the brand's mint. A meter is tinted by state — amber
                    // when ahead of pace, red when over — and mixing 35% mint
                    // into red lands on brown, which is how an over-budget
                    // alarm ended up looking like a rendering fault rather
                    // than a warning.
                    colors: [_lighten(tint, 0.13), tint],
                  ),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (pace != null && pace! > 0.02 && pace! < 0.99)
                Positioned(
                  left: (width * pace!.clamp(0.0, 1.0)) - 3,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 6, color: c.surface200),
                ),
              if (pace != null && pace! > 0.02 && pace! < 0.99)
                Positioned(
                  left: (width * pace!.clamp(0.0, 1.0)) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: c.text300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Raises a colour's lightness while holding its hue and saturation — the
  /// only safe way to build a gradient out of a colour whose identity is its
  /// hue.
  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// One segment of a stacked meter.
@immutable
class MeterSegment {
  const MeterSegment({required this.fraction, required this.color, this.label});

  final double fraction;
  final Color color;
  final String? label;
}

/// Part-to-whole on one track — "where this window's spend went".
///
/// Horizontal rather than a pie, and capped by the caller at a handful of
/// segments with the tail folded into "Other": past ~6 bins adjacent classes
/// blur, and the legend below is what actually carries identity.
///
/// ⚠️ Segments are separated by a 2px gap in the **surface** colour, not by a
/// border and not by nothing. Abutting fills of two validated-adjacent hues
/// still bleed into each other at a 12px height — the gap is what makes the
/// boundary a boundary.
class BudgyStackedMeter extends StatelessWidget {
  const BudgyStackedMeter({
    super.key,
    required this.segments,
    this.height = 14,
    this.gap = 2,
    this.animated = true,
  });

  final List<MeterSegment> segments;
  final double height;
  final double gap;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    if (segments.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: c.surface300,
          borderRadius: BorderRadius.circular(height),
        ),
      );
    }

    final total = segments.fold<double>(0, (sum, s) => sum + s.fraction);
    final safeTotal = total <= 0 ? 1.0 : total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              Expanded(
                flex: math.max(
                  1,
                  ((segments[i].fraction / safeTotal) * 10000).round(),
                ),
                child: AnimatedContainer(
                  duration: animated
                      ? const Duration(milliseconds: 500)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  color: segments[i].color,
                ),
              ),
              if (i < segments.length - 1)
                SizedBox(
                  width: gap,
                  child: ColoredBox(color: c.surface200),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A progress ring. Goals, and nothing else — a budget gets a meter, because
/// a ring hides whether you are ahead of the clock and a goal has no clock to
/// be ahead of.
class BudgyRing extends StatelessWidget {
  const BudgyRing({
    super.key,
    required this.fraction,
    this.size = 64,
    this.thickness = 7,
    this.color,
    this.trackColor,
    this.child,
    this.animated = true,
  });

  final double fraction;
  final double size;
  final double thickness;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final tint = color ?? c.accent;
    final value = (fraction.isNaN ? 0.0 : fraction).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: animated ? const Duration(milliseconds: 750) : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => CustomPaint(
          painter: _RingPainter(
            fraction: animated,
            color: tint,
            trackColor: trackColor ?? c.surface300,
            thickness: thickness,
            glow: Color.lerp(tint, c.accentPop, 0.4)!,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.thickness,
    required this.glow,
  });

  final double fraction;
  final Color color;
  final Color trackColor;
  final double thickness;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (fraction <= 0) return;

    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    final fill = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [glow, color],
      ).createShader(rect)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}
