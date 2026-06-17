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
    this.transferAmountMinor,
  });

  final TransactionType type;

  /// Importe en centavos, siempre positivo. En transferencias, lo que SALE del
  /// origen (en la moneda del origen).
  final int amountMinor;

  /// Cuenta origen (o la única cuenta en gasto/ingreso).
  final String accountId;

  /// Cuenta destino, solo en transferencias.
  final String? transferAccountId;

  /// Lo que ENTRA al destino (en la moneda del destino). Si es nulo, se usa
  /// [amountMinor] (transferencia de la misma moneda y sin comisión).
  final int? transferAmountMinor;
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
        if (e.transferAccountId == accountId) {
          balance += e.transferAmountMinor ?? e.amountMinor;
        }
    }
  }
  return balance;
}

/// Suma de los saldos de varias cuentas (para el "saldo total" de la billetera).
int computeTotalBalance(Map<String, int> balancesByAccount) {
  return balancesByAccount.values.fold(0, (sum, b) => sum + b);
}
