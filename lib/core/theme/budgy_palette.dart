import 'dart:ui';

/// **Midnight** — Budgy's raw colour constants.
///
/// ## The premise
///
/// Budgy is a **dark app**. Not "an app with a dark mode": the composition is
/// designed on near-black, and light mode is the accommodation. That is a
/// deliberate reversal of the previous warm-cream identity, and it is doing
/// three things at once.
///
/// A budget screen is mostly large numerals. White numerals on near-black have
/// roughly 18:1 contrast and no competing surface, so the figure is the only
/// bright object in the frame and the eye lands on it without being directed.
/// On cream, a white card and a cream page sit within a few percent of each
/// other and nothing leads.
///
/// Second: **white becomes the accent.** With the page at 4% luminance, a pure
/// white pill is the loudest thing available, so the primary actions need no
/// hue at all. That is why this palette carries almost no chroma — the blue
/// below is for data and focus, never for a button.
///
/// Third, the surfaces step by *luminance only* and all share one hue, so a
/// panel on a page and a card on a panel separate cleanly without a single
/// border (see `BudgyShadows` — shadows do nothing on near-black, and fill is
/// carrying the whole job here).
///
/// Nothing here is semantic. Widgets never import this file; they read
/// [BudgyColors] through `context.budgyColors`. This is the pigment, not the
/// paint-by-numbers.
class BudgyPalette {
  BudgyPalette._();

  // ───────────────────── Surfaces — dark (the designed-for mode) ───────────
  //
  // One hue (~225°) at five luminances. The steps are wider at the bottom
  // than a neutral grey ramp would be, because perceived difference compresses
  // as you approach black: an even numeric step from #000 upward reads as four
  // identical blacks and then a grey.

  /// The page. Blue-black — cool enough to read as glass rather than as soot.
  static const voidBase = Color(0xFF07080C);

  /// The panel. The balance card, the sheet, anything that *holds* something.
  static const panel = Color(0xFF101218);

  /// Raised — input fills, segmented tracks, the card slivers behind a panel,
  /// inert chips.
  static const panelHigh = Color(0xFF181B23);

  /// Raised twice. Pressed states and the top of a stack.
  static const panelTop = Color(0xFF20242E);

  /// Hairline, for separating rows *inside* one surface. Never an outline.
  static const line = Color(0xFF242833);

  // ───────────────────── Ink — dark ────────────────────────────────────────
  /// The numbers, and anything that is the point of its row.
  static const ink = Color(0xFFFFFFFF);

  /// Secondary copy, row subtitles, de-emphasised labels.
  static const ink2 = Color(0xFF959CAA);

  /// Captions, eyebrows, axis ticks, timestamps.
  static const ink3 = Color(0xFF626A79);

  // ───────────────────── Surfaces — light (the accommodation) ──────────────
  //
  // ⚠️ Cool, not cream. The old palette's warm page is gone on purpose: a
  // warm light mode and a blue-black dark mode are two different products,
  // and every component built for one looks borrowed in the other.
  static const dayPage = Color(0xFFF2F3F6);
  static const dayCard = Color(0xFFFFFFFF);
  static const dayBand = Color(0xFFE8EAEF);
  static const dayTop = Color(0xFFDDE0E7);
  static const dayLine = Color(0xFFDCDFE7);

  static const dayInk = Color(0xFF0A0C11);
  static const dayInk2 = Color(0xFF4C5361);
  static const dayInk3 = Color(0xFF7C8494);

  // ───────────────────── Brand ─────────────────────────────────────────────
  //
  // ⚠️ The primary **fill** is achromatic — white on dark, near-black on
  // light. See the class note: on a 4%-luminance page, white is already the
  // loudest thing available, and tinting the main action only makes it
  // quieter. The blue is a *data* colour: progress, focus, selection, the
  // first chart slot's sibling. Painting a CTA with it is a bug.

  /// Cool blue — focus rings, progress fills, selection, links.
  static const blue = Color(0xFF4C8DFF);

  /// Lighter blue — the pop. Gradient end-stops and on-dark accents.
  static const bluePop = Color(0xFF8CB6FF);

  /// Mid blue — inactive tracks, the `accent` card tone on dark.
  static const blueMid = Color(0xFF1E3566);

  /// Blue wash — icon containers, callouts, soft pills.
  static const blueSoft = Color(0xFF131A2A);

  /// The same family, re-stepped for a light page.
  static const blueDay = Color(0xFF2563EB);
  static const bluePopDay = Color(0xFF60A5FA);
  static const blueMidDay = Color(0xFFBFD4FE);
  static const blueSoftDay = Color(0xFFEAF1FE);

  // ───────────────────── Money semantics ───────────────────────────────────
  // ⚠️ Expenses are **not** painted red.
  //
  // In a budget app the overwhelming majority of rows are expenses. Painting
  // them all red makes the ledger read as a list of errors and spends the
  // alarm colour on the normal case — so by the time something is genuinely
  // wrong (over budget, a missed bill) there is no louder colour left to say
  // it with. Outflow rows wear plain ink and a leading `−`; the *direction*
  // is carried by the sign and the glyph, not by a warning.

  /// Money in. Green, and only ever as a mark — never a surface.
  static const inflow = Color(0xFF34D399);
  static const inflowDay = Color(0xFF059669);

  /// Money out. Warm amber — "spend", not "mistake". Charts and direction
  /// arrows only, never row text.
  static const outflow = Color(0xFFFB923C);
  static const outflowDay = Color(0xFFEA580C);

  /// Between your own accounts. Cool and quiet; nothing was earned or lost.
  static const transfer = Color(0xFF818CF8);
  static const transferDay = Color(0xFF4F46E5);

  // ───────────────────── Status ────────────────────────────────────────────
  static const success = Color(0xFF34D399);
  static const successDay = Color(0xFF059669);
  static const warning = Color(0xFFFBBF24);
  static const warningDay = Color(0xFFB45309);
  static const danger = Color(0xFFFF5F6D);
  static const dangerDay = Color(0xFFDC2626);
  static const info = Color(0xFF60A5FA);
  static const infoDay = Color(0xFF2563EB);

  // ───────────────────── Category / chart categorical ramp ─────────────────
  // ⚠️ **This order is a validated artefact, not a mood board.**
  //
  // Checked with the data-viz validator on the adjacent pairlist, both modes
  // clearing the ΔE 8 CVD target and the ΔE 15 normal-vision floor, with slots
  // 1–3 additionally clearing every gate on the *all-pairs* list — the subset
  // safe for forms where any two marks can be compared at a glance. Past three
  // slots, charts either fold the tail into "Other" or carry labels.
  //
  // ⚠️ The hues below are carried over unchanged from the validated run, but
  // the **surfaces under them moved** when this palette replaced the cream
  // one: the dark panel went from #151E19 to [panel] and the light page from
  // #FBF9F4 to [dayPage]. Both are within ~2% luminance of what was tested, so
  // the separation result holds and the contrast result is close — but it has
  // not been re-run, because the `scripts/validate_palette.js` the old note
  // referred to does not exist in this repo. Treat the ramp as inherited, not
  // re-proven, and re-validate before changing a hue.
  //
  // The **relief rule** applies and is honoured by construction regardless: a
  // category never appears as a bare swatch anywhere in Budgy — a
  // `CategoryGlyph` always pairs the colour with an icon, and every chart
  // ships direct labels. Identity is never colour alone.
  static const categoryDay = <Color>[
    Color(0xFF1BAF7A), // 1 emerald
    Color(0xFFEB6834), // 2 tangerine
    Color(0xFF2A78D6), // 3 blue
    Color(0xFFEDA100), // 4 amber
    Color(0xFFE87BA4), // 5 magenta
    Color(0xFF008300), // 6 forest
    Color(0xFF4A3AA7), // 7 violet
    Color(0xFFE34948), // 8 red
  ];

  /// The same eight hues **re-stepped for the dark surface** — not an
  /// automatic lighten of the light column. Each lands in the dark lightness
  /// band and clears 3:1 against [panel].
  static const categoryNight = <Color>[
    Color(0xFF2DD4A0), // 1 emerald
    Color(0xFFFB8B5E), // 2 tangerine
    Color(0xFF5B9CF8), // 3 blue
    Color(0xFFF0B429), // 4 amber
    Color(0xFFF08BB4), // 5 magenta
    Color(0xFF3FAD63), // 6 forest
    Color(0xFF9F8CF5), // 7 violet
    Color(0xFFF77272), // 8 red
  ];

  // ───────────────────── Sequential blue ramp ──────────────────────────────
  /// One hue, light → dark, for **continuous magnitude** (the spending
  /// heatmap). Monotonic in lightness with ≥0.06 ΔL between steps.
  ///
  /// ⚠️ Ordered **light-first**, like its predecessor, because `sequentialAt`
  /// samples 0 → "near zero". On the dark page the UI reads it in reverse —
  /// near-zero days recede toward the page by using the *dark* end — which is
  /// `sequentialAt`'s caller's business, not this list's.
  static const seq050 = Color(0xFFE3EDFF);
  static const seq100 = Color(0xFFC7DBFF);
  static const seq200 = Color(0xFFA8C6FF);
  static const seq300 = Color(0xFF86AFFF);
  static const seq400 = Color(0xFF6698FB);
  static const seq500 = Color(0xFF4C8DFF);
  static const seq600 = Color(0xFF3B6FD6);
  static const seq700 = Color(0xFF2E57AC);
  static const seq800 = Color(0xFF234283);
  static const seq900 = Color(0xFF1A305F);
  static const seq950 = Color(0xFF122142);

  /// Light → dark, in order. Index into it, or lerp across it.
  static const sequential = <Color>[
    seq050, seq100, seq200, seq300, seq400, seq500,
    seq600, seq700, seq800, seq900, seq950,
  ];
}
