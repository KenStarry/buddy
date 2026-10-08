import 'package:flutter/material.dart';

import 'budgy_color_schemes.dart';
import 'extensions/budgy_colors.dart';

/// Budgy's `ThemeData` assembly and type ramp.
///
/// ## Two families, on purpose
///
/// **Sora** carries display, headlines and every number. It is geometric with
/// wide apertures and — the reason it was chosen — a flagged `1`, so a
/// five-digit balance reads as money rather than as a serial number.
///
/// **Manrope** carries body, labels and UI chrome. Tall x-height, tight
/// spacing, still legible at 11pt in an eyebrow.
///
/// The spec's house rule is one family per app, and this deliberately breaks
/// it: Budgy's entire premise is *large numbers you want to look at*, and a
/// display face doing that job while a text face does the reading is the
/// single biggest lever on whether the app feels expensive. The split is
/// strictly by role and enforced by this file — no call site picks a family.
class AppTheme {
  AppTheme._();

  static const _display = 'Sora';
  static const _text = 'Manrope';

  /// Tabular figures for anything numeric.
  ///
  /// ⚠️ Not cosmetic. Budgy animates balances (`MoneyText` rolls digits), and
  /// with proportional figures every tick re-measures — a `1` is narrower
  /// than an `8`, so the number visibly shudders and anything right-aligned
  /// beside it twitches with it. Tabular locks every digit to one advance
  /// width, so a rolling total stays nailed in place.
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Builds one style on a **variable** font.
  ///
  /// ⚠️ Both families ship as single variable files with a `wght` axis, so
  /// `fontVariations` is set alongside `fontWeight`. Without the explicit axis
  /// value, a platform that cannot synthesise the weight renders the file's
  /// default instance instead — every heading silently collapsing to regular,
  /// on some devices and not others. `fontWeight` is still set so Flutter's
  /// own metrics, fallback chain and `FontWeight.lerp` keep working.
  static TextStyle _style({
    required String family,
    required double size,
    required double weight,
    double height = 1.4,
    double letterSpacing = 0,
    bool numeric = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight)],
    fontFeatures: numeric ? _tabular : null,
  );

  /// The ramp.
  ///
  /// ⚠️ Display weights are **600, not 800**. Heavy numerals were right on a
  /// cream page, where a figure had to fight a white card for attention. On
  /// near-black a white numeral already has ~18:1 contrast and nothing to
  /// compete with, so the same weight reads as shouting — and a 48pt w800
  /// figure fills so much of its own counters that it stops looking like
  /// money and starts looking like a logo. The lighter cut is what makes a
  /// large balance read as expensive rather than loud.
  ///
  /// ```
  /// displayLarge   Sora    44 w600  -1.6   the money hero
  /// displayMedium  Sora    34 w600  -1.0   section totals
  /// displaySmall   Sora    28 w600  -0.6   page titles
  /// headlineLarge  Sora    24 w600  -0.4   card headline numbers
  /// headlineMedium Sora    20 w600  -0.3
  /// headlineSmall  Sora    18 w600
  /// titleLarge     Manrope 18 w700         sheet titles
  /// titleMedium    Manrope 15 w700         row titles
  /// titleSmall     Manrope 13 w700
  /// bodyLarge      Manrope 16 w500
  /// bodyMedium     Manrope 14 w500
  /// bodySmall      Manrope 12 w500         captions
  /// labelLarge     Manrope 14 w700  +0.2   buttons
  /// labelMedium    Manrope 12 w700  +0.3   chips
  /// labelSmall     Manrope 11 w800  +1.3   EYEBROWS (caps)
  /// ```
  static TextTheme _textTheme() => TextTheme(
    displayLarge: _style(
      family: _display,
      size: 44,
      weight: 600,
      height: 1.02,
      letterSpacing: -1.6,
      numeric: true,
    ),
    displayMedium: _style(
      family: _display,
      size: 34,
      weight: 600,
      height: 1.08,
      letterSpacing: -1.0,
      numeric: true,
    ),
    displaySmall: _style(
      family: _display,
      size: 28,
      weight: 600,
      height: 1.15,
      letterSpacing: -0.6,
      numeric: true,
    ),
    headlineLarge: _style(
      family: _display,
      size: 24,
      weight: 600,
      height: 1.2,
      letterSpacing: -0.4,
      numeric: true,
    ),
    headlineMedium: _style(
      family: _display,
      size: 20,
      weight: 600,
      height: 1.25,
      letterSpacing: -0.3,
      numeric: true,
    ),
    headlineSmall: _style(
      family: _display,
      size: 18,
      weight: 600,
      height: 1.3,
      numeric: true,
    ),
    titleLarge: _style(family: _text, size: 18, weight: 700, height: 1.3),
    titleMedium: _style(family: _text, size: 15, weight: 700, height: 1.35),
    titleSmall: _style(family: _text, size: 13, weight: 700, height: 1.4),
    bodyLarge: _style(family: _text, size: 16, weight: 500, height: 1.5),
    bodyMedium: _style(family: _text, size: 14, weight: 500, height: 1.5),
    bodySmall: _style(family: _text, size: 12, weight: 500, height: 1.45),
    labelLarge: _style(
      family: _text,
      size: 14,
      weight: 700,
      height: 1.2,
      letterSpacing: 0.2,
    ),
    labelMedium: _style(
      family: _text,
      size: 12,
      weight: 700,
      height: 1.2,
      letterSpacing: 0.3,
    ),
    labelSmall: _style(
      family: _text,
      size: 11,
      weight: 800,
      height: 1.2,
      letterSpacing: 1.3,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required BudgyColors c,
  }) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: isLight ? Colors.white : c.primaryInk,
      secondary: c.primary,
      onSecondary: c.primaryInk,
      surface: c.surface100,
      onSurface: c.text100,
      surfaceContainerLowest: c.surface100,
      surfaceContainerLow: c.surface200,
      surfaceContainer: c.surface300,
      surfaceContainerHigh: c.surface300,
      surfaceContainerHighest: c.surface400,
      outline: c.divider,
      outlineVariant: c.divider,
      error: c.errorMain,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surface100,
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: _textTheme().apply(
        bodyColor: c.text100,
        displayColor: c.text100,
      ),

      // Budgy draws its own chrome (`BudgyMasthead`), so the stock app bar is
      // configured only to be invisible when something does slip through.
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface100,
        foregroundColor: c.text100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 70,
        iconTheme: IconThemeData(color: c.text100),
        titleTextStyle: _style(
          family: _display,
          size: 20,
          weight: 700,
          letterSpacing: -0.3,
        ).copyWith(color: c.text100),
      ),

      cardTheme: CardThemeData(
        color: c.surface200,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: IconThemeData(color: c.text200, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface300,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: _textTheme().bodyMedium?.copyWith(color: c.text300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.errorMain, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.errorMain, width: 2),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface100,
        modalBackgroundColor: c.surface100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface200,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.primary,
        contentTextStyle: _style(
          family: _text,
          size: 14,
          weight: 600,
        ).copyWith(color: c.primaryInk),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.text100,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: _style(
          family: _text,
          size: 12,
          weight: 600,
        ).copyWith(color: c.surface200),
      ),

      splashFactory: InkSparkle.splashFactory,
      // Material's stock page transition is a horizontal push; Budgy's routes
      // declare their own motion (see `app_router.dart`), so the default is
      // left alone rather than globally overridden.
    );
  }

  static ThemeData light([BudgyColorScheme? scheme]) => _build(
    brightness: Brightness.light,
    c: BudgyColors.from(
      scheme: scheme ?? BudgyColorSchemes.defaultScheme,
      brightness: Brightness.light,
    ),
  );

  static ThemeData dark([BudgyColorScheme? scheme]) => _build(
    brightness: Brightness.dark,
    c: BudgyColors.from(
      scheme: scheme ?? BudgyColorSchemes.defaultScheme,
      brightness: Brightness.dark,
    ),
  );
}
