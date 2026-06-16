part of '../app_database.dart';

/// Acceso a la tabla de presupuestos.
@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  /// Presupuestos no archivados.
  Stream<List<BudgetRow>> watchActive() {
    return (select(budgets)..where((b) => b.archived.equals(false))).watch();
  }

  Future<List<BudgetRow>> getActive() {
    return (select(budgets)..where((b) => b.archived.equals(false))).get();
  }

  Future<BudgetRow?> getById(String id) {
    return (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(BudgetsCompanion budget) {
    return into(budgets).insertOnConflictUpdate(budget);
  }

  Future<void> archive(String id, DateTime now) {
    return (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(archived: const Value(true), updatedAt: Value(now)),
    );
  }
}
