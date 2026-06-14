import 'package:billetera/domain/balance.dart';
import 'package:billetera/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeAccountBalance', () {
    const acc = 'a1';
    const other = 'a2';

    test('parte del saldo inicial cuando no hay movimientos', () {
      final balance = computeAccountBalance(
        accountId: acc,
        initialBalanceMinor: 5000,
        entries: const [],
      );
      expect(balance, 5000);
    });

    test('suma ingresos y resta gastos de la cuenta', () {
      final balance = computeAccountBalance(
        accountId: acc,
        initialBalanceMinor: 1000,
        entries: const [
          BalanceEntry(type: TransactionType.ingreso, amountMinor: 2000, accountId: acc),
          BalanceEntry(type: TransactionType.gasto, amountMinor: 500, accountId: acc),
        ],
      );
      expect(balance, 1000 + 2000 - 500);
    });

    test('ignora movimientos de otras cuentas', () {
      final balance = computeAccountBalance(
        accountId: acc,
        initialBalanceMinor: 0,
        entries: const [
          BalanceEntry(type: TransactionType.ingreso, amountMinor: 9999, accountId: other),
        ],
      );
      expect(balance, 0);
    });

    test('transferencia resta del origen y suma al destino', () {
      const entries = [
        BalanceEntry(
          type: TransactionType.transferencia,
          amountMinor: 700,
          accountId: acc,
          transferAccountId: other,
        ),
      ];
      final origen = computeAccountBalance(
        accountId: acc,
        initialBalanceMinor: 1000,
        entries: entries,
      );
      final destino = computeAccountBalance(
        accountId: other,
        initialBalanceMinor: 1000,
        entries: entries,
      );
      expect(origen, 300, reason: 'origen pierde 700');
      expect(destino, 1700, reason: 'destino gana 700');
    });

    test('una transferencia no cambia el total entre las dos cuentas', () {
      const entries = [
        BalanceEntry(
          type: TransactionType.transferencia,
          amountMinor: 500,
          accountId: acc,
          transferAccountId: other,
        ),
      ];
      final total = computeAccountBalance(accountId: acc, initialBalanceMinor: 1000, entries: entries) +
          computeAccountBalance(accountId: other, initialBalanceMinor: 0, entries: entries);
      expect(total, 1000, reason: 'el dinero solo se mueve, no se crea ni destruye');
    });
  });

  group('computeTotalBalance', () {
    test('suma todos los saldos', () {
      expect(computeTotalBalance({'a': 1000, 'b': -300, 'c': 50}), 750);
    });
  });
}
