part of '../app_database.dart';

/// Acceso a la tabla de monedas.
@DriftAccessor(tables: [Currencies])
class CurrenciesDao extends DatabaseAccessor<AppDatabase>
    with _$CurrenciesDaoMixin {
  CurrenciesDao(super.db);

  Stream<List<CurrencyRow>> watchAll() {
    return (select(currencies)..orderBy([(c) => OrderingTerm.asc(c.code)]))
        .watch();
  }

  Future<List<CurrencyRow>> getAll() => select(currencies).get();

  Future<CurrencyRow?> getDefault() {
    return (select(currencies)..where((c) => c.isDefault.equals(true)))
        .getSingleOrNull();
  }

  Future<void> upsert(CurrenciesCompanion currency) {
    return into(currencies).insertOnConflictUpdate(currency);
  }

  Future<void> insertAll(List<CurrenciesCompanion> rows) async {
    await batch((b) => b.insertAll(currencies, rows));
  }

  /// Marca [code] como predeterminada y desmarca las demás (transacción).
  Future<void> setDefault(String code, DateTime now) {
    return transaction(() async {
      await (update(currencies)).write(
        CurrenciesCompanion(isDefault: const Value(false), updatedAt: Value(now)),
      );
      await (update(currencies)..where((c) => c.code.equals(code))).write(
        CurrenciesCompanion(isDefault: const Value(true), updatedAt: Value(now)),
      );
    });
  }

  Future<void> deleteByCode(String code) {
    return (delete(currencies)..where((c) => c.code.equals(code))).go();
  }
}
