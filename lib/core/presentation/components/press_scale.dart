import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tap feedback: a small scale-down on press, plus a haptic.
///
/// Budgy's cards are big and mostly tappable, and Material's ink ripple reads
/// badly on a 24-radius white card over cream — the splash clips to the
/// rectangle and flashes grey. A press-scale says "this is a button" without
/// painting anything.
///
/// ⚠️ Uses a raw [Listener]-style gesture set rather than `InkWell`'s, and
/// resets on cancel as well as up. Tracking only `onTapDown`/`onTapUp` leaves
/// the card stuck at 0.97 forever when the press turns into a scroll — which
/// is most presses on a scrolling page.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.enableHaptics = true,
    this.haptic = HapticLevel.light,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enableHaptics;
  final HapticLevel haptic;

  /// Only used for the hit-test shape; nothing is painted.
  final BorderRadius? borderRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

enum HapticLevel { light, medium, selection }

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _fire() {
    if (widget.enableHaptics) {
      switch (widget.haptic) {
        case HapticLevel.light:
          HapticFeedback.lightImpact();
        case HapticLevel.medium:
          HapticFeedback.mediumImpact();
        case HapticLevel.selection:
          HapticFeedback.selectionClick();
      }
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    if (!interactive) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null ? null : _fire,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.enableHaptics) HapticFeedback.mediumImpact();
              widget.onLongPress!.call();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
