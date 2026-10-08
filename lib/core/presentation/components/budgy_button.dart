import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/budgy_shadows.dart';
import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// The primary action. Emerald fill, dyed glow, press-scale, and a morph to a
/// circular spinner while working.
///
/// ⚠️ The loading state **keeps the button's footprint**: it animates to a
/// circle in place rather than being swapped for a `CircularProgressIndicator`
/// of a different size. Replacing it reflows whatever sits below — on a sheet
/// with a button at the bottom, the whole sheet jumps the moment you tap.
class BudgyFilledButton extends StatefulWidget {
  const BudgyFilledButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconTrailing = false,
    this.isLoading = false,
    this.disabled = false,
    this.enableHaptics = true,
    this.background,
    this.foreground,
    this.height = 54,
    this.width,
    this.radius = 18,
  });

  final String label;
  final FutureOr<void> Function()? onTap;
  final IconData? icon;

  /// Put the icon after the label. For forward motion — "Next →" — where a
  /// leading arrow points back at the word it is meant to follow.
  final bool iconTrailing;

  final bool isLoading;
  final bool disabled;
  final bool enableHaptics;
  final Color? background;
  final Color? foreground;
  final double height;
  final double? width;
  final double radius;

  @override
  State<BudgyFilledButton> createState() => _BudgyFilledButtonState();
}

class _BudgyFilledButtonState extends State<BudgyFilledButton> {
  bool _pressed = false;
  bool _busy = false;

  bool get _loading => widget.isLoading || _busy;
  bool get _inert => widget.disabled || _loading || widget.onTap == null;

  Future<void> _fire() async {
    if (_inert) return;
    if (widget.enableHaptics) HapticFeedback.mediumImpact();
    final action = widget.onTap;
    if (action == null) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      // The button may have been disposed while the action ran — a save that
      // navigates away is the normal case, not the edge case.
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final fill = widget.disabled
        ? c.surface300
        : (widget.background ?? c.primary);
    final ink = widget.disabled
        ? c.text300
        : (widget.foreground ?? c.primaryInk);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _inert ? null : (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _fire,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: widget.height,
          width: _loading ? widget.height : widget.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(
              _loading ? widget.height / 2 : widget.radius,
            ),
            boxShadow: widget.disabled
                ? null
                : BudgyShadows.glow(
                    context,
                    fill,
                    strength: _pressed ? 0.5 : 1,
                  ),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(ink),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null && !widget.iconTrailing) ...[
                        Icon(widget.icon, size: 18, color: ink),
                        const SizedBox(width: 9),
                      ],
                      Text(
                        widget.label,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: ink,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.icon != null && widget.iconTrailing) ...[
                        const SizedBox(width: 9),
                        Icon(widget.icon, size: 18, color: ink),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// The secondary action. A tonal fill rather than an outline — Budgy draws no
/// borders in light mode, so an "outlined" button here is a `surface300`
/// panel with ink text.
class BudgyTonalButton extends StatelessWidget {
  const BudgyTonalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 54,
    this.width,
    this.radius = 18,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final double? width;
  final double radius;

  /// Error-tinted. For "Delete", and nothing softer.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final ink = destructive ? c.errorMain : c.text100;
    final fill = destructive ? c.errorSurface : c.surface300;

    return PressScale(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: ink),
                const SizedBox(width: 9),
              ],
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: ink,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A square icon button — the masthead's chrome.
class BudgyIconButton extends StatelessWidget {
  const BudgyIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.tone,
    this.iconColor,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? tone;
  final Color? iconColor;

  /// A small accent dot in the corner — "there is something in here".
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
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
              color: tone ?? c.surface200,
              borderRadius: BorderRadius.circular(size * 0.32),
              boxShadow: BudgyShadows.pressed(context),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? c.text100),
          ),
          if (badge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  // Ringed in the PAGE colour so the dot reads as sitting on
                  // top of the button rather than as part of its glyph. This
                  // is a mark separator, not an outline — the no-border rule
                  // is about surfaces.
                  border: Border.all(color: c.surface100, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
