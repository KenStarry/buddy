import 'package:flutter/material.dart';

import '../utils/extensions/context_extensions.dart';

/// The elevation language — one source of truth.
///
/// **Budgy draws no borders.** Not on cards, not on buttons, not on the nav,
/// not in dark mode. A card is lifted off the page by light and by fill, and a
/// hairline around it flattens the whole thing back into a diagram. Every
/// level here is a shadow; there is no border token to reach for, and adding a
/// `Border.all` to a surface is a bug.
///
/// ## Why these are brightness-aware
///
/// ⚠️ A shadow tuned for a cream page is invisible on a near-black one —
/// which is exactly why dark modes so often grow borders. Budgy solves it
/// twice instead: the dark surfaces are stepped far enough apart that a card
/// separates from the page by **fill** before its shadow does any work (see
/// `BudgyPalette`), and the shadows below go pure black, deeper and wider in
/// dark mode so they still read as contact with a surface.
///
/// The shadow ink in light mode is a dark *green*-black rather than neutral:
/// on a warm cream page a neutral shadow goes faintly grey-violet and reads as
/// dirt, where a shadow tinted toward the ground it falls on stays a shadow.
class BudgyShadows {
  BudgyShadows._();

  static const _warmInk = Color(0xFF0A1711);

  static Color _ink(bool isDark) => isDark ? Colors.black : _warmInk;

  /// Default card elevation. The one you want 90% of the time.
  static List<BoxShadow> soft(BuildContext context) {
    final dark = context.isDark;
    return [
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.44 : 0.055),
        blurRadius: dark ? 26 : 20,
        offset: Offset(0, dark ? 8 : 6),
        spreadRadius: dark ? -6 : 0,
      ),
      // A second, tighter contact shadow. On a light page it is what keeps a
      // large card from looking like it is hovering an inch above the paper;
      // in dark mode it is most of what reads as an edge at all.
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.30 : 0.035),
        blurRadius: dark ? 7 : 5,
        offset: const Offset(0, 2),
        spreadRadius: -2,
      ),
    ];
  }

  /// Hero / floating nav / anything that should read as genuinely off the
  /// page.
  static List<BoxShadow> lifted(BuildContext context) {
    final dark = context.isDark;
    return [
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.58 : 0.10),
        blurRadius: dark ? 40 : 32,
        offset: Offset(0, dark ? 16 : 12),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.36 : 0.05),
        blurRadius: dark ? 12 : 8,
        offset: const Offset(0, 3),
        spreadRadius: -3,
      ),
    ];
  }

  /// Sub-elevation — the active white pill inside a segmented track, a
  /// pressed tile, a small chrome button.
  static List<BoxShadow> pressed(BuildContext context) {
    final dark = context.isDark;
    return [
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.34 : 0.045),
        blurRadius: dark ? 14 : 10,
        offset: const Offset(0, 3),
        spreadRadius: -2,
      ),
    ];
  }

  /// A shadow **dyed with the control's own colour**, so a saturated button
  /// feels grounded rather than pasted on.
  ///
  /// ⚠️ The dense core must stay *under* the element. A glow at blur 20 /
  /// offset 10 with no spread puts its centre entirely below the control, and
  /// on a 48pt pill that renders as a hard second pill sitting behind the real
  /// one. The negative spread pulls the core back under; the alpha rises to
  /// keep the same presence. (This is the exact failure RezQ patched in four
  /// separate call sites before centralising it — inherited here already
  /// fixed.)
  static List<BoxShadow> glow(
    BuildContext context,
    Color tint, {
    double strength = 1,
  }) {
    final dark = context.isDark;
    return [
      BoxShadow(
        color: tint.withValues(alpha: (dark ? 0.34 : 0.28) * strength),
        blurRadius: dark ? 26 : 22,
        offset: const Offset(0, 6),
        spreadRadius: -6,
      ),
      // Grounds the glow against the page. Without it a bright pill in dark
      // mode is a halo with nothing holding it down.
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.34 : 0.05),
        blurRadius: dark ? 14 : 9,
        offset: const Offset(0, 4),
        spreadRadius: -4,
      ),
    ];
  }

  /// The money hero: a wide dyed ambient under a tight contact shadow. Two
  /// levels because the hero is the largest card on the screen, and a single
  /// blur at that size either disappears or smears.
  static List<BoxShadow> hero(BuildContext context, Color tint) {
    final dark = context.isDark;
    return [
      BoxShadow(
        color: tint.withValues(alpha: dark ? 0.30 : 0.22),
        blurRadius: 40,
        offset: const Offset(0, 18),
        spreadRadius: -12,
      ),
      BoxShadow(
        color: _ink(dark).withValues(alpha: dark ? 0.52 : 0.09),
        blurRadius: dark ? 20 : 14,
        offset: const Offset(0, 5),
        spreadRadius: -5,
      ),
    ];
  }
}
