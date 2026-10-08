import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';

/// Progress as a **travelling wave**.
///
/// The filled portion is a sine stroked with round caps, separated from a flat
/// remaining track by a small gap, with a stop dot at the far end. Material 3
/// Expressive's wavy indicator is the same idea, which Flutter does not ship as
/// of 3.47 — and Budgy needs a pace marker on top of it regardless.
///
/// ## Why a wave rather than a bar
///
/// A flat bar encodes one number and says nothing else. The wave encodes the
/// same number and adds a second, non-numeric channel: it *moves*, so a budget
/// mid-period reads as live rather than as a static report. That matters most
/// where Budgy is weakest — a screen of rectangles full of totals looks like an
/// export, and the one thing a budget is not is finished.
///
/// The motion is slow and the amplitude small on purpose: this is texture, not
/// animation. If you can watch it, it is too fast.
///
/// ⚠️ `animated`, never `animate`. A bool member named `animate` shadows
/// `flutter_animate`'s `Widget.animate()` extension on every instance of this
/// widget, and the resulting error points at the constructor with no mention of
/// the field that caused it.
class WavyMeter extends StatefulWidget {
  const WavyMeter({
    super.key,
    required this.fraction,
    this.pace,
    this.color,
    this.trackColor,
    this.thickness = 8,
    this.amplitude = 2.5,
    this.wavelength = 25,
    this.animated = true,
  });

  /// 0..1. Clamped — an overspend is told by colour and by the remaining
  /// figure, never by a fill running off the end of its own track.
  final double fraction;

  /// 0..1, or null for no marker. The thing that distinguishes a quantity
  /// **racing a clock** (a budget) from one simply accumulating (a goal): only
  /// the former has a pace to be behind.
  final double? pace;

  final Color? color;
  final Color? trackColor;

  /// Stroke width of both the wave and the track.
  final double thickness;

  /// Peak offset of the wave from the centre line. Kept under half the
  /// thickness so the stroke still reads as one continuous ribbon rather than
  /// as a zigzag of disconnected blobs.
  final double amplitude;

  /// Distance between wave crests.
  final double wavelength;

  final bool animated;

  @override
  State<WavyMeter> createState() => _WavyMeterState();
}

class _WavyMeterState extends State<WavyMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// The value the wave is currently drawn at, eased toward [WavyMeter.fraction]
  /// so a logged transaction slides the bar rather than teleporting it.
  late double _shown = widget.fraction.isNaN ? 0 : widget.fraction.clamp(0, 1);

  @override
  void initState() {
    super.initState();
    if (widget.animated) _phase.repeat();
  }

  @override
  void didUpdateWidget(WavyMeter old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_phase.isAnimating) {
      _phase.repeat();
    } else if (!widget.animated && _phase.isAnimating) {
      _phase.stop();
    }
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final target = widget.fraction.isNaN
        ? 0.0
        : widget.fraction.clamp(0.0, 1.0);

    // ⚠️ `RepaintBoundary`. The wave repaints every frame; without it the
    // whole scrolling page's layer is dragged into that repaint, and a rail of
    // four budget cards quietly costs the frame budget of the entire screen.
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _shown, end: target),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        onEnd: () => _shown = target,
        builder: (context, value, _) => AnimatedBuilder(
          animation: _phase,
          builder: (context, _) => CustomPaint(
            size: Size(double.infinity, widget.thickness + widget.amplitude * 2),
            painter: _WavyPainter(
              fraction: value,
              pace: widget.pace,
              phase: widget.animated ? _phase.value : 0,
              color: widget.color ?? c.accent,
              trackColor: widget.trackColor ?? c.heroInk.withValues(alpha: 0.14),
              markerColor: c.heroInk.withValues(alpha: 0.85),
              thickness: widget.thickness,
              amplitude: widget.amplitude,
              wavelength: widget.wavelength,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  _WavyPainter({
    required this.fraction,
    required this.pace,
    required this.phase,
    required this.color,
    required this.trackColor,
    required this.markerColor,
    required this.thickness,
    required this.amplitude,
    required this.wavelength,
  });

  final double fraction;
  final double? pace;
  final double phase;
  final Color color;
  final Color trackColor;
  final Color markerColor;
  final double thickness;
  final double amplitude;
  final double wavelength;

  /// Clear air between the wave's cap and the track's. Without it the two
  /// strokes touch and the whole thing reads as one bar that changes colour.
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    if (w <= 0) return;
    final midY = size.height / 2;
    final r = thickness / 2;

    // Round caps overhang by half the stroke, so the drawable span is inset by
    // that much at each end — otherwise a full bar is visibly clipped and an
    // empty one pokes out of the left edge.
    final left = r;
    final right = w - r;
    final span = right - left;
    if (span <= 0) return;

    final end = left + span * fraction;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = thickness;

    // ── Track ────────────────────────────────────────────────────────────
    final trackStart = math.min(end + _gap, right);
    if (trackStart < right) {
      canvas.drawLine(
        Offset(trackStart, midY),
        Offset(right, midY),
        stroke..color = trackColor,
      );
    }

    // ── Stop dot ─────────────────────────────────────────────────────────
    // Marks where the track ends, so a bar at 80% still shows you where 100%
    // is. M3 puts it in the active colour; it is the only part of the
    // remaining track that belongs to the thing being measured.
    canvas.drawCircle(
      Offset(right, midY),
      r * 0.62,
      Paint()..color = color.withValues(alpha: 0.9),
    );

    // ── The wave ─────────────────────────────────────────────────────────
    if (fraction > 0.001) {
      final path = Path()..moveTo(left, midY);
      final drift = phase * 2 * math.pi;
      // ⚠️ The wave flattens when there is not much of it. Below ~2.5
      // wavelengths a sine stroked at full amplitude is not read as a wave —
      // there are too few crests for the eye to find the period — so a budget
      // at 8% rendered as a fat orange squiggle that looked like a worm. It
      // grows into the wave as it fills, which also gives the bar a second,
      // free reading: flat means barely started.
      final lengthRamp = ((end - left) / (wavelength * 2.5)).clamp(0.0, 1.0);
      // Sampled every 1.2pt rather than per pixel: finer buys nothing visible
      // on a 3pt amplitude and costs a path segment each time.
      for (var x = left; x <= end; x += 1.2) {
        final travelled = x - left;
        // Taper in over the first wavelength so the stroke leaves the left
        // edge level instead of starting mid-crest, which reads as a clipped
        // wave rather than the start of one.
        final ramp = math.min(1.0, travelled / wavelength);
        final y =
            midY +
            amplitude *
                ramp *
                lengthRamp *
                math.sin(travelled / wavelength * 2 * math.pi - drift);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, stroke..color = color);
    }

    // ── Pace marker ──────────────────────────────────────────────────────
    if (pace != null && pace! > 0.02 && pace! < 0.98) {
      final x = left + span * pace!.clamp(0.0, 1.0);
      // Drawn **over** both wave and track rather than punched through as a
      // gap: the card's fill varies (glass over a bloom), so there is no one
      // background colour a gap could be painted in.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, midY),
            width: 2.5,
            height: thickness + 7,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = markerColor,
      );
    }
  }

  @override
  bool shouldRepaint(_WavyPainter old) =>
      old.fraction != fraction ||
      old.pace != pace ||
      old.phase != phase ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.thickness != thickness ||
      old.amplitude != amplitude;
}
