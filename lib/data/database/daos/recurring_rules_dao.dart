part of '../app_database.dart';

/// Acceso a la tabla de reglas recurrentes.
@DriftAccessor(tables: [RecurringRules])
class RecurringRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRulesDaoMixin {
  RecurringRulesDao(super.db);

  /// Reglas no archivadas, ordenadas por próximo vencimiento.
  Stream<List<RecurringRuleRow>> watchActive() {
    return (select(recurringRules)
          ..where((r) => r.archived.equals(false))
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
        .watch();
  }

  /// Todas las reglas automáticas activas (para la recuperación al abrir).
  Future<List<RecurringRuleRow>> getActiveAutomatic() {
    return (select(recurringRules)
          ..where((r) =>
              r.archived.equals(false) &
              r.active.equals(true) &
              r.mode.equalsValue(RecurringMode.automatica)))
        .get();
  }

  Future<RecurringRuleRow?> getById(String id) {
    return (select(recurringRules)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsert(RecurringRulesCompanion rule) {
    return into(recurringRules).insertOnConflictUpdate(rule);
  }

  Future<void> archive(String id, DateTime now) {
    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        archived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }
}
