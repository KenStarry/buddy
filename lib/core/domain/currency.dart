import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A currency Budgy can hold money in.
///
/// `rateToBase` is a **static** conversion factor: 1 unit of this currency
/// expressed in the user's base currency. Budgy ships sensible defaults and
/// lets the user edit them in Settings; there is no live rate feed yet, so a
/// converted total is explicitly an estimate and the UI says so wherever it
/// mixes currencies.
@immutable
class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalDigits = 2,
    this.rateToBase = 1,
  });

  /// ISO 4217, uppercase. The stored key.
  final String code;

  /// What Budgy prints. `KSh`, `$`, `€` — short enough to sit beside a
  /// 44pt numeral without stealing from it.
  final String symbol;

  final String name;

  /// How many minor units make a major one, as a digit count.
  ///
  /// ⚠️ Not always 2. JPY and KRW are 0; a zero-decimal currency formatted
  /// with two decimals reads as 100× the real amount to anyone who knows the
  /// currency, and the rounding on write silently loses nothing — so the
  /// *display* bug is the whole bug.
  final int decimalDigits;

  /// 1 unit of this currency, in base-currency units.
  final double rateToBase;

  /// Minor units per major unit — 100 for USD, 1 for JPY.
  int get minorPerMajor {
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }

  /// Major-unit double → minor-unit int, rounded half-away-from-zero.
  ///
  /// ⚠️ `toInt()` truncates, which turns a user typing `19.99` into 1998
  /// minor units once the parse lands on 19.989999999999998 — a cent
  /// evaporating per entry, and a ledger that never quite reconciles.
  int toMinor(double major) => (major * minorPerMajor).round();

  /// Minor-unit int → major-unit double. For display and charts only; never
  /// accumulate in this space.
  double toMajor(int minor) => minor / minorPerMajor;

  Currency copyWith({
    String? code,
    String? symbol,
    String? name,
    int? decimalDigits,
    double? rateToBase,
  }) => Currency(
    code: code ?? this.code,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    decimalDigits: decimalDigits ?? this.decimalDigits,
    rateToBase: rateToBase ?? this.rateToBase,
  );

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    code: map['code']?.toString().toUpperCase() ?? 'USD',
    symbol: map['symbol']?.toString() ?? r'$',
    name: map['name']?.toString() ?? 'Currency',
    decimalDigits: (map['decimal_digits'] as num?)?.toInt() ?? 2,
    rateToBase: (map['rate_to_base'] as num?)?.toDouble() ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'code': code,
    'symbol': symbol,
    'name': name,
    'decimal_digits': decimalDigits,
    'rate_to_base': rateToBase,
  };

  @override
  List<Object?> get props => [code, symbol, name, decimalDigits, rateToBase];
}

/// The currencies Budgy knows out of the box. Rates are rough, static, and
/// user-editable; they exist so a fresh install can hold more than one wallet
/// without first configuring a rate table.
class CurrencyRegistry {
  CurrencyRegistry._();

  static const kes = Currency(
    code: 'KES',
    symbol: 'KSh',
    name: 'Kenyan Shilling',
    decimalDigits: 2,
    rateToBase: 1,
  );
  static const usd = Currency(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    rateToBase: 129,
  );
  static const eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    rateToBase: 140,
  );
  static const gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'Pound Sterling',
    rateToBase: 163,
  );
  static const ngn = Currency(
    code: 'NGN',
    symbol: '₦',
    name: 'Nigerian Naira',
    rateToBase: 0.086,
  );
  static const zar = Currency(
    code: 'ZAR',
    symbol: 'R',
    name: 'South African Rand',
    rateToBase: 7.1,
  );
  static const inr = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    rateToBase: 1.46,
  );
  static const jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    decimalDigits: 0,
    rateToBase: 0.84,
  );

  static const base = kes;

  static const all = <Currency>[kes, usd, eur, gbp, ngn, zar, inr, jpy];

  /// Never throws — an unknown stored code falls back to [base] so a ledger
  /// written by a later build stays readable rather than crashing the list.
  static Currency byCode(String? code) {
    if (code == null) return base;
    final upper = code.toUpperCase();
    return all.firstWhere((c) => c.code == upper, orElse: () => base);
  }
}
