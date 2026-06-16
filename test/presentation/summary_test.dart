import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/domain/enums.dart';
import 'package:billetera/presentation/providers/summary.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionRow _tx({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required DateTime date,
  String? categoryId,
}) {
  return TransactionRow(
    id: id,
    accountId: 'a1',
    type: type,
    amountMinor: amountMinor,
    date: date,
    categoryId: categoryId,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('rangeFor', () {
    final anchor = DateTime(2026, 5, 17); // mayo, T2, semestre 1

    test('mes', () {
      final r = rangeFor(SummaryPeriod.mes, anchor: anchor);
      expect(r.start, DateTime(2026, 5, 1));
      expect(r.endExclusive, DateTime(2026, 6, 1));
    });

    test('mes con offset negativo cruza el año', () {
      final r = rangeFor(SummaryPeriod.mes,
          anchor: DateTime(2026, 1, 10), offset: -1);
      expect(r.start, DateTime(2025, 12, 1));
      expect(r.endExclusive, DateTime(2026, 1, 1));
    });

    test('trimestre natural (T2 = abr–jun)', () {
      final r = rangeFor(SummaryPeriod.trimestre, anchor: anchor);
      expect(r.start, DateTime(2026, 4, 1));
      expect(r.endExclusive, DateTime(2026, 7, 1));
    });

    test('semestre natural (H1 = ene–jun)', () {
      final r = rangeFor(SummaryPeriod.semestre, anchor: anchor);
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.endExclusive, DateTime(2026, 7, 1));
    });

    test('año con offset', () {
      final r = rangeFor(SummaryPeriod.anio, anchor: anchor, offset: -1);
      expect(r.start, DateTime(2025, 1, 1));
      expect(r.endExclusive, DateTime(2026, 1, 1));
    });
  });

  group('agregados', () {
    final mayo = (
      start: DateTime(2026, 5, 1),
      endExclusive: DateTime(2026, 6, 1)
    );
    final txns = [
      _tx(id: '1', type: TransactionType.gasto, amountMinor: 1000, date: DateTime(2026, 5, 3), categoryId: 'comida'),
      _tx(id: '2', type: TransactionType.gasto, amountMinor: 500, date: DateTime(2026, 5, 20), categoryId: 'comida'),
      _tx(id: '3', type: TransactionType.gasto, amountMinor: 800, date: DateTime(2026, 5, 10), categoryId: 'transporte'),
      _tx(id: '4', type: TransactionType.ingreso, amountMinor: 9000, date: DateTime(2026, 5, 1), categoryId: 'salario'),
      _tx(id: '5', type: TransactionType.transferencia, amountMinor: 2000, date: DateTime(2026, 5, 5)),
      _tx(id: '6', type: TransactionType.gasto, amountMinor: 300, date: DateTime(2026, 6, 1), categoryId: 'comida'), // fuera de rango
    ];

    test('totalsIn excluye transferencias y respeta el rango', () {
      final t = totalsIn(txns, mayo);
      expect(t.incomeMinor, 9000);
      expect(t.expenseMinor, 2300); // 1000+500+800 (no el de junio)
    });

    test('expenseByCategory agrupa y ordena desc', () {
      final slices = expenseByCategory(txns, mayo);
      expect(slices.map((s) => s.categoryId), ['comida', 'transporte']);
      expect(slices.first.amountMinor, 1500); // comida 1000+500
      expect(slices[1].amountMinor, 800);
    });

    test('evolution por mes produce una barra por día del mes', () {
      final bars = evolution(txns, SummaryPeriod.mes, mayo);
      expect(bars.length, 31); // mayo tiene 31 días
      final day3 = bars.firstWhere((b) => b.start.day == 3);
      expect(day3.expenseMinor, 1000);
      final day1 = bars.firstWhere((b) => b.start.day == 1);
      expect(day1.incomeMinor, 9000);
    });

    test('evolution trimestral produce 3 barras (por mes)', () {
      final t2 = (start: DateTime(2026, 4, 1), endExclusive: DateTime(2026, 7, 1));
      final bars = evolution(txns, SummaryPeriod.trimestre, t2);
      expect(bars.length, 3);
      expect(bars[0].expenseMinor, 0); // abril
      expect(bars[1].expenseMinor, 2300); // mayo (1000+500+800)
      expect(bars[2].expenseMinor, 300); // junio (el gasto del 1 de junio sí cuenta)
    });

    test('evolution anual produce 12 barras', () {
      final anio = (start: DateTime(2026, 1, 1), endExclusive: DateTime(2027, 1, 1));
      final bars = evolution(txns, SummaryPeriod.anio, anio);
      expect(bars.length, 12);
    });
  });
}
