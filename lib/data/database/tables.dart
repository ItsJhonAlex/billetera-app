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

  DateTimeColumn get createdAt => dateTime()();
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

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
