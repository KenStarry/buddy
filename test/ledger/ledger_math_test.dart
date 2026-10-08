import 'package:budgy/core/domain/currency.dart';
import 'package:budgy/features/accounts/domain/model/account_model.dart';
import 'package:budgy/features/transactions/domain/enum/transaction_type.dart';
import 'package:budgy/features/transactions/domain/model/transaction_model.dart';
import 'package:budgy/modules/ledger/domain/ledger_math.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel tx({
  required int minor,
  required TransactionType type,
  String account = 'a',
  String? destination,
  String currency = 'KES',
  TransactionNature nature = TransactionNature.standard,
  bool settled = true,
  DateTime? date,
  String? category,
}) => TransactionModel(
  id: 'tx-$minor-${type.name}-${date?.millisecondsSinceEpoch ?? 0}-$account',
  title: 'test',
  amountMinor: minor,
  type: type,
  nature: nature,
  accountId: account,
  destinationAccountId: destination,
  currencyCode: currency,
  categoryId: category,
  isSettled: settled,
  date: date ?? DateTime(2026, 10, 5),
);

void main() {
  const kes = CurrencyRegistry.kes;

  const wallet = AccountModel(
    id: 'a',
    name: 'M-Pesa',
    currencyCode: 'KES',
    iconKey: 'wallet',
    colorIndex: 0,
    openingBalanceMinor: 1000000,
  );
  const savings = AccountModel(
    id: 'b',
    name: 'Savings',
    currencyCode: 'KES',
    iconKey: 'piggy-bank',
    colorIndex: 1,
  );

  group('totals', () {
    test('unsettled rows do not count', () {
      final rows = [
        tx(minor: 50000, type: TransactionType.expense),
        tx(minor: 90000, type: TransactionType.expense, settled: false),
      ];
      expect(LedgerMath.totals(rows, kes).outflowMinor, 50000);
    });

    test('transfers are neither in nor out', () {
      final rows = [
        tx(minor: 500000, type: TransactionType.transfer, destination: 'b'),
      ];
      final t = LedgerMath.totals(rows, kes);
      expect(t.inflowMinor, 0);
      expect(t.outflowMinor, 0);
    });

    test('loans are excluded from income and spend', () {
      final rows = [
        tx(
          minor: 150000,
          type: TransactionType.income,
          nature: TransactionNature.debt,
        ),
      ];
      final t = LedgerMath.totals(rows, kes);
      expect(t.inflowMinor, 0);
    });

    test('savings rate is null on zero income, not zero', () {
      final rows = [tx(minor: 50000, type: TransactionType.expense)];
      expect(LedgerMath.totals(rows, kes).savingsRate, isNull);
    });
  });

  group('balances', () {
    test('a transfer moves money without changing the total', () {
      final rows = [
        tx(minor: 300000, type: TransactionType.transfer, destination: 'b'),
      ];
      final balances = LedgerMath.balances([wallet, savings], rows, kes);
      expect(balances[0].minor, 700000); // 1,000,000 − 300,000
      expect(balances[1].minor, 300000);
      // The ledger as a whole is unchanged.
      expect(LedgerMath.netWorth(balances), 1000000);
    });

    test('an unsettled row does not move a balance', () {
      final rows = [
        tx(minor: 400000, type: TransactionType.expense, settled: false),
      ];
      final balances = LedgerMath.balances([wallet], rows, kes);
      expect(balances.single.minor, 1000000);
    });

    test('a wallet opted out is left out of net worth', () {
      const card = AccountModel(
        id: 'c',
        name: 'Card',
        currencyCode: 'KES',
        iconKey: 'credit-card',
        colorIndex: 2,
        openingBalanceMinor: -500000,
        excludeFromNetWorth: true,
      );
      final balances = LedgerMath.balances([wallet, card], const [], kes);
      expect(LedgerMath.netWorth(balances), 1000000);
    });

    test('a foreign-currency entry lands in the wallet’s own unit', () {
      final rows = [
        tx(minor: 1000, type: TransactionType.expense, currency: 'USD'),
      ];
      final balances = LedgerMath.balances([wallet], rows, kes);
      // $10 at the shipped rate of 129 is 1,290 KES = 129,000 minor units.
      expect(balances.single.minor, 1000000 - 129000);
    });
  });

  group('dailySpend', () {
    test('zero-fills quiet days', () {
      final rows = [
        tx(minor: 50000, type: TransactionType.expense, date: DateTime(2026, 10, 1)),
        tx(minor: 70000, type: TransactionType.expense, date: DateTime(2026, 10, 4)),
      ];
      final series = LedgerMath.dailySpend(
        rows,
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 5),
        kes,
      );
      // A line drawn from only the days that had spending would connect the
      // 1st straight to the 4th and read as steady spending through a quiet
      // stretch.
      expect(series.length, 5);
      expect(series.map((p) => p.minor).toList(), [50000, 0, 0, 70000, 0]);
    });
  });

  group('spendByCategory', () {
    test('gathers uncategorised rather than dropping them', () {
      final rows = [
        tx(minor: 60000, type: TransactionType.expense, category: 'food'),
        tx(minor: 40000, type: TransactionType.expense),
      ];
      final spend = LedgerMath.spendByCategory(rows, kes);
      expect(spend.length, 2);
      expect(
        spend.map((s) => s.categoryId),
        contains(LedgerMath.uncategorisedId),
      );
      // The shares must still add to 1, or the chart contradicts the total
      // printed above it.
      expect(
        spend.fold<double>(0, (sum, s) => sum + s.share),
        closeTo(1.0, 0.0001),
      );
    });

    test('is ordered largest first', () {
      final rows = [
        tx(minor: 10000, type: TransactionType.expense, category: 'a'),
        tx(minor: 90000, type: TransactionType.expense, category: 'b'),
      ];
      final spend = LedgerMath.spendByCategory(rows, kes);
      expect(spend.first.categoryId, 'b');
    });
  });
}
