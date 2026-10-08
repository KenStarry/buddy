import 'dart:ui' as ui;

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/presentation/state/controllers/settings_controller.dart';
import '../../domain/currency.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/functions/money_format.dart';

/// How prominent an amount is.
enum MoneySize {
  /// The amount being typed on the entry screen. The largest figure in the
  /// app, because it is the only thing on that screen anyone came to do.
  entry,

  /// The home headline. 48pt — a hero figure, per the data-viz rule that a
  /// dashboard's lead number is a *figure*, not a one-bar chart.
  hero,

  /// A card's own headline number.
  display,

  /// A section total.
  title,

  /// A ledger row's amount.
  row,

  /// A caption-scale figure — a sub-limit, a per-day rate.
  small,
}

/// Renders money, consistently, everywhere.
///
/// Three things it does that a `Text(MoneyFormat.amount(...))` does not:
///
/// 1. **Steps the symbol and the decimals down.** `KSh` at 48pt competes with
///    the number it is labelling, and `.00` at 48pt is two characters of
///    nothing taking up a third of the figure. Both render smaller and
///    slightly muted, so the eye lands on the digits that matter.
/// 2. **Honours the privacy screen.** One switch in Settings blurs every
///    amount in the app, and it works because nothing renders money except
///    this widget.
/// 3. **Rolls on change, optionally.** [animate] drives an odometer so a
///    balance ticking down after an entry is legible as a change rather than
///    a repaint.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.minor, {
    super.key,
    required this.currency,
    this.size = MoneySize.row,
    this.color,
    this.signed = false,
    this.showDecimals,
    this.showSymbol = true,
    this.symbolTrailing = false,
    this.roll = false,
    this.compact = false,
    this.weight,
  });

  final int minor;
  final Currency currency;
  final MoneySize size;
  final Color? color;

  /// Prefix positive amounts with `+`. For ledger rows, where the sign is the
  /// information; off for balances, where it is noise.
  final bool signed;

  final bool? showDecimals;
  final bool showSymbol;

  /// Render the currency **after** the figure rather than before it.
  ///
  /// For the one place the figure is the whole composition — the balance
  /// panel — where a leading `KSh` is the first thing read on a line whose
  /// entire job is the number. Trailing, the eye lands on the digits and
  /// picks up the unit on the way out. Everywhere else the symbol leads,
  /// because in a list of amounts a trailing unit ragged-rights the column.
  final bool symbolTrailing;

  /// Roll the digits when the value changes.
  ///
  /// ⚠️ Named `roll`, not `animate`, and that is not a style choice. An
  /// instance member called `animate` **shadows** `flutter_animate`'s
  /// `Widget.animate()` extension on every instance of this widget, so
  /// `MoneyText(...).animate().fadeIn()` stops resolving to the extension and
  /// instead tries to invoke a `bool` — which fails as "the expression
  /// doesn't evaluate to a function", pointing at the constructor, with no
  /// mention of the field that caused it.
  final bool roll;

  /// `48.3k` instead of `48,320`. For axes and tight chips.
  final bool compact;

  final FontWeight? weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(settingsControllerProvider).hideAmounts;
    final c = context.budgyColors;
    final ink = color ?? c.text100;

    final base = switch (size) {
      MoneySize.entry => context.textTheme.displayLarge!.copyWith(
        fontSize: 88,
        height: 1,
        letterSpacing: -3.6,
      ),
      MoneySize.hero => context.textTheme.displayLarge!.copyWith(fontSize: 48),
      MoneySize.display => context.textTheme.displayMedium!,
      MoneySize.title => context.textTheme.headlineMedium!,
      MoneySize.row => context.textTheme.headlineSmall!.copyWith(fontSize: 16),
      MoneySize.small => context.textTheme.titleSmall!.copyWith(
        fontFamily: 'Sora',
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      ),
    };
    final style = base.copyWith(
      color: ink,
      fontWeight: weight,
      fontVariations: weight == null
          ? null
          : [ui.FontVariation('wght', weight!.value.toDouble())],
    );

    // Satellite scale: the symbol and the decimals ride at a fraction of the
    // figure's size and at 70% alpha. The ratio tightens as the figure
    // shrinks — at row scale a 0.6× symbol is simply too small to read.
    final satelliteRatio = switch (size) {
      MoneySize.entry => 0.24,
      MoneySize.hero => 0.42,
      MoneySize.display => 0.46,
      MoneySize.title => 0.6,
      MoneySize.row || MoneySize.small => 0.82,
    };
    final satellite = style.copyWith(
      fontSize: (style.fontSize ?? 16) * satelliteRatio,
      // ⚠️ **Scaled**, not set. `withValues(alpha: 0.7)` replaces the channel,
      // so a caller passing a translucent ink — a placeholder amount at 22%,
      // a muted row — got a currency symbol at 70% against a figure at 22%:
      // the label louder than the number it labels. Multiplying keeps the
      // satellite a step below whatever ink it was handed.
      color: ink.withValues(alpha: ink.a * 0.7),
      letterSpacing: 0,
    );

    final Widget content;
    if (compact) {
      content = Text(
        '$_signPrefix${showSymbol ? '${currency.symbol} ' : ''}'
        '${MoneyFormat.compact(minor.abs(), currency)}',
        style: style,
      );
    } else {
      final parts = MoneyFormat.split(
        minor,
        currency,
        showDecimals: showDecimals,
      );
      final gap = SizedBox(width: (style.fontSize ?? 16) * 0.14);
      content = Row(
        mainAxisSize: MainAxisSize.min,
        // ⚠️ Baseline alignment, not centre. The symbol and the decimals are
        // smaller than the figure; centred, they float in the middle of the
        // digits' height and the whole number looks like three fragments.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (_signPrefix.isNotEmpty) Text(_signPrefix, style: style),
          if (showSymbol && !symbolTrailing) ...[
            Text(parts.symbol, style: satellite),
            gap,
          ],
          if (roll)
            AnimatedDigitWidget(
              value: _wholeValue(parts.whole),
              textStyle: style,
              duration: const Duration(milliseconds: 550),
              enableSeparator: true,
            )
          else
            Text(parts.whole, style: style),
          if (parts.fraction.isNotEmpty)
            Text(parts.fraction, style: satellite),
          if (showSymbol && symbolTrailing) ...[
            gap,
            Text(parts.symbol, style: satellite),
          ],
        ],
      );
    }

    if (!hidden) return content;

    // The blur sits over the real glyphs rather than replacing them with dots
    // so the figure keeps its exact width — turning privacy on must not
    // reflow the page.
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: ExcludeSemantics(child: content),
    );
  }

  String get _signPrefix {
    if (minor < 0) return MoneyFormat.minus;
    return signed && minor > 0 ? '+' : '';
  }

  /// `AnimatedDigitWidget` wants a number, and the formatter hands back a
  /// grouped string. Strip the separators rather than re-deriving from
  /// `minor`, so the rolling figure and the static one can never disagree
  /// about rounding.
  num _wholeValue(String whole) =>
      num.tryParse(whole.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

/// A small inline `↑ / ↓` with a tinted pill, for a delta beside a figure.
class MoneyDelta extends StatelessWidget {
  const MoneyDelta({
    super.key,
    required this.fraction,
    this.inverted = false,
    this.label,
  });

  /// Signed change, e.g. `0.12` for +12%.
  final double fraction;

  /// For spend, **up is bad**. Inverting swaps the colours without touching
  /// the arrow, which still points the way the number moved.
  final bool inverted;

  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.budgyColors;
    final up = fraction >= 0;
    final good = inverted ? !up : up;
    final tint = good ? c.successMain : c.errorMain;
    final pct = (fraction.abs() * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 11, color: tint),
          const SizedBox(width: 3),
          Text(
            label ?? '$pct%',
            style: context.textTheme.labelMedium?.copyWith(color: tint),
          ),
        ],
      ),
    );
  }
}
