part of '../app_database.dart';

/// Acceso a la tabla de categorías.
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Categorías activas, ordenadas por nombre.
  Stream<List<CategoryRow>> watchActive() {
    return (select(categories)
          ..where((c) => c.archived.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<List<CategoryRow>> getAll() => select(categories).get();

  Future<int> count() async {
    final countExp = categories.id.count();
    final query = selectOnly(categories)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> upsert(CategoriesCompanion category) {
    return into(categories).insertOnConflictUpdate(category);
  }

  /// Inserta varias categorías de una vez (usado en la siembra inicial).
  Future<void> insertAll(List<CategoriesCompanion> items) async {
    await batch((b) => b.insertAll(categories, items));
  }

  Future<void> archive(String id, DateTime now) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(archived: const Value(true), updatedAt: Value(now)),
    );
  }
}
