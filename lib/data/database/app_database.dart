import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import 'seed_categories.dart';
import 'seed_currencies.dart';
import 'tables.dart';

part 'app_database.g.dart';
part 'daos/accounts_dao.dart';
part 'daos/categories_dao.dart';
part 'daos/transactions_dao.dart';
part 'daos/recurring_rules_dao.dart';
part 'daos/budgets_dao.dart';
part 'daos/currencies_dao.dart';
part 'daos/exchange_rates_dao.dart';

const _uuid = Uuid();

/// Base de datos local de Billetera (SQLite vía Drift).
///
/// El esquema se versiona con [schemaVersion]. Cada cambio futuro de estructura
/// añade un bloque en [migration.onUpgrade] que conserva los datos existentes:
/// así la app se actualiza sin que el usuario pierda información.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    RecurringRules,
    Budgets,
    Currencies,
    ExchangeRates,
  ],
  daos: [
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    RecurringRulesDao,
    BudgetsDao,
    CurrenciesDao,
    ExchangeRatesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'billetera'));

  /// Constructor para tests: recibe un ejecutor (p. ej. una DB en memoria).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
          await _seedDefaultCurrencies();
        },
        onUpgrade: (m, from, to) async {
          // v2: reglas de movimientos recurrentes. Conserva los datos previos.
          if (from < 2) {
            await m.createTable(recurringRules);
          }
          // v3: presupuestos por categoría + cuentas incluidas en el % .
          if (from < 3) {
            await m.addColumn(accounts, accounts.includeInBudget);
            await m.createTable(budgets);
          }
          // v4: multimoneda (monedas, tasas y montos de transferencia).
          if (from < 4) {
            await m.createTable(currencies);
            await m.createTable(exchangeRates);
            await m.addColumn(transactions, transactions.transferAmountMinor);
            await m.addColumn(transactions, transactions.feeMinor);
            await _seedDefaultCurrencies();
          }
          // NUNCA borres datos aquí.
        },
      );

  /// Inserta las categorías por defecto en el primer arranque.
  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    final companions = kDefaultCategories
        .map((c) => CategoriesCompanion.insert(
              id: _uuid.v4(),
              name: c.name,
              kind: c.kind,
              iconCodePoint: c.icon.codePoint,
              colorValue: c.color.toARGB32(),
              isDefault: const Value(true),
              updatedAt: now,
            ))
        .toList();
    await categoriesDao.insertAll(companions);
  }

  /// Inserta las monedas por defecto (CUP predeterminada, USD, EUR).
  Future<void> _seedDefaultCurrencies() async {
    final now = DateTime.now();
    await currenciesDao.insertAll(
      kDefaultCurrencies
          .map((c) => CurrenciesCompanion.insert(
                code: c.code,
                name: c.name,
                symbol: c.symbol,
                isDefault: Value(c.isDefault),
                createdAt: now,
                updatedAt: now,
              ))
          .toList(),
    );
  }
}
