import 'enums.dart';

/// Datos de un movimiento que el usuario quiere guardar, antes de persistir.
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amountMinor,
    required this.accountId,
    this.categoryId,
    this.transferAccountId,
  });

  final TransactionType type;
  final int amountMinor;
  final String accountId;
  final String? categoryId;
  final String? transferAccountId;
}

/// Valida un [TransactionDraft]. Devuelve un mensaje de error legible o `null`
/// si es válido. Vive en el dominio para testearse sin UI ni base de datos.
String? validateTransaction(TransactionDraft d) {
  if (d.amountMinor <= 0) {
    return 'El importe debe ser mayor que cero.';
  }
  if (d.accountId.isEmpty) {
    return 'Selecciona una cuenta.';
  }

  switch (d.type) {
    case TransactionType.gasto:
    case TransactionType.ingreso:
      if (d.categoryId == null || d.categoryId!.isEmpty) {
        return 'Selecciona una categoría.';
      }
    case TransactionType.transferencia:
      if (d.transferAccountId == null || d.transferAccountId!.isEmpty) {
        return 'Selecciona la cuenta de destino.';
      }
      if (d.transferAccountId == d.accountId) {
        return 'La cuenta de origen y destino no pueden ser la misma.';
      }
  }
  return null;
}
