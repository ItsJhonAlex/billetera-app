import 'package:billetera/domain/enums.dart';
import 'package:billetera/domain/transaction_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateTransaction', () {
    test('rechaza importe cero o negativo', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 0,
        accountId: 'a1',
        categoryId: 'c1',
      ));
      expect(err, isNotNull);
    });

    test('gasto requiere categoría', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 100,
        accountId: 'a1',
      ));
      expect(err, contains('categoría'));
    });

    test('gasto válido pasa', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 100,
        accountId: 'a1',
        categoryId: 'c1',
      ));
      expect(err, isNull);
    });

    test('transferencia requiere cuenta destino', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 100,
        accountId: 'a1',
      ));
      expect(err, contains('destino'));
    });

    test('transferencia no puede ir a la misma cuenta', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 100,
        accountId: 'a1',
        transferAccountId: 'a1',
      ));
      expect(err, isNotNull);
    });

    test('transferencia válida pasa', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 100,
        accountId: 'a1',
        transferAccountId: 'a2',
      ));
      expect(err, isNull);
    });

    test('rechaza comisión mayor o igual al monto', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 100,
        accountId: 'a1',
        transferAccountId: 'a2',
        feeMinor: 100,
      ));
      expect(err, contains('comisión'));
    });

    test('rechaza monto recibido cero', () {
      final err = validateTransaction(const TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 100,
        accountId: 'a1',
        transferAccountId: 'a2',
        transferAmountMinor: 0,
      ));
      expect(err, contains('recibido'));
    });
  });
}
