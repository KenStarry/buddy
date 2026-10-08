import 'package:flutter/material.dart';

/// Soft blooms of light painted **over whatever is behind**, with no base
/// fill of its own.
///
/// The reason this exists at all: glass needs something to refract. A frosted panel on a flat near-black page blurs
/// near-black and produces near-black — the blur is real, costs a saveLayer,
/// and is completely invisible. Lay a couple of wide, faint blooms on the page
/// first and the same panel suddenly has colour moving through it, an edge
/// that catches, and a reason to be glass at all.
///
/// Deliberately faint. These are ambient light, not objects: if you can point
/// at where the bloom ends, it is too strong.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({
    super.key,
    required this.blooms,
    this.fadeBottom = 0,
    this.child,
  });

  final List<AmbientBloom> blooms;

  /// Dissolve the glow over the bottom fraction of its own box.
  ///
  /// ⚠️ Load-bearing wherever a glow ends inside a scrolling page. A bloom is
  /// a radial gradient that is still well above zero alpha when it reaches the
  /// edge of the box it is painted in, so the box **clips** it — and a clipped
  /// gradient is a hard horizontal line across the page. The fix is not a
  /// taller box (the line just moves); it is fading the layer out before its
  /// own edge, so the light dies rather than stopping.
  final double fadeBottom;

  final Widget? child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _AmbientPainter(blooms, fadeBottom),
      isComplex: true,
      child: child ?? const SizedBox.expand(),
    ),
  );
}

/// Raises a hue to a **light source's** lightness.
///
/// ⚠️ Use this for any bloom whose colour comes from data (a category slot, a
/// wallet's hue) rather than from the accent. A mid-tone hue laid over
/// near-black at low alpha does not read as coloured light; it reads as dirty
/// paint — tangerine goes brown, amber goes olive, and the screen looks
/// stained rather than lit. Real light is bright and desaturated at its core,
/// so the bloom is drawn with the hue lifted and the saturation eased off; the
/// low alpha then does the work of making it subtle.
Color asLight(Color color) {
  final hsl = HSLColor.fromColor(color);
  // ⚠️ Saturation is cut *hard*, not trimmed. At 85% a tangerine category lit
  // the entry screen sepia — the page read as dusty rather than lit, because
  // a warm mid-saturation hue over near-black is exactly the colour of dirt.
  // Real light is close to white at its core and only carries a cast; pulling
  // saturation to a third and the lightness up gets that, and the bloom's own
  // low alpha keeps the cast visible.
  return hsl
      .withLightness(0.76)
      .withSaturation((hsl.saturation * 0.34).clamp(0.0, 0.5))
      .toColor();
}

@immutable
class AmbientBloom {
  const AmbientBloom({
    required this.color,
    required this.center,
    this.radius = 0.9,
    this.strength = 0.22,
  });

  final Color color;
  final Alignment center;
  final double radius;
  final double strength;
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.blooms, this.fadeBottom);

  final List<AmbientBloom> blooms;
  final double fadeBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;

    final fade = fadeBottom.clamp(0.0, 1.0);
    // The fade is applied with `dstIn` against the blooms alone, so the layer
    // is explicit — without it the mask would erase whatever is already on the
    // canvas behind this widget.
    if (fade > 0) canvas.saveLayer(rect, Paint());

    for (final bloom in blooms) {
      final alpha = bloom.strength.clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: bloom.center,
            radius: bloom.radius,
            colors: [
              bloom.color.withValues(alpha: alpha),
              bloom.color.withValues(alpha: alpha * 0.30),
              bloom.color.withValues(alpha: 0),
            ],
            // Front-loaded. A linear falloff renders as a visible disc with a
            // rim; easing the mid stop down makes the bloom dissolve the way
            // light does.
            stops: const [0, 0.40, 1],
          ).createShader(rect),
      );
    }

    if (fade > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF),
              const Color(0xFFFFFFFF),
              const Color(0x00FFFFFF),
            ],
            // Held solid until the fade begins, then eased out. The middle
            // stop is what keeps the transition from reading as a second,
            // softer edge.
            stops: [0, 1 - fade, 1],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.blooms != blooms || old.fadeBottom != fadeBottom;
}
