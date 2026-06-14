part of '../app_database.dart';

/// Acceso a la tabla de cuentas. Solo CRUD y streams; el cálculo de saldos
/// vive en el dominio para poder testearlo aislado.
@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// Cuentas activas (no archivadas), ordenadas por fecha de creación.
  Stream<List<AccountRow>> watchActive() {
    return (select(accounts)
          ..where((a) => a.archived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .watch();
  }

  Future<List<AccountRow>> getAll() => select(accounts).get();

  Future<AccountRow?> getById(String id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(AccountsCompanion account) {
    return into(accounts).insertOnConflictUpdate(account);
  }

  /// Archiva una cuenta (no se borra para conservar el historial).
  Future<void> archive(String id, DateTime now) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(archived: const Value(true), updatedAt: Value(now)),
    );
  }
}
