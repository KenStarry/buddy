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
  const AmbientGlow({super.key, required this.blooms, this.child});

  final List<AmbientBloom> blooms;
  final Widget? child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _AmbientPainter(blooms),
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
  _AmbientPainter(this.blooms);

  final List<AmbientBloom> blooms;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;
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
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.blooms != blooms;
}
