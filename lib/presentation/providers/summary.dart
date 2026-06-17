import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../../domain/exchange.dart';
import 'providers.dart';

/// Periodo del resumen. El selector controla toda la pantalla.
enum SummaryPeriod { mes, trimestre, semestre, anio }

/// Rango semiabierto `[start, endExclusive)`.
typedef Range = ({DateTime start, DateTime endExclusive});

/// Totales de un periodo (en centavos). El balance = ingresos − gastos.
typedef SummaryTotals = ({int incomeMinor, int expenseMinor});

/// Porción de gasto de una categoría (id nulo = sin categoría).
typedef CategorySlice = ({String? categoryId, int amountMinor});

/// Barra de evolución: inicio del sub-periodo + gasto/ingreso de ese tramo.
typedef EvolutionBar = ({DateTime start, int expenseMinor, int incomeMinor});

// ---- Lógica pura (testeable) ----

/// Calcula el rango natural del [period] anclado en [anchor], desplazado
/// [offset] unidades (negativo = pasado).
Range rangeFor(SummaryPeriod period, {required DateTime anchor, int offset = 0}) {
  switch (period) {
    case SummaryPeriod.mes:
      final start = DateTime(anchor.year, anchor.month + offset, 1);
      return (start: start, endExclusive: DateTime(start.year, start.month + 1, 1));
    case SummaryPeriod.trimestre:
      final q = (anchor.month - 1) ~/ 3; // 0..3
      final firstMonth = q * 3 + 1;
      final start = DateTime(anchor.year, firstMonth + offset * 3, 1);
      return (start: start, endExclusive: DateTime(start.year, start.month + 3, 1));
    case SummaryPeriod.semestre:
      final h = (anchor.month - 1) ~/ 6; // 0..1
      final firstMonth = h * 6 + 1;
      final start = DateTime(anchor.year, firstMonth + offset * 6, 1);
      return (start: start, endExclusive: DateTime(start.year, start.month + 6, 1));
    case SummaryPeriod.anio:
      final start = DateTime(anchor.year + offset, 1, 1);
      return (start: start, endExclusive: DateTime(start.year + 1, 1, 1));
  }
}

bool _inRange(DateTime d, Range r) =>
    !d.isBefore(r.start) && d.isBefore(r.endExclusive);

/// Ingresos y gastos dentro del rango (las transferencias no cuentan).
SummaryTotals totalsIn(List<TransactionRow> txns, Range range) {
  var income = 0;
  var expense = 0;
  for (final t in txns) {
    if (!_inRange(t.date, range)) continue;
    switch (t.type) {
      case TransactionType.ingreso:
        income += t.amountMinor;
      case TransactionType.gasto:
        expense += t.amountMinor;
      case TransactionType.transferencia:
        break;
    }
  }
  return (incomeMinor: income, expenseMinor: expense);
}

/// Gasto agrupado por categoría en el rango, de mayor a menor.
List<CategorySlice> expenseByCategory(List<TransactionRow> txns, Range range) {
  final byCat = <String?, int>{};
  for (final t in txns) {
    if (t.type != TransactionType.gasto || !_inRange(t.date, range)) continue;
    byCat.update(t.categoryId, (v) => v + t.amountMinor,
        ifAbsent: () => t.amountMinor);
  }
  final slices = byCat.entries
      .map((e) => (categoryId: e.key, amountMinor: e.value))
      .toList()
    ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
  return slices;
}

/// Barras de evolución: por día si el periodo es mes; por mes en el resto.
List<EvolutionBar> evolution(
  List<TransactionRow> txns,
  SummaryPeriod period,
  Range range,
) {
  final buckets = <DateTime>[];
  if (period == SummaryPeriod.mes) {
    var day = range.start;
    while (day.isBefore(range.endExclusive)) {
      buckets.add(day);
      day = DateTime(day.year, day.month, day.day + 1);
    }
  } else {
    var month = range.start;
    while (month.isBefore(range.endExclusive)) {
      buckets.add(month);
      month = DateTime(month.year, month.month + 1, 1);
    }
  }

  bool sameBucket(DateTime txDate, DateTime bucketStart, DateTime bucketEnd) =>
      !txDate.isBefore(bucketStart) && txDate.isBefore(bucketEnd);

  final bars = <EvolutionBar>[];
  for (var i = 0; i < buckets.length; i++) {
    final start = buckets[i];
    final end = i + 1 < buckets.length ? buckets[i + 1] : range.endExclusive;
    var expense = 0;
    var income = 0;
    for (final t in txns) {
      if (!sameBucket(t.date, start, end)) continue;
      if (t.type == TransactionType.gasto) {
        expense += t.amountMinor;
      } else if (t.type == TransactionType.ingreso) {
        income += t.amountMinor;
      }
    }
    bars.add((start: start, expenseMinor: expense, incomeMinor: income));
  }
  return bars;
}

// ---- Estado y providers ----

typedef SummarySelection = ({SummaryPeriod period, int offset});

class SummarySelectionNotifier extends Notifier<SummarySelection> {
  @override
  SummarySelection build() => (period: SummaryPeriod.mes, offset: 0);

  void setPeriod(SummaryPeriod period) =>
      state = (period: period, offset: 0); // reinicia la navegación

  void prev() => state = (period: state.period, offset: state.offset - 1);

  /// No permite navegar al futuro (offset máximo 0).
  void next() {
    if (state.offset < 0) {
      state = (period: state.period, offset: state.offset + 1);
    }
  }
}

final summarySelectionProvider =
    NotifierProvider<SummarySelectionNotifier, SummarySelection>(
  SummarySelectionNotifier.new,
);

final summaryRangeProvider = Provider<Range>((ref) {
  final sel = ref.watch(summarySelectionProvider);
  return rangeFor(sel.period, anchor: DateTime.now(), offset: sel.offset);
});

/// Movimientos con su importe ya convertido a la moneda predeterminada (desde
/// la moneda de su cuenta). Así los agregados del resumen son comparables.
/// Si falta la tasa, el importe queda en 0 (no contamina los totales).
final _summaryTxnsProvider = Provider<List<TransactionRow>>((ref) {
  final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
  final accountsById = ref.watch(accountsByIdProvider);
  final rates = ref.watch(ratesMapProvider);
  final def = ref.watch(defaultCurrencyProvider);
  if (def == null) return txns;
  return txns.map((t) {
    final code = accountsById[t.accountId]?.currency ?? def.code;
    if (code == def.code) return t;
    final converted =
        convertMinor(t.amountMinor, code, def.code, rates, def.code) ?? 0;
    return t.copyWith(amountMinor: converted);
  }).toList(growable: false);
});

final summaryTotalsProvider = Provider<SummaryTotals>((ref) {
  final txns = ref.watch(_summaryTxnsProvider);
  return totalsIn(txns, ref.watch(summaryRangeProvider));
});

final expenseByCategoryProvider = Provider<List<CategorySlice>>((ref) {
  final txns = ref.watch(_summaryTxnsProvider);
  return expenseByCategory(txns, ref.watch(summaryRangeProvider));
});

final evolutionProvider = Provider<List<EvolutionBar>>((ref) {
  final txns = ref.watch(_summaryTxnsProvider);
  final sel = ref.watch(summarySelectionProvider);
  return evolution(txns, sel.period, ref.watch(summaryRangeProvider));
});

/// Comisiones de transferencia del periodo, convertidas a la predeterminada.
final feesInPeriodProvider = Provider<int>((ref) {
  final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
  final accountsById = ref.watch(accountsByIdProvider);
  final rates = ref.watch(ratesMapProvider);
  final def = ref.watch(defaultCurrencyProvider);
  final range = ref.watch(summaryRangeProvider);
  if (def == null) return 0;
  var total = 0;
  for (final t in txns) {
    final fee = t.feeMinor;
    if (fee == null || fee == 0) continue;
    if (t.date.isBefore(range.start) || !t.date.isBefore(range.endExclusive)) {
      continue;
    }
    final code = accountsById[t.accountId]?.currency ?? def.code;
    total += convertMinor(fee, code, def.code, rates, def.code) ?? 0;
  }
  return total;
});
