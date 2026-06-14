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
