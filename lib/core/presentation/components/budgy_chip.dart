import 'package:flutter/material.dart';

import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// A filter / selection pill.
class BudgyChip extends StatelessWidget {
  const BudgyChip({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.selected = false,
    this.onTap,
    this.tint,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;

  /// Overrides the accent — used so a category chip wears its own colour.
  final Color? tint;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final accent = tint ?? c.accent;
    final fill = selected ? accent : c.surface300;
    // ⚠️ Selected ink is white on the accent, not `primaryInk`. `primaryInk`
    // pairs with `primary` (deep emerald); on the brighter `accent` fill it
    // is near-black in dark mode and vanishes.
    final ink = selected
        ? (ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
              ? Colors.white
              : const Color(0xFF0D1A14))
        : c.text200;

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.selection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 11 : 14,
          vertical: dense ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(dense ? 11 : 13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: TextStyle(fontSize: dense ? 12 : 13)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: dense ? 13 : 15, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style:
                  (dense
                          ? context.textTheme.labelMedium
                          : context.textTheme.labelLarge)
                      ?.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// A status pill — 6px dot plus a label, tinted by state.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.tint,
    this.icon,
  });

  final String label;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: tint)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(color: tint),
          ),
        ],
      ),
    );
  }
}

/// The travelling-pill segmented tab bar.
///
/// ⚠️ **One pill slides A→B.** Giving each segment its own animated
/// background cross-fades the selection — it dissolves in one place and
/// reappears in another with nothing connecting them, which reads as two
/// controls where one lit up. A single indicator moving between equal slots
/// reads as *the same control, new state*. (RezQ's `SegmentedPillTabs`
/// records the same ruling; the geometry is easier here because Budgy's
/// segments are equal width by construction.)
class SegmentedPillTabs extends StatelessWidget {
  const SegmentedPillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 46,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final count = labels.length;
    if (count == 0) return const SizedBox.shrink();
    final selected = index.clamp(0, count - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // ⚠️ Glass, and the **thumb is lighter than the track** — it used to
        // be `surface200` on `surface300`, which on a dark page made the
        // selected segment darker than the thing it sits in. That inversion
        // is a leftover from the cream palette, where a white thumb genuinely
        // did lift off a sand track; carried onto near-black it reads as the
        // live tab being switched off.
        color: c.heroInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / count;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: slot * selected,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.heroInk.withValues(alpha: 0.20),
                        c.heroInk.withValues(alpha: 0.13),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: PressScale(
                        onTap: () => onChanged(i),
                        haptic: HapticLevel.selection,
                        scale: 1,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style:
                                context.textTheme.labelLarge?.copyWith(
                                  color: i == selected
                                      ? c.heroInk
                                      : c.heroInk.withValues(alpha: 0.5),
                                ) ??
                                const TextStyle(),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
