import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Film grain, tiled over a surface.
///
/// ## Why a dark surface needs it
///
/// A gradient rendered at 8 bits per channel across 300 points produces
/// **banding** — visible steps where the ramp crosses a quantisation
/// boundary. It is worst exactly where Budgy's header lives: a dark,
/// low-contrast, large-area field. The standard fix in film and in games is
/// dithering, and grain is dithering you can see on purpose: a pixel of noise
/// pushes neighbouring samples either side of the boundary so the step
/// dissolves into texture.
///
/// So this is not decoration bolted onto the aurora. Without it the header
/// has visible contour lines on most phone panels; with it the same field
/// reads as a material. That it also makes a flat surface feel expensive is a
/// bonus the compositing was going to pay for anyway.
///
/// The noise tile is generated **once per process** and shared by every
/// surface in the app — regenerating a bitmap per card would be absurd, and
/// re-randomising per rebuild would make the grain crawl.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({
    super.key,
    this.intensity = 0.055,
    this.blendMode = BlendMode.overlay,
    this.child,
  });

  /// How much of the noise layer lands. The useful range is roughly 0.03 to
  /// 0.09 — past that it stops being texture and starts being dirt.
  final double intensity;

  final BlendMode blendMode;

  final Widget? child;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> {
  ui.Image? _tile;

  @override
  void initState() {
    super.initState();
    final ready = _GrainTile.ready;
    if (ready != null) {
      _tile = ready;
    } else {
      // Fire and forget. Until it resolves the surface simply renders without
      // grain, which is a correct intermediate state rather than a blank
      // frame — nothing here is load-bearing for legibility.
      _GrainTile.load().then((image) {
        if (mounted) setState(() => _tile = image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile;
    final child = widget.child;
    if (tile == null) return child ?? const SizedBox.expand();

    return CustomPaint(
      foregroundPainter: _GrainPainter(
        tile: tile,
        intensity: widget.intensity,
        blendMode: widget.blendMode,
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.tile,
    required this.intensity,
    required this.blendMode,
  });

  final ui.Image tile;
  final double intensity;
  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty || intensity <= 0) return;

    // The layer's own paint carries both the blend mode and the opacity, so
    // the noise composites against the surface *as a whole* at one strength.
    // Putting the alpha on the tile instead would blend each grain
    // individually and lose the overlay curve.
    canvas.saveLayer(
      rect,
      Paint()
        ..blendMode = blendMode
        ..color = Colors.white.withValues(alpha: intensity.clamp(0.0, 1.0)),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.ImageShader(
          tile,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.tile != tile ||
      old.intensity != intensity ||
      old.blendMode != blendMode;
}

/// The shared noise bitmap.
class _GrainTile {
  _GrainTile._();

  /// 128 is the smallest tile at which repetition is not legible as a grid at
  /// arm's length, and costs 64KB of RGBA — cheap enough to hold forever.
  static const int _size = 128;

  static ui.Image? _image;
  static Future<ui.Image>? _pending;

  /// The tile if it is already decoded, else null. Lets the first frame skip
  /// a `setState` round-trip once any surface in the app has warmed it.
  static ui.Image? get ready => _image;

  static Future<ui.Image> load() {
    final done = _image;
    if (done != null) return Future.value(done);
    return _pending ??= _decode().then((image) {
      _image = image;
      _pending = null;
      return image;
    });
  }

  static Future<ui.Image> _decode() {
    // Fixed seed: the grain must be identical on every launch and on every
    // surface, otherwise two adjacent cards carry visibly different textures.
    final random = math.Random(0x8ADF);
    final pixels = Uint8List(_size * _size * 4);

    for (var i = 0; i < _size * _size; i++) {
      // Centred on mid-grey because the layer composites with `overlay`,
      // where 128 is the identity value — so the noise lightens and darkens
      // the surface symmetrically instead of fogging it one way.
      final value = (128 + (random.nextDouble() - 0.5) * 150)
          .clamp(0, 255)
          .toInt();
      final offset = i * 4;
      pixels[offset] = value;
      pixels[offset + 1] = value;
      pixels[offset + 2] = value;
      pixels[offset + 3] = 255;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _size,
      _size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
