import 'package:budgy/core/domain/currency.dart';
import 'package:budgy/core/presentation/components/amount_field.dart';
import 'package:budgy/core/presentation/components/amount_keypad.dart';
import 'package:flutter_test/flutter_test.dart';

/// The entry maths: what a keypress does to the text, and what an operator
/// does to the running total. Both are pure, both are load-bearing, and a
/// mistake in either writes a wrong number into the ledger silently.
void main() {
  final kes = CurrencyRegistry.byCode('KES');
  final jpy = const Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    decimalDigits: 0,
  );

  ({String text, int caret}) press(
    String text,
    int caret,
    String key, [
    Currency? currency,
  ]) => applyAmountKey(
    text: text,
    caret: caret,
    key: key,
    currency: currency ?? kes,
  );

  group('applyAmountKey — insertion', () {
    test('appends at the end', () {
      final r = press('12', 2, '5');
      expect(r.text, '125');
      expect(r.caret, 3);
    });

    test('inserts in the middle and carries the caret with it', () {
      // The whole point of the caret: 100 → 150 by typing 5 between the zeros.
      final r = press('100', 2, '5');
      expect(r.text, '1050');
      expect(r.caret, 3);
    });

    test('inserts at the very start', () {
      final r = press('50', 0, '2');
      expect(r.text, '250');
      expect(r.caret, 1);
    });

    test('replaces a lone zero rather than prefixing it', () {
      final r = press('0', 1, '7');
      expect(r.text, '7');
      expect(r.caret, 1);
    });

    test('caps the overall length', () {
      final long = '9' * 12;
      expect(press(long, 12, '9').text, long);
    });
  });

  group('applyAmountKey — the decimal point', () {
    test('is refused on a zero-decimal currency', () {
      expect(press('12', 2, '.', jpy).text, '12');
    });

    test('never leads — an empty field becomes 0.', () {
      final r = press('', 0, '.');
      expect(r.text, '0.');
      expect(r.caret, 2);
    });

    test('appears only once', () {
      expect(press('1.5', 3, '.').text, '1.5');
    });

    test('inserts at the caret', () {
      final r = press('1250', 2, '.');
      expect(r.text, '12.50');
      expect(r.caret, 3);
    });
  });

  group('applyAmountKey — the fraction cap', () {
    test('refuses a third decimal', () {
      expect(press('19.99', 5, '9').text, '19.99');
    });

    test('⚠️ still accepts a digit typed BEFORE the point', () {
      // The cap is about where the digit lands, not about how many decimals
      // exist. Refusing this would block editing the whole part of any amount
      // that already has two decimals.
      final r = press('19.99', 0, '2');
      expect(r.text, '219.99');
      expect(r.caret, 1);
    });
  });

  group('applyAmountKey — backspace', () {
    test('deletes the character before the caret', () {
      final r = press('1050', 3, '⌫');
      expect(r.text, '100');
      expect(r.caret, 2);
    });

    test('is a no-op at the start, and does not move the caret', () {
      final r = press('100', 0, '⌫');
      expect(r.text, '100');
      expect(r.caret, 0);
    });

    test('empties a single character', () {
      final r = press('5', 1, '⌫');
      expect(r.text, '');
      expect(r.caret, 0);
    });
  });

  group('CalcOp', () {
    test('applies left to right', () {
      expect(CalcOp.add.apply(1250, 340), 1590);
      expect(CalcOp.subtract.apply(1250, 340), 910);
      expect(CalcOp.multiply.apply(250, 3), 750);
      expect(CalcOp.divide.apply(1200, 4), 300);
    });

    test('⚠️ division by zero returns the left operand, not infinity', () {
      // The divisor is read live while being typed, so "÷ 40" passes through
      // "÷ 0" on the way. Infinity here reaches `toMinor` and crashes.
      expect(CalcOp.divide.apply(1200, 0), 1200);
      expect(CalcOp.divide.apply(1200, 0).isFinite, isTrue);
    });

    test('round-trips through its glyph', () {
      for (final op in CalcOp.values) {
        expect(CalcOp.fromGlyph(op.glyph), op);
      }
      expect(CalcOp.fromGlyph('5'), isNull);
      expect(CalcOp.fromGlyph('⌫'), isNull);
    });
  });

  group('AmountKeypad text round-trip', () {
    test('fromMinor drops a fraction that carries nothing', () {
      expect(AmountKeypad.fromMinor(125000, kes), '1250');
    });

    test('fromMinor keeps a real fraction', () {
      expect(AmountKeypad.fromMinor(125050, kes), '1250.50');
    });

    test('an empty amount is empty text, not "0"', () {
      expect(AmountKeypad.fromMinor(0, kes), '');
    });

    test('toMinor and fromMinor agree across the boundary', () {
      for (final minor in [1, 99, 100, 125050, 999999]) {
        expect(
          AmountKeypad.toMinor(AmountKeypad.fromMinor(minor, kes), kes),
          minor,
        );
      }
    });
  });
}
