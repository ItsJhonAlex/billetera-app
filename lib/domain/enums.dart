/// Tipo de cuenta donde se guarda el dinero.
///
/// Los nombres (`.name`) se persisten como texto en la base de datos, así que
/// **no se deben renombrar** sin una migración. Añadir valores nuevos es seguro.
enum AccountType {
  efectivo,
  banco,
  tarjeta,
  otro,
}

/// Naturaleza de una categoría: si agrupa gastos o ingresos.
enum CategoryKind {
  gasto,
  ingreso,
}

/// Tipo de movimiento.
///
/// Una [transferencia] mueve dinero de una cuenta a otra y no lleva categoría.
enum TransactionType {
  gasto,
  ingreso,
  transferencia,
}

/// Cómo se registra una regla recurrente.
///
/// [automatica]: importe fijo; el movimiento se crea solo en la recuperación al
/// abrir la app. [manual]: importe estimado; se registra cuando el usuario pulsa
/// "Pagar" (y puede ajustar el monto).
///
/// Los nombres (`.name`) se persisten como texto: no renombrar sin migración.
enum RecurringMode {
  automatica,
  manual,
}

/// Cómo se calcula el siguiente vencimiento de una regla recurrente.
///
/// [diaDelMes]: un día fijo del mes (ajustado al último día si el mes es corto).
/// [cadaNDias]: cada N días desde el último pago.
///
/// Los nombres (`.name`) se persisten como texto: no renombrar sin migración.
enum RecurringSchedule {
  diaDelMes,
  cadaNDias,
}

/// Cómo se define el límite mensual de un presupuesto de categoría.
///
/// [fijo]: un monto en centavos. [porcentaje]: un % del saldo (al inicio del
/// mes) de las cuentas incluidas en el presupuesto.
///
/// Los nombres (`.name`) se persisten como texto: no renombrar sin migración.
enum BudgetLimitType {
  fijo,
  porcentaje,
}
