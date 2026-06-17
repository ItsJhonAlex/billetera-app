import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// Cuentas donde se guarda el dinero (efectivo, banco, tarjeta…).
///
/// El saldo NO se almacena: se calcula a partir de [initialBalanceMinor] y los
/// movimientos. Así nunca queda descuadrado.
@DataClassName('AccountRow')
class Accounts extends Table {
  /// UUID en texto. Pensado para una futura sincronización en la nube.
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  TextColumn get type => textEnum<AccountType>()();

  /// Saldo inicial en centavos.
  IntColumn get initialBalanceMinor => integer().withDefault(const Constant(0))();

  /// Código de moneda ISO (por ahora siempre "CUP").
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('CUP'))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Si la cuenta cuenta para la base del % de los presupuestos
  /// (ahorro/emergencia suelen excluirse).
  BoolColumn get includeInBudget => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Monedas que maneja el usuario. El [code] (ej. "CUP") es la clave.
@DataClassName('CurrencyRow')
class Currencies extends Table {
  TextColumn get code => text().withLength(min: 2, max: 8)();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  TextColumn get symbol => text().withLength(min: 1, max: 6)();

  /// Decimales para mostrar (por ahora se almacena a 2 decimales).
  IntColumn get decimalDigits => integer().withDefault(const Constant(2))();

  /// La moneda en la que se muestra el saldo total. Solo una en `true`.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {code};
}

/// Tasa de cambio dirigida: `1 [fromCode] = [rate] [toCode]`.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get id => text()();

  TextColumn get fromCode => text()();

  TextColumn get toCode => text()();

  RealColumn get rate => real()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categorías para clasificar gastos e ingresos.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  TextColumn get kind => textEnum<CategoryKind>()();

  /// Codepoint del icono Material (ej. Icons.fastfood.codePoint).
  IntColumn get iconCodePoint => integer()();

  /// Color del badge, como entero ARGB.
  IntColumn get colorValue => integer()();

  /// `true` si vino sembrada por defecto (informativo; igual es editable/borrable).
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Movimientos: gastos, ingresos y transferencias.
///
/// En una transferencia, [accountId] es el origen y [transferAccountId] el
/// destino; [categoryId] queda nulo.
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();

  TextColumn get accountId => text().references(Accounts, #id)();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  TextColumn get type => textEnum<TransactionType>()();

  /// Importe en centavos, siempre positivo. El signo lo da [type].
  IntColumn get amountMinor => integer()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get date => dateTime()();

  /// Cuenta destino, solo en transferencias.
  TextColumn get transferAccountId => text().nullable().references(Accounts, #id)();

  /// Monto acreditado en la cuenta destino (transferencias entre monedas).
  /// Si es nulo, se usa [amountMinor] (misma moneda, sin comisión).
  IntColumn get transferAmountMinor => integer().nullable()();

  /// Comisión de la transferencia, en la moneda de origen (dinero perdido).
  IntColumn get feeMinor => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Presupuesto mensual de una categoría de gasto.
///
/// El límite es un monto fijo o un % del saldo (al inicio del mes) de las
/// cuentas incluidas. [alertMonthKey] y [alertMaxThreshold] evitan repetir las
/// alertas de umbral dentro del mismo mes.
@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();

  TextColumn get categoryId => text().references(Categories, #id)();

  TextColumn get limitType => textEnum<BudgetLimitType>()();

  /// Monto en centavos (si [limitType] es `fijo`).
  IntColumn get amountMinor => integer().nullable()();

  /// Porcentaje 1–100 (si [limitType] es `porcentaje`).
  IntColumn get percent => integer().nullable()();

  /// Clave de mes (año*100+mes) del último estado de alertas.
  IntColumn get alertMonthKey => integer().withDefault(const Constant(0))();

  /// Umbral máximo (60/75/90/100) ya avisado en [alertMonthKey].
  IntColumn get alertMaxThreshold => integer().withDefault(const Constant(0))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Reglas de movimientos recurrentes (suscripciones, facturas, salario…).
///
/// Generan [Transactions] normales: automáticas en la recuperación al abrir la
/// app, manuales cuando el usuario marca "Pagar". El anti-duplicado es
/// [nextDueDate], que se avanza al registrar cada cobro.
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `gasto` o `ingreso` (nunca `transferencia`).
  TextColumn get txType => textEnum<TransactionType>()();

  /// `automatica` (importe fijo, se registra sola) o `manual` (importe estimado).
  TextColumn get mode => textEnum<RecurringMode>()();

  /// `diaDelMes` o `cadaNDias`.
  TextColumn get scheduleType => textEnum<RecurringSchedule>()();

  /// Día del mes (1–31) si [scheduleType] es `diaDelMes`.
  IntColumn get dayOfMonth => integer().nullable()();

  /// Intervalo en días (>0) si [scheduleType] es `cadaNDias`.
  IntColumn get intervalDays => integer().nullable()();

  /// Importe en centavos: fijo (automática) o estimado/sugerido (manual).
  IntColumn get amountMinor => integer()();

  TextColumn get accountId => text().references(Accounts, #id)();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Nota por defecto para el movimiento generado.
  TextColumn get note => text().nullable()();

  /// Próximo vencimiento.
  DateTimeColumn get nextDueDate => dateTime()();

  /// Última fecha en que se registró un cobro de esta regla.
  DateTimeColumn get lastPaidDate => dateTime().nullable()();

  /// Permite pausar la regla sin borrarla.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
