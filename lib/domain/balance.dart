import 'enums.dart';

/// Línea mínima de movimiento que afecta a un saldo.
///
/// La capa de datos mapea las filas de la base de datos a este tipo; así el
/// dominio calcula saldos sin conocer Drift y se testea de forma aislada.
class BalanceEntry {
  const BalanceEntry({
    required this.type,
    required this.amountMinor,
    required this.accountId,
    this.transferAccountId,
  });

  final TransactionType type;

  /// Importe en centavos, siempre positivo.
  final int amountMinor;

  /// Cuenta origen (o la única cuenta en gasto/ingreso).
  final String accountId;

  /// Cuenta destino, solo en transferencias.
  final String? transferAccountId;
}

/// Calcula el saldo (en centavos) de una cuenta a partir de su saldo inicial y
/// los movimientos que la afectan.
///
/// - Ingreso: suma a la cuenta.
/// - Gasto: resta de la cuenta.
/// - Transferencia: resta del origen y suma al destino.
int computeAccountBalance({
  required String accountId,
  required int initialBalanceMinor,
  required Iterable<BalanceEntry> entries,
}) {
  var balance = initialBalanceMinor;
  for (final e in entries) {
    switch (e.type) {
      case TransactionType.ingreso:
        if (e.accountId == accountId) balance += e.amountMinor;
      case TransactionType.gasto:
        if (e.accountId == accountId) balance -= e.amountMinor;
      case TransactionType.transferencia:
        if (e.accountId == accountId) balance -= e.amountMinor;
        if (e.transferAccountId == accountId) balance += e.amountMinor;
    }
  }
  return balance;
}

/// Suma de los saldos de varias cuentas (para el "saldo total" de la billetera).
int computeTotalBalance(Map<String, int> balancesByAccount) {
  return balancesByAccount.values.fold(0, (sum, b) => sum + b);
}
