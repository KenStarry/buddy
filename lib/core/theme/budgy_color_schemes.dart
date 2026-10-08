import 'package:flutter/material.dart';

import 'budgy_palette.dart';

/// One selectable accent skin.
///
/// ## What a scheme may and may not change
///
/// A scheme supplies the **accent family** and nothing else. The surfaces stay
/// blue-black in every scheme, and the primary action stays achromatic —
/// white on dark, near-black on light — because those two decisions *are* the
/// Midnight identity (see `BudgyPalette`). A scheme that could repaint the
/// page would not be a skin, it would be a different app.
///
/// So `primary` here is the same achromatic pair in all five, and the thing
/// that actually varies is the data colour: progress fills, focus rings,
/// selection, the chart's first slot. That is a smaller surface than the old
/// scheme system painted, and deliberately — a budget app's accent should be
/// where the *information* is, not on the furniture.
///
/// Text and the money semantics (`inflow`/`outflow`/`transfer`) stay out of
/// here on purpose: legibility and "which way did the money go" must not
/// change because somebody liked violet.
@immutable
class BudgyColorScheme {
  const BudgyColorScheme({
    required this.id,
    required this.label,
    required this.blurb,
    required this.lightAccent,
    required this.lightAccentPop,
    required this.lightAccentMid,
    required this.lightAccentSoft,
    required this.darkAccent,
    required this.darkAccentPop,
    required this.darkAccentMid,
    required this.darkAccentSoft,
  });

  /// Stable key — persisted in Hive. Renaming one orphans a user's choice.
  final String id;
  final String label;

  /// One line for the appearance picker. Warm, not spec-sheet.
  final String blurb;

  final Color lightAccent;
  final Color lightAccentPop;
  final Color lightAccentMid;
  final Color lightAccentSoft;

  final Color darkAccent;
  final Color darkAccentPop;
  final Color darkAccentMid;
  final Color darkAccentSoft;

  // ── Invariant across every scheme ────────────────────────────────────────

  /// The primary **fill**: the loudest surface available in each mode.
  Color get lightPrimary => BudgyPalette.dayInk;
  Color get lightPrimaryInk => BudgyPalette.dayCard;
  Color get darkPrimary => BudgyPalette.ink;
  Color get darkPrimaryInk => BudgyPalette.voidBase;
}

/// The shipped skins. [midnight] is Budgy's identity; the rest vary only the
/// accent.
class BudgyColorSchemes {
  BudgyColorSchemes._();

  /// **Midnight** — blue-black with a cool blue read-out. The default, and
  /// the one every screenshot is composed against.
  static const midnight = BudgyColorScheme(
    id: 'midnight',
    label: 'Midnight',
    blurb: 'Blue-black and white. The house look.',
    lightAccent: BudgyPalette.blueDay,
    lightAccentPop: BudgyPalette.bluePopDay,
    lightAccentMid: BudgyPalette.blueMidDay,
    lightAccentSoft: BudgyPalette.blueSoftDay,
    darkAccent: BudgyPalette.blue,
    darkAccentPop: BudgyPalette.bluePop,
    darkAccentMid: BudgyPalette.blueMid,
    darkAccentSoft: BudgyPalette.blueSoft,
  );

  static const aurora = BudgyColorScheme(
    id: 'aurora',
    label: 'Aurora',
    blurb: 'A green read-out on the same black.',
    lightAccent: Color(0xFF059669),
    lightAccentPop: Color(0xFF34D399),
    lightAccentMid: Color(0xFFA7F3D0),
    lightAccentSoft: Color(0xFFE6FBF2),
    darkAccent: Color(0xFF2DD4A0),
    darkAccentPop: Color(0xFF6EE7C0),
    darkAccentMid: Color(0xFF115141),
    darkAccentSoft: Color(0xFF0C2119),
  );

  static const ultraviolet = BudgyColorScheme(
    id: 'ultraviolet',
    label: 'Ultraviolet',
    blurb: 'Violet, for the late-night ledger.',
    lightAccent: Color(0xFF6D28D9),
    lightAccentPop: Color(0xFFA78BFA),
    lightAccentMid: Color(0xFFDDD6FE),
    lightAccentSoft: Color(0xFFF2EEFE),
    darkAccent: Color(0xFF9F8CF5),
    darkAccentPop: Color(0xFFC4B5FD),
    darkAccentMid: Color(0xFF342A66),
    darkAccentSoft: Color(0xFF17132B),
  );

  static const ember = BudgyColorScheme(
    id: 'ember',
    label: 'Ember',
    blurb: 'Warm amber against the cold.',
    lightAccent: Color(0xFFB45309),
    lightAccentPop: Color(0xFFFBBF24),
    lightAccentMid: Color(0xFFFDE68A),
    lightAccentSoft: Color(0xFFFEF6E3),
    darkAccent: Color(0xFFF0B429),
    darkAccentPop: Color(0xFFFCD34D),
    darkAccentMid: Color(0xFF5C430C),
    darkAccentSoft: Color(0xFF241B08),
  );

  static const rose = BudgyColorScheme(
    id: 'rose',
    label: 'Rose',
    blurb: 'A soft rose read-out.',
    lightAccent: Color(0xFFBE185D),
    lightAccentPop: Color(0xFFF472B6),
    lightAccentMid: Color(0xFFFBCFE8),
    lightAccentSoft: Color(0xFFFDF0F6),
    darkAccent: Color(0xFFF08BB4),
    darkAccentPop: Color(0xFFF9A8D4),
    darkAccentMid: Color(0xFF5C2440),
    darkAccentSoft: Color(0xFF26121C),
  );

  static const defaultScheme = midnight;

  static const all = <BudgyColorScheme>[
    midnight,
    aurora,
    ultraviolet,
    ember,
    rose,
  ];

  /// Resolve a persisted id, falling back to the house look. A stored id that
  /// no longer exists must degrade to the default, never throw — a renamed
  /// scheme would otherwise brick the app for anyone who had chosen it.
  static BudgyColorScheme byId(String? id) {
    for (final scheme in all) {
      if (scheme.id == id) return scheme;
    }
    return defaultScheme;
  }
}
