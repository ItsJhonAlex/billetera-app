import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import 'seed_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';
part 'daos/accounts_dao.dart';
part 'daos/categories_dao.dart';
part 'daos/transactions_dao.dart';
part 'daos/recurring_rules_dao.dart';
part 'daos/budgets_dao.dart';

const _uuid = Uuid();

/// Base de datos local de Billetera (SQLite vía Drift).
///
/// El esquema se versiona con [schemaVersion]. Cada cambio futuro de estructura
/// añade un bloque en [migration.onUpgrade] que conserva los datos existentes:
/// así la app se actualiza sin que el usuario pierda información.
@DriftDatabase(
  tables: [Accounts, Categories, Transactions, RecurringRules, Budgets],
  daos: [
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    RecurringRulesDao,
    BudgetsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'billetera'));

  /// Constructor para tests: recibe un ejecutor (p. ej. una DB en memoria).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
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
}
