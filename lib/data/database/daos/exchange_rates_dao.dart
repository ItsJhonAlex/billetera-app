part of '../app_database.dart';

/// Acceso a la tabla de tasas de cambio.
@DriftAccessor(tables: [ExchangeRates])
class ExchangeRatesDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRatesDaoMixin {
  ExchangeRatesDao(super.db);

  Stream<List<ExchangeRateRow>> watchAll() {
    return (select(exchangeRates)
          ..orderBy([(r) => OrderingTerm.asc(r.fromCode)]))
        .watch();
  }

  Future<List<ExchangeRateRow>> getAll() => select(exchangeRates).get();

  Future<void> upsert(ExchangeRatesCompanion rate) {
    return into(exchangeRates).insertOnConflictUpdate(rate);
  }

  Future<void> deleteById(String id) {
    return (delete(exchangeRates)..where((r) => r.id.equals(id))).go();
  }
}
