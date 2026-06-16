import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import 'providers.dart';

/// Criterios de filtrado del historial de movimientos.
@immutable
class TransactionFilter {
  const TransactionFilter({
    this.dateRange,
    this.accountId,
    this.type,
    this.query = '',
  });

  /// Rango de fechas (inclusivo por día). `null` = sin límite.
  final DateTimeRange? dateRange;

  /// Cuenta implicada (origen o destino en transferencias). `null` = todas.
  final String? accountId;

  /// Tipo de movimiento. `null` = todos.
  final TransactionType? type;

  /// Texto a buscar en la nota (sin distinguir mayúsculas).
  final String query;

  bool get hasFilters =>
      dateRange != null ||
      accountId != null ||
      type != null ||
      query.trim().isNotEmpty;

  TransactionFilter copyWith({
    DateTimeRange? dateRange,
    String? accountId,
    TransactionType? type,
    String? query,
    bool clearDateRange = false,
    bool clearAccount = false,
    bool clearType = false,
  }) {
    return TransactionFilter(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      type: clearType ? null : (type ?? this.type),
      query: query ?? this.query,
    );
  }
}

/// Aplica el filtro a una lista de movimientos. Función pura (testeable).
/// Asume que [txns] viene ordenada por fecha descendente y conserva el orden.
List<TransactionRow> applyTransactionFilter(
  List<TransactionRow> txns,
  TransactionFilter filter,
) {
  final q = filter.query.trim().toLowerCase();
  final range = filter.dateRange;
  // Normaliza el rango a límites por día (inclusivo).
  final start = range == null
      ? null
      : DateTime(range.start.year, range.start.month, range.start.day);
  final end = range == null
      ? null
      : DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);

  return txns.where((t) {
    if (filter.type != null && t.type != filter.type) return false;
    if (filter.accountId != null &&
        t.accountId != filter.accountId &&
        t.transferAccountId != filter.accountId) {
      return false;
    }
    if (start != null && t.date.isBefore(start)) return false;
    if (end != null && t.date.isAfter(end)) return false;
    if (q.isNotEmpty && !(t.note?.toLowerCase().contains(q) ?? false)) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

/// Estado del filtro de movimientos.
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setDateRange(DateTimeRange? range) =>
      state = range == null
          ? state.copyWith(clearDateRange: true)
          : state.copyWith(dateRange: range);

  void setAccount(String? accountId) => state = accountId == null
      ? state.copyWith(clearAccount: true)
      : state.copyWith(accountId: accountId);

  void setType(TransactionType? type) => state = type == null
      ? state.copyWith(clearType: true)
      : state.copyWith(type: type);

  void setQuery(String query) => state = state.copyWith(query: query);

  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

/// Movimientos tras aplicar el filtro activo.
final filteredTransactionsProvider = Provider<List<TransactionRow>>((ref) {
  final all = ref.watch(transactionsProvider).asData?.value ?? const [];
  final filter = ref.watch(transactionFilterProvider);
  return applyTransactionFilter(all, filter);
});

/// Resumen (ingresos, gastos) en centavos del conjunto filtrado.
/// Las transferencias no cuentan como ingreso ni gasto.
typedef TransactionsSummary = ({int incomeMinor, int expenseMinor});

final filteredSummaryProvider = Provider<TransactionsSummary>((ref) {
  final txns = ref.watch(filteredTransactionsProvider);
  var income = 0;
  var expense = 0;
  for (final t in txns) {
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
});
