import 'package:flutter/material.dart';

import '../budgy_color_schemes.dart';
import '../budgy_palette.dart';

/// Budgy's **one** semantic colour vocabulary.
///
/// Widgets read these through `context.budgyColors` and never touch
/// [BudgyPalette] or `Colors.*` directly. If a widget wants a colour this
/// class does not name, the answer is almost always that it wants an existing
/// token it hasn't found yet — and occasionally that a token is missing here,
/// which is a change to this file, not a hex literal at the call site.
@immutable
class BudgyColors extends ThemeExtension<BudgyColors> {
  // ───────────────────── Brand ─────────────────────────────────────────────
  /// The primary **fill** — white on dark, near-black on light.
  ///
  /// ⚠️ Achromatic on purpose, and it does not change with the chosen scheme.
  /// On a 4%-luminance page a white pill is already the loudest object
  /// available, so a tinted primary action can only be quieter than the plain
  /// one. Reach for [accent] when you want to colour *information*; reach for
  /// this when you want someone to press something.
  final Color primary;

  /// The foreground that pairs with [primary]. Never assume white — it is
  /// near-black on dark, where the fill itself is the white.
  final Color primaryInk;

  /// The data colour: progress fills, focus rings, selection, links, the
  /// chart's leading slot. The one token a scheme actually repaints.
  final Color accent;

  /// The *pop* — gradient end-stops and on-dark accents only. Too light to be
  /// ink on a pale card; using it as text in light mode is a bug.
  final Color accentPop;

  /// Mid tone. Gradient stops, inactive tracks, the `accent` card tone.
  final Color accentMid;

  /// Accent wash. Icon containers, callouts, soft pills.
  final Color accentSoft;

  /// The balance panel's fill — deep in **both** modes.
  ///
  /// ⚠️ A separate token from [surface200], because it does not follow the
  /// page. The composition this fill carries (white numerals, card slivers
  /// tucked behind it, white action pills on its own ground) only reads on a
  /// deep surface, and rebuilding it light-on-light would be a second design
  /// to maintain for the minority mode. In light mode it is a near-black
  /// panel on a pale page — which is how a card looks lying on a desk.
  final Color heroFill;

  /// The foreground that pairs with [heroFill]. White, in both modes.
  final Color heroInk;

  // ───────────────────── Ink ───────────────────────────────────────────────
  /// Body copy and the big numbers.
  final Color text100;

  /// Secondary copy, row subtitles, de-emphasised labels.
  final Color text200;

  /// Captions, eyebrows, axis ticks, timestamps.
  final Color text300;

  // ───────────────────── Surfaces ──────────────────────────────────────────
  //
  // An **elevation ladder**, not a set of roles. Each step is one level
  // further off the page, and a widget picks its step by asking "what am I
  // resting on?" rather than "am I an input or a chip?".
  //
  //   surface100  the page
  //   surface200  a card resting on the page
  //   surface300  something resting on a card — a nested panel, an input, a
  //               segmented track, an inert chip
  //   surface400  the top of the stack — a chip on a band, a pressed tile
  //
  // ⚠️ On near-black there is no *down*. A recessed input cannot be painted
  // darker than a page that is already at 2% luminance, so both raised and
  // recessed things step **up** the same ladder. What separates them is the
  // edge: a raised surface catches a specular highlight along its top (see
  // `GlassCard`, `ScoopButton`), a recessed one does not. Reaching for a
  // darker fill to say "inset" is the one move this ramp cannot make.

  /// The page.
  final Color surface100;

  /// A card resting on the page — a different fill from [surface100], which is
  /// what lets a card read as a card before any shadow does. (And it has to:
  /// shadows do almost nothing on this ground.)
  final Color surface200;

  /// Something resting on a card: a nested panel, an input fill, a segmented
  /// track, an inert chip.
  final Color surface300;

  /// The top of the stack — a chip on a band, a pressed tile, the near card in
  /// a stack. The step that keeps a twice-nested surface from vanishing into
  /// its parent on a dark page.
  final Color surface400;

  /// Hairline divider.
  ///
  /// For separating rows *inside* one surface — a settings group, a list of
  /// sub-limits — where whitespace alone would let two rows merge. It is
  /// **never** an outline: Budgy draws no borders around anything, in either
  /// mode. Surfaces separate by fill (see the note above).
  final Color divider;

  // ───────────────────── Money semantics ───────────────────────────────────
  /// Money arriving. Green, and only ever as a mark — never a surface.
  final Color inflow;

  /// Money leaving. Warm amber, and **only for charts and direction
  /// glyphs** — expense row amounts wear [text100] with a leading `−`. See
  /// the note in [BudgyPalette] for why expenses are not red.
  final Color outflow;

  /// Between your own accounts. Deliberately cool and quiet: net zero.
  final Color transfer;

  // ───────────────────── Status ────────────────────────────────────────────
  final Color successMain, successSurface, successBorder;
  final Color warningMain, warningSurface, warningBorder;
  final Color errorMain, errorSurface, errorBorder;
  final Color infoMain, infoSurface, infoBorder;

  // ───────────────────── Chart scales ──────────────────────────────────────
  /// The validated categorical ramp, already stepped for this brightness.
  /// Index it with [categoryAt]; never cycle it past its length.
  final List<Color> categories;

  /// Single-hue blue scale, light → dark, for continuous magnitude (the
  /// spending heatmap). Sample it with [sequentialAt].
  final List<Color> sequential;

  const BudgyColors({
    required this.primary,
    required this.primaryInk,
    required this.accent,
    required this.accentPop,
    required this.accentMid,
    required this.accentSoft,
    required this.heroFill,
    required this.heroInk,
    required this.text100,
    required this.text200,
    required this.text300,
    required this.surface100,
    required this.surface200,
    required this.surface300,
    required this.surface400,
    required this.divider,
    required this.inflow,
    required this.outflow,
    required this.transfer,
    required this.successMain,
    required this.successSurface,
    required this.successBorder,
    required this.warningMain,
    required this.warningSurface,
    required this.warningBorder,
    required this.errorMain,
    required this.errorSurface,
    required this.errorBorder,
    required this.infoMain,
    required this.infoSurface,
    required this.infoBorder,
    required this.categories,
    required this.sequential,
  });

  /// Stable colour for a category slot.
  ///
  /// ⚠️ Clamps instead of wrapping with `%`. Wrapping is how a 9th category
  /// silently becomes the same colour as the 1st — two different categories
  /// identical in the pie, the legend, and every glyph. Budgy's UI folds the
  /// tail into "Other" before it gets here; the clamp is the backstop so the
  /// failure is "two tail categories share the last hue", not "your rent is
  /// the same colour as your coffee".
  Color categoryAt(int index) =>
      categories[index.clamp(0, categories.length - 1)];

  /// A colour that will read as an alarm **on the hero's own fill**.
  ///
  /// ⚠️ Not simply [outflow]. Amber on a blue-black panel is unmistakable;
  /// the identical token on a panel that had drifted warm would read as a
  /// slightly different shade of the card rather than as a warning. Alarm is
  /// the one signal that must survive every skin, so when the alert hue sits
  /// too close to the panel's own, this falls back to [heroInk] — guaranteed
  /// legible against the fill by definition — and leaves the eyebrow ("OVER
  /// BY") and the meter to carry the meaning.
  Color get heroAlert {
    final alertHue = HSLColor.fromColor(outflow).hue;
    final fillHue = HSLColor.fromColor(heroFill).hue;
    var delta = (alertHue - fillHue).abs();
    if (delta > 180) delta = 360 - delta;
    return delta < 45 ? heroInk : outflow;
  }

  /// Samples the sequential ramp at `t` in 0..1 (0 = near-zero magnitude).
  Color sequentialAt(double t) {
    if (sequential.isEmpty) return accent;
    final clamped = t.isNaN ? 0.0 : t.clamp(0.0, 1.0);
    final pos = clamped * (sequential.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sequential[lo];
    return Color.lerp(sequential[lo], sequential[hi], pos - lo)!;
  }

  /// Builds the semantic palette for a scheme + brightness.
  ///
  /// Only the accent family comes from the scheme (see `BudgyColorScheme`).
  /// The structural canvas, the ink and the money semantics are fixed: a skin
  /// changes where the *information* is coloured, never the furniture.
  factory BudgyColors.from({
    required BudgyColorScheme scheme,
    required Brightness brightness,
  }) {
    final isNight = brightness == Brightness.dark;

    return BudgyColors(
      // ⚠️ Achromatic, in both modes. On a 4%-luminance page a white pill is
      // already the loudest object available; tinting the primary action can
      // only make it quieter. The accent below is a data colour.
      primary: isNight ? scheme.darkPrimary : scheme.lightPrimary,
      primaryInk: isNight ? scheme.darkPrimaryInk : scheme.lightPrimaryInk,

      accent: isNight ? scheme.darkAccent : scheme.lightAccent,
      accentPop: isNight ? scheme.darkAccentPop : scheme.lightAccentPop,
      accentMid: isNight ? scheme.darkAccentMid : scheme.lightAccentMid,
      accentSoft: isNight ? scheme.darkAccentSoft : scheme.lightAccentSoft,

      // ⚠️ The balance panel is deep in **both** modes, which is why it is a
      // separate token from every surface below. The composition it carries —
      // white numerals, card slivers tucked behind it, white action pills on
      // its own ground — only works on a deep fill, and rebuilding it a
      // second time in light-on-light would be a second design to maintain
      // for the minority mode. Light mode gets the same object on a pale
      // page, which is how a physical card looks on a desk.
      heroFill: isNight ? BudgyPalette.panel : BudgyPalette.dayInk,
      heroInk: BudgyPalette.ink,

      text100: isNight ? BudgyPalette.ink : BudgyPalette.dayInk,
      text200: isNight ? BudgyPalette.ink2 : BudgyPalette.dayInk2,
      text300: isNight ? BudgyPalette.ink3 : BudgyPalette.dayInk3,

      surface100: isNight ? BudgyPalette.voidBase : BudgyPalette.dayPage,
      surface200: isNight ? BudgyPalette.panel : BudgyPalette.dayCard,
      surface300: isNight ? BudgyPalette.panelHigh : BudgyPalette.dayBand,
      surface400: isNight ? BudgyPalette.panelTop : BudgyPalette.dayTop,
      divider: isNight ? BudgyPalette.line : BudgyPalette.dayLine,

      inflow: isNight ? BudgyPalette.inflow : BudgyPalette.inflowDay,
      outflow: isNight ? BudgyPalette.outflow : BudgyPalette.outflowDay,
      transfer: isNight ? BudgyPalette.transfer : BudgyPalette.transferDay,

      successMain: isNight ? BudgyPalette.success : BudgyPalette.successDay,
      successSurface: isNight
          ? const Color(0xFF0C2119)
          : const Color(0xFFE6FBF2),
      successBorder: isNight
          ? const Color(0xFF17493A)
          : const Color(0xFFBBEEDA),

      warningMain: isNight ? BudgyPalette.warning : BudgyPalette.warningDay,
      warningSurface: isNight
          ? const Color(0xFF241B08)
          : const Color(0xFFFEF6E3),
      warningBorder: isNight
          ? const Color(0xFF53400F)
          : const Color(0xFFF5E2AF),

      errorMain: isNight ? BudgyPalette.danger : BudgyPalette.dangerDay,
      errorSurface: isNight ? const Color(0xFF2A0F13) : const Color(0xFFFDECEC),
      errorBorder: isNight ? const Color(0xFF5E2129) : const Color(0xFFF7C9C9),

      infoMain: isNight ? BudgyPalette.info : BudgyPalette.infoDay,
      infoSurface: isNight ? const Color(0xFF101B2E) : const Color(0xFFEAF1FE),
      infoBorder: isNight ? const Color(0xFF1F3A5E) : const Color(0xFFC6DCF7),

      categories: isNight
          ? BudgyPalette.categoryNight
          : BudgyPalette.categoryDay,
      sequential: BudgyPalette.sequential,
    );
  }

  factory BudgyColors.light() => BudgyColors.from(
    scheme: BudgyColorSchemes.defaultScheme,
    brightness: Brightness.light,
  );

  factory BudgyColors.dark() => BudgyColors.from(
    scheme: BudgyColorSchemes.defaultScheme,
    brightness: Brightness.dark,
  );

  @override
  ThemeExtension<BudgyColors> lerp(
    ThemeExtension<BudgyColors>? other,
    double t,
  ) {
    if (other is! BudgyColors) return this;
    return BudgyColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPop: Color.lerp(accentPop, other.accentPop, t)!,
      accentMid: Color.lerp(accentMid, other.accentMid, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      heroFill: Color.lerp(heroFill, other.heroFill, t)!,
      heroInk: Color.lerp(heroInk, other.heroInk, t)!,
      text100: Color.lerp(text100, other.text100, t)!,
      text200: Color.lerp(text200, other.text200, t)!,
      text300: Color.lerp(text300, other.text300, t)!,
      surface100: Color.lerp(surface100, other.surface100, t)!,
      surface200: Color.lerp(surface200, other.surface200, t)!,
      surface300: Color.lerp(surface300, other.surface300, t)!,
      surface400: Color.lerp(surface400, other.surface400, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inflow: Color.lerp(inflow, other.inflow, t)!,
      outflow: Color.lerp(outflow, other.outflow, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      successMain: Color.lerp(successMain, other.successMain, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningMain: Color.lerp(warningMain, other.warningMain, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      errorMain: Color.lerp(errorMain, other.errorMain, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      infoMain: Color.lerp(infoMain, other.infoMain, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      // ⚠️ Chart scales **snap** at the halfway point rather than lerping.
      // A categorical ramp mid-interpolation is not a categorical ramp: every
      // validated ΔE between adjacent slots collapses as the hues converge,
      // so a theme crossfade would briefly render a palette that fails every
      // CVD gate this file documents. Snapping means one frame of the old
      // ramp and then the new one — correct at both ends, which is what a
      // chart needs.
      categories: t < 0.5 ? categories : other.categories,
      sequential: t < 0.5 ? sequential : other.sequential,
    );
  }

  @override
  BudgyColors copyWith({
    Color? primary,
    Color? primaryInk,
    Color? accent,
    Color? accentPop,
    Color? accentMid,
    Color? accentSoft,
    Color? heroFill,
    Color? heroInk,
    Color? text100,
    Color? text200,
    Color? text300,
    Color? surface100,
    Color? surface200,
    Color? surface300,
    Color? surface400,
    Color? divider,
    Color? inflow,
    Color? outflow,
    Color? transfer,
    Color? successMain,
    Color? successSurface,
    Color? successBorder,
    Color? warningMain,
    Color? warningSurface,
    Color? warningBorder,
    Color? errorMain,
    Color? errorSurface,
    Color? errorBorder,
    Color? infoMain,
    Color? infoSurface,
    Color? infoBorder,
    List<Color>? categories,
    List<Color>? sequential,
  }) {
    return BudgyColors(
      primary: primary ?? this.primary,
      primaryInk: primaryInk ?? this.primaryInk,
      accent: accent ?? this.accent,
      accentPop: accentPop ?? this.accentPop,
      accentMid: accentMid ?? this.accentMid,
      accentSoft: accentSoft ?? this.accentSoft,
      heroFill: heroFill ?? this.heroFill,
      heroInk: heroInk ?? this.heroInk,
      text100: text100 ?? this.text100,
      text200: text200 ?? this.text200,
      text300: text300 ?? this.text300,
      surface100: surface100 ?? this.surface100,
      surface200: surface200 ?? this.surface200,
      surface300: surface300 ?? this.surface300,
      surface400: surface400 ?? this.surface400,
      divider: divider ?? this.divider,
      inflow: inflow ?? this.inflow,
      outflow: outflow ?? this.outflow,
      transfer: transfer ?? this.transfer,
      successMain: successMain ?? this.successMain,
      successSurface: successSurface ?? this.successSurface,
      successBorder: successBorder ?? this.successBorder,
      warningMain: warningMain ?? this.warningMain,
      warningSurface: warningSurface ?? this.warningSurface,
      warningBorder: warningBorder ?? this.warningBorder,
      errorMain: errorMain ?? this.errorMain,
      errorSurface: errorSurface ?? this.errorSurface,
      errorBorder: errorBorder ?? this.errorBorder,
      infoMain: infoMain ?? this.infoMain,
      infoSurface: infoSurface ?? this.infoSurface,
      infoBorder: infoBorder ?? this.infoBorder,
      categories: categories ?? this.categories,
      sequential: sequential ?? this.sequential,
    );
  }
}
