part of '../app_database.dart';

/// Acceso a la tabla de movimientos.
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Todos los movimientos, del más reciente al más antiguo.
  Stream<List<TransactionRow>> watchAll() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// Movimientos donde la cuenta participa, ya sea como origen o destino.
  Stream<List<TransactionRow>> watchByAccount(String accountId) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) | t.transferAccountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> upsert(TransactionsCompanion tx) {
    return into(transactions).insertOnConflictUpdate(tx);
  }

  Future<void> deleteById(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
