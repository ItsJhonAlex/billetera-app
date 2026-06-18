import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Exporta e importa todos los datos en un único JSON, para mover la app entre
/// teléfonos o restaurar tras reinstalar. Importar **reemplaza** todo.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const _appTag = 'billetera';

  /// Serializa toda la base de datos a un string JSON.
  Future<String> exportJson({required DateTime now}) async {
    final data = {
      'currencies':
          (await _db.select(_db.currencies).get()).map((e) => e.toJson()).toList(),
      'exchangeRates': (await _db.select(_db.exchangeRates).get())
          .map((e) => e.toJson())
          .toList(),
      'categories':
          (await _db.select(_db.categories).get()).map((e) => e.toJson()).toList(),
      'accounts':
          (await _db.select(_db.accounts).get()).map((e) => e.toJson()).toList(),
      'transactions': (await _db.select(_db.transactions).get())
          .map((e) => e.toJson())
          .toList(),
      'recurringRules': (await _db.select(_db.recurringRules).get())
          .map((e) => e.toJson())
          .toList(),
      'budgets':
          (await _db.select(_db.budgets).get()).map((e) => e.toJson()).toList(),
    };
    return jsonEncode({
      'app': _appTag,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': now.toIso8601String(),
      'data': data,
    });
  }

  /// Restaura un backup, reemplazando TODOS los datos actuales. Lanza
  /// [FormatException] con un mensaje legible si el archivo no es válido.
  Future<void> importJson(String raw) async {
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('El archivo no es un backup válido.');
    }

    if (map['app'] != _appTag) {
      throw const FormatException('Este archivo no es un backup de Billetera.');
    }
    if (map['schemaVersion'] != _db.schemaVersion) {
      throw FormatException(
        'El backup es de otra versión de la app (v${map['schemaVersion']}). '
        'Actualiza la app a la misma versión para restaurarlo.',
      );
    }

    final data = map['data'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) =>
        (data[key] as List? ?? const [])
            .cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      // Borrar en orden seguro respecto a las claves foráneas.
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.currencies).go();

      // Insertar en orden de dependencia.
      for (final j in rows('currencies')) {
        await _db.into(_db.currencies).insert(CurrencyRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('exchangeRates')) {
        await _db.into(_db.exchangeRates).insert(ExchangeRateRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('categories')) {
        await _db.into(_db.categories).insert(CategoryRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('accounts')) {
        await _db.into(_db.accounts).insert(AccountRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('transactions')) {
        await _db.into(_db.transactions).insert(TransactionRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('recurringRules')) {
        await _db.into(_db.recurringRules).insert(RecurringRuleRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
      for (final j in rows('budgets')) {
        await _db.into(_db.budgets).insert(BudgetRow.fromJson(j),
            mode: InsertMode.insertOrReplace);
      }
    });
  }
}
