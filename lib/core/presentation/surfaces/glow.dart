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
