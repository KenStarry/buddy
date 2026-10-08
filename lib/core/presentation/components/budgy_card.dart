import 'package:flutter/material.dart';

import '../../theme/budgy_shadows.dart';
import '../../utils/extensions/context_extensions.dart';
import 'press_scale.dart';

/// How a card is filled.
enum BudgyCardTone {
  /// White on cream. The default, and most of the app.
  plain,

  /// The tonal band — inert containers, nested rows inside a plain card.
  band,

  /// Mint wash. Callouts, tips, "nothing here yet" states.
  wash,

  /// Mid mint. Brand-leaning slots that are not quite heroes.
  accent,
}

/// Budgy's card.
///
/// Depth is a fill difference plus a shadow — never a border. A `band` or
/// `wash` card gets **no** shadow: it is nested inside something, and a
/// shadow on a tinted panel inside a white card reads as a rendering
/// artefact rather than elevation.
class BudgyCard extends StatelessWidget {
  const BudgyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tone = BudgyCardTone.plain,
    this.onTap,
    this.onLongPress,
    this.radius = 24,
    this.elevated = true,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BudgyCardTone tone;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final bool elevated;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final fill = switch (tone) {
      BudgyCardTone.plain => c.surface200,
      BudgyCardTone.band => c.surface300,
      BudgyCardTone.wash => c.accentSoft,
      BudgyCardTone.accent => c.accentMid,
    };
    final borderRadius = BorderRadius.circular(radius);

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: borderRadius,
          // No border, in either mode. A plain card is lifted by its
          // shadow and by being a different fill from the page; the tinted
          // tones are nested inside something and need neither.
          boxShadow: elevated && tone == BudgyCardTone.plain
              ? BudgyShadows.soft(context)
              : null,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// The deep-emerald anchor card. One per screen, at most — it is the thing
/// the eye lands on, and two of them is none.
///
/// Its subtree is wrapped in `primaryInk` text and icon defaults, so children
/// do not each have to remember they are on a dark fill.
class BudgyHeroCard extends StatelessWidget {
  const BudgyHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.radius = 30,
    this.gradient,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Gradient? gradient;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final fill = background ?? c.heroFill;
    final ink = c.heroInk;
    final borderRadius = BorderRadius.circular(radius);

    return PressScale(
      onTap: onTap,
      haptic: HapticLevel.medium,
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? fill : null,
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: BudgyShadows.hero(context, fill),
        ),
        child: Padding(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: ink),
            child: IconTheme.merge(
              data: IconThemeData(color: ink),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The hero's default fill: emerald deepening into near-black, with a mint
/// breath in the top-right corner. Built from the live tokens so it follows
/// the chosen scheme.
LinearGradient budgyHeroGradient(BuildContext context) {
  final c = context.budgyColors;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(c.heroFill, c.accent, context.isDark ? 0.10 : 0.22)!,
      c.heroFill,
      Color.lerp(c.heroFill, Colors.black, context.isDark ? 0.30 : 0.35)!,
    ],
    stops: const [0, 0.55, 1],
  );
}
