import 'package:intl/intl.dart';

import '../../domain/currency.dart';

/// How a number should be shown. Grouped is the ledger default; compact is for
/// axes and dense chips where there is no room for five digits.
enum MoneyStyle { grouped, compact }

/// Budgy's money formatter.
///
/// Every amount in the app comes through here, so the rules live in one place:
/// the symbol leads, groups are separated, the decimal part is dropped when
/// it is zero *and* we are not in a context that needs alignment, and the
/// sign is a real minus (`−`, U+2212) rather than a hyphen.
class MoneyFormat {
  MoneyFormat._();

  /// U+2212. A hyphen-minus is narrower than a digit and sits too high; next
  /// to 44pt numerals it reads as a stray dash rather than a sign.
  static const minus = '−';

  static final _cache = <String, NumberFormat>{};

  static NumberFormat _grouped(int decimals) => _cache.putIfAbsent(
    'g$decimals',
    () => NumberFormat.decimalPatternDigits(
      decimalDigits: decimals,
    ),
  );

  /// Formats minor units in [currency].
  ///
  /// [showDecimals] `null` means *decide*: show them only when the amount is
  /// not a whole major unit. A column of balances that flickers between
  /// `48,320` and `48,320.50` looks broken, so pass `true` explicitly when
  /// the number sits in a list that must align.
  static String amount(
    int minor,
    Currency currency, {
    bool? showDecimals,
    bool withSymbol = true,
    bool signed = false,
    MoneyStyle style = MoneyStyle.grouped,
  }) {
    final isNegative = minor < 0;
    final abs = minor.abs();
    final major = currency.toMajor(abs);

    final String body;
    if (style == MoneyStyle.compact) {
      body = _compact(major, currency);
    } else {
      final decimals = currency.decimalDigits == 0
          ? 0
          : (showDecimals ?? (abs % currency.minorPerMajor != 0))
                ? currency.decimalDigits
                : 0;
      body = _grouped(decimals).format(major);
    }

    final sign = isNegative
        ? minus
        : signed
        ? '+'
        : '';
    return withSymbol ? '$sign${currency.symbol} $body' : '$sign$body';
  }

  /// `1.2k`, `48.3k`, `1.4M`. Used on chart axes and in tight chips.
  ///
  /// ⚠️ The suffix is chosen **after** rounding, not before. Picking it first
  /// means 999,500 formats as `999.5k` and 999,990 as `1000.0k` — a tick
  /// wider than the one above it, and a scale that silently stops being
  /// monotonic in label width. Rounding first and promoting on overflow keeps
  /// every label inside its own band.
  static String _compact(double major, Currency currency) {
    final abs = major.abs();

    String? scaled(double divisor, String suffix, String? nextSuffix) {
      if (abs < divisor) return null;
      var value = major / divisor;
      // Rounds to one decimal, then checks whether that rounding pushed it
      // into the next band.
      final rounded = (value * 10).roundToDouble() / 10;
      if (rounded.abs() >= 1000 && nextSuffix != null) {
        value = rounded / 1000;
        return '${_trim(value)}$nextSuffix';
      }
      return '${_trim(rounded)}$suffix';
    }

    return scaled(1e9, 'B', null) ??
        scaled(1e6, 'M', 'B') ??
        scaled(1e3, 'k', 'M') ??
        (currency.decimalDigits == 0
            ? major.toStringAsFixed(0)
            : _grouped(
                abs % 1 == 0 ? 0 : currency.decimalDigits,
              ).format(major));
  }

  /// One decimal, dropped when it carries nothing — `48k` beats `48.0k` on a
  /// crowded axis.
  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// Compact, for axes. Separate entry point so a caller can't accidentally
  /// ask for a symbol on a tick label.
  static String compact(int minor, Currency currency) =>
      amount(minor, currency, style: MoneyStyle.compact, withSymbol: false);

  /// Splits a formatted amount into the part rendered large and the part
  /// rendered small, so the money hero can set `KSh 48,320` with the decimals
  /// and symbol stepped down without the call site re-doing the formatting.
  ///
  /// Returns `(symbol, whole, fraction)` where `fraction` includes its
  /// separator and is empty when there isn't one.
  static ({String symbol, String whole, String fraction}) split(
    int minor,
    Currency currency, {
    bool? showDecimals,
  }) {
    // ⚠️ The MAGNITUDE. `amount` applies the sign itself, and every caller of
    // `split` renders its own sign in front of the parts — so passing the
    // signed value here produced "−KSh −24,000" on every outgoing row.
    final formatted = amount(
      minor.abs(),
      currency,
      showDecimals: showDecimals,
      withSymbol: false,
    );
    final sep = _decimalSeparator;
    final idx = formatted.lastIndexOf(sep);
    if (idx < 0) {
      return (symbol: currency.symbol, whole: formatted, fraction: '');
    }
    return (
      symbol: currency.symbol,
      whole: formatted.substring(0, idx),
      fraction: formatted.substring(idx),
    );
  }

  static String get _decimalSeparator =>
      NumberFormat.decimalPattern().symbols.DECIMAL_SEP;

  /// Parses user input into minor units.
  ///
  /// Accepts grouping separators, a leading symbol, and either separator as
  /// the decimal mark. Returns `null` on anything it cannot read, so the
  /// caller shows a validation message rather than silently banking a zero.
  static int? parse(String input, Currency currency) {
    var text = input.trim();
    if (text.isEmpty) return null;

    final negative = text.startsWith(minus) || text.startsWith('-');
    // Strip everything that isn't a digit or a separator — symbols, spaces,
    // non-breaking spaces, and the sign we just recorded.
    text = text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (text.isEmpty) return null;

    // Whichever separator appears LAST is the decimal mark. `1.234,56` and
    // `1,234.56` are both real inputs and differ only in that ordering.
    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');
    final decimalAt = lastDot > lastComma ? lastDot : lastComma;

    String normalised;
    if (decimalAt < 0) {
      normalised = text.replaceAll(RegExp(r'[.,]'), '');
    } else {
      final whole = text.substring(0, decimalAt).replaceAll(RegExp(r'[.,]'), '');
      final frac = text.substring(decimalAt + 1).replaceAll(RegExp(r'[.,]'), '');
      normalised = frac.isEmpty ? whole : '$whole.$frac';
    }

    final value = double.tryParse(normalised);
    if (value == null) return null;
    final minor = currency.toMinor(value);
    return negative ? -minor : minor;
  }

  /// Converts minor units between currencies through the base currency.
  ///
  /// ⚠️ Converts in the **major** domain and re-rounds into the target's minor
  /// units, because the two currencies may not share a decimal count: moving
  /// 1,000 JPY (0 decimals, so 1000 minor) into USD by scaling the minor
  /// integer directly would be off by 100×.
  static int convert(int minor, Currency from, Currency to) {
    if (from.code == to.code) return minor;
    final inBase = from.toMajor(minor) * from.rateToBase;
    return to.toMinor(inBase / to.rateToBase);
  }
}
