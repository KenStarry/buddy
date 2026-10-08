import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/budgy_shadows.dart';
import '../../utils/extensions/context_extensions.dart';
import '../components/press_scale.dart';

@immutable
class PillDestination {
  const PillDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;

  /// Not painted — the bar is icon-only (see the note on [BudgyPillNav]). It
  /// is the accessibility label, which is the job it was always best at.
  final String label;
}

/// Budgy's floating navigation: a frosted pill of equal slots with a
/// travelling disc, and a separate accent **add** button beside it.
///
/// ## Why icon-only
///
/// A permanent 9pt label under every icon doubles the bar's height and halves
/// the glyph's budget, and in a four-tab app with four conventional icons it
/// is telling people something they worked out on the first launch and have
/// not needed since. Dropping the labels buys a shorter bar, a bigger glyph,
/// and room for the selection to be a **disc** rather than a stadium — which
/// is what makes the indicator read as a physical token sliding along a track
/// instead of a rectangle growing and shrinking. The labels survive as
/// semantics, so a screen reader is unaffected.
///
/// ## Why slots are equal width
///
/// Growing the selected slot to fit a label means every slot moves whenever
/// the selection does, so there is no fixed track for the indicator to slide
/// along — and the bar's own width breathes on every tap. Equal slots keep the
/// geometry still, which is what you want from the one element meant to be the
/// app's fixed point.
///
/// ## Why the add button is outside the bar
///
/// Centre-notching the primary action into the nav makes it a fifth tab that
/// happens to be bigger — it inherits the bar's fill, its shadow and its
/// alignment, and it stops reading as *the* action. Sitting apart, on its own
/// glow, it is unmistakably the thing you came to do. Logging a transaction is
/// also the single most frequent action in a budget app, so it gets the
/// thumb's home position.
class BudgyPillNav extends StatelessWidget {
  const BudgyPillNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final List<PillDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  static const double barHeight = 62;

  /// The travelling disc's diameter. Inset from the bar so the frosted fill
  /// shows as a ring of track all the way around it.
  static const double _disc = barHeight - 14;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final count = destinations.length;
    final selected = currentIndex.clamp(0, count - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12 + context.viewPadding.bottom * 0.4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(barHeight / 2),
                boxShadow: BudgyShadows.lifted(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(barHeight / 2),
                // Frosted rather than opaque. The bar floats over the content
                // (`extendBody`), and a solid slab there is a hole punched in
                // the page — the blur keeps the page continuous underneath
                // while still carrying its own icons at full contrast.
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: ColoredBox(
                    color: c.surface200.withValues(
                      alpha: context.isDark ? 0.74 : 0.80,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final slot = constraints.maxWidth / count;
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 420),
                              // A touch of overshoot. The disc is a physical
                              // token in this metaphor, and a physical token
                              // sliding to a stop does not arrive at exactly
                              // its mark on the first try.
                              curve: Curves.easeOutBack,
                              left: slot * selected + (slot - _disc) / 2,
                              top: (barHeight - _disc) / 2,
                              width: _disc,
                              height: _disc,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.lerp(c.primary, c.accent, 0.28)!,
                                      c.primary,
                                    ],
                                  ),
                                  boxShadow: BudgyShadows.glow(
                                    context,
                                    c.primary,
                                    strength: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < count; i++)
                                  Expanded(
                                    child: _Slot(
                                      destination: destinations[i],
                                      active: i == selected,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        onSelected(i);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _AddButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final PillDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;

    return Semantics(
      label: destination.label,
      selected: active,
      button: true,
      child: PressScale(
        onTap: onTap,
        enableHaptics: false,
        scale: 0.88,
        child: Center(
          child: AnimatedScale(
            scale: active ? 1.08 : 1,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                active ? destination.activeIcon : destination.icon,
                key: ValueKey(active),
                size: 21,
                color: active ? c.primaryInk : c.text300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    return Semantics(
      label: 'Add an entry',
      button: true,
      child: PressScale(
        onTap: onTap,
        haptic: HapticLevel.medium,
        scale: 0.93,
        child: Container(
          width: BudgyPillNav.barHeight,
          height: BudgyPillNav.barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.accentPop, c.accent],
            ),
            shape: BoxShape.circle,
            boxShadow: BudgyShadows.glow(context, c.accent, strength: 1.3),
          ),
          child: Icon(
            LucideIcons.plus,
            // Ink chosen from the accent's own brightness: electric mint needs
            // dark ink, a deep accent needs white, and the scheme picker can
            // swap between them.
            color:
                ThemeData.estimateBrightnessForColor(c.accent) ==
                    Brightness.dark
                ? Colors.white
                : const Color(0xFF07271B),
            size: 26,
          ),
        ),
      ),
    );
  }
}
