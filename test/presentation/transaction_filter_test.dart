import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/domain/enums.dart';
import 'package:billetera/presentation/providers/transaction_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionRow _tx({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required DateTime date,
  String accountId = 'a1',
  String? transferAccountId,
  String? note,
}) {
  return TransactionRow(
    id: id,
    accountId: accountId,
    type: type,
    amountMinor: amountMinor,
    date: date,
    transferAccountId: transferAccountId,
    note: note,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  final txns = [
    _tx(
      id: '1',
      type: TransactionType.gasto,
      amountMinor: 1000,
      date: DateTime(2026, 1, 10),
      accountId: 'a1',
      note: 'Café con leche',
    ),
    _tx(
      id: '2',
      type: TransactionType.ingreso,
      amountMinor: 5000,
      date: DateTime(2026, 2, 1),
      accountId: 'a2',
      note: 'Salario',
    ),
    _tx(
      id: '3',
      type: TransactionType.transferencia,
      amountMinor: 2000,
      date: DateTime(2026, 2, 15),
      accountId: 'a1',
      transferAccountId: 'a2',
    ),
  ];

  test('sin filtro devuelve todo', () {
    expect(applyTransactionFilter(txns, const TransactionFilter()).length, 3);
  });

  test('filtra por tipo', () {
    final r = applyTransactionFilter(
      txns,
      const TransactionFilter(type: TransactionType.gasto),
    );
    expect(r.map((t) => t.id), ['1']);
  });

  test('filtra por cuenta incluyendo transferencias (origen o destino)', () {
    final r = applyTransactionFilter(
      txns,
      const TransactionFilter(accountId: 'a2'),
    );
    // ingreso en a2 (id 2) + transferencia con destino a2 (id 3)
    expect(r.map((t) => t.id).toSet(), {'2', '3'});
  });

  test('filtra por rango de fechas inclusivo', () {
    final r = applyTransactionFilter(
      txns,
      TransactionFilter(
        dateRange: DateTimeRange(
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 15),
        ),
      ),
    );
    expect(r.map((t) => t.id).toSet(), {'2', '3'});
  });

  test('busca texto en la nota sin distinguir mayúsculas', () {
    final r = applyTransactionFilter(
      txns,
      const TransactionFilter(query: 'CAFÉ'),
    );
    expect(r.map((t) => t.id), ['1']);
  });

  test('combina varios criterios', () {
    final r = applyTransactionFilter(
      txns,
      TransactionFilter(
        type: TransactionType.ingreso,
        accountId: 'a2',
        dateRange: DateTimeRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 12, 31),
        ),
      ),
    );
    expect(r.map((t) => t.id), ['2']);
  });
}
