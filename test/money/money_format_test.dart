import 'package:budgy/core/domain/currency.dart';
import 'package:budgy/core/utils/functions/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kes = CurrencyRegistry.kes;
  const jpy = CurrencyRegistry.jpy;

  group('amount', () {
    test('drops a zero fraction and keeps a real one', () {
      expect(MoneyFormat.amount(4832000, kes), 'KSh 48,320');
      expect(MoneyFormat.amount(4832050, kes), 'KSh 48,320.50');
    });

    test('uses a real minus sign, not a hyphen', () {
      expect(MoneyFormat.amount(-2400000, kes).startsWith('−'), isTrue);
      expect(MoneyFormat.amount(-2400000, kes).contains('-'), isFalse);
    });

    test('a zero-decimal currency never shows decimals', () {
      expect(MoneyFormat.amount(1200, jpy), '¥ 1,200');
    });
  });

  group('split', () {
    test('returns the magnitude so callers can render their own sign', () {
      // The regression this guards: `split` used to pass the signed value to
      // `amount`, which signs it too — so a row rendering its own minus came
      // out as "−KSh −24,000".
      final parts = MoneyFormat.split(-2400000, kes);
      expect(parts.whole, '24,000');
      expect(parts.whole.contains('−'), isFalse);
      expect(parts.symbol, 'KSh');
      expect(parts.fraction, isEmpty);
    });

    test('separates the fractional part with its separator', () {
      final parts = MoneyFormat.split(4832050, kes);
      expect(parts.whole, '48,320');
      expect(parts.fraction, '.50');
    });
  });

  group('parse', () {
    test('reads grouped input', () {
      expect(MoneyFormat.parse('48,320.50', kes), 4832050);
      expect(MoneyFormat.parse('KSh 1 200', kes), 120000);
    });

    test('treats the LAST separator as the decimal mark', () {
      expect(MoneyFormat.parse('1.234,56', kes), 123456);
      expect(MoneyFormat.parse('1,234.56', kes), 123456);
    });

    test('rounds rather than truncating', () {
      // 19.99 parses to 19.989999999999998; `toInt()` would bank 1998.
      expect(MoneyFormat.parse('19.99', kes), 1999);
    });

    test('returns null on junk instead of banking a zero', () {
      expect(MoneyFormat.parse('', kes), isNull);
      expect(MoneyFormat.parse('abc', kes), isNull);
    });
  });

  group('convert', () {
    test('is a no-op within one currency', () {
      expect(MoneyFormat.convert(12345, kes, kes), 12345);
    });

    test('crosses a decimal-count boundary correctly', () {
      // 1,000 JPY is 1000 minor units (0 decimals). At the shipped rates it
      // is 840 KES — i.e. 84,000 minor units, not 84,000,000.
      expect(MoneyFormat.convert(1000, jpy, kes), 84000);
    });

    test('round-trips within a unit', () {
      const usd = CurrencyRegistry.usd;
      final there = MoneyFormat.convert(100000, kes, usd);
      final back = MoneyFormat.convert(there, usd, kes);
      expect((back - 100000).abs(), lessThanOrEqualTo(100));
    });
  });

  group('compact', () {
    test('drops a decimal that carries nothing', () {
      expect(MoneyFormat.compact(4832000, kes), '48.3k');
      expect(MoneyFormat.compact(4800000, kes), '48k');
    });

    test('stays in its band when rounding does not overflow', () {
      // 999.5k is a perfectly good label — five characters, unambiguous.
      expect(MoneyFormat.compact(99950000, kes), '999.5k');
    });

    test('promotes when rounding WOULD overflow the band', () {
      // 999,990 rounds to 1000.0k — a tick wider than the one above it, and
      // the point at which an axis stops being monotonic in label width.
      expect(MoneyFormat.compact(99999000, kes), '1M');
      expect(MoneyFormat.compact(99999900000, kes), '1B');
    });

    test('carries the sign through, as a real minus', () {
      expect(MoneyFormat.compact(-4832000, kes), '\u221248.3k');
    });
  });
}
