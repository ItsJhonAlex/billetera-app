import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/transaction_validation.dart';
import '../database/app_database.dart';

const _uuid = Uuid();

/// Punto único de acceso a los datos de la billetera.
///
/// Expone streams de lectura (para Riverpod) y métodos de escritura que se
/// encargan de generar ids, marcar `updatedAt` y validar antes de persistir.
/// La UI nunca toca los DAOs directamente.
class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;

  // ---- Lectura (reactiva) ----

  Stream<List<AccountRow>> watchAccounts() => _db.accountsDao.watchActive();
  Stream<List<CategoryRow>> watchCategories() => _db.categoriesDao.watchActive();
  Stream<List<TransactionRow>> watchTransactions() => _db.transactionsDao.watchAll();
  Stream<List<TransactionRow>> watchTransactionsByAccount(String accountId) =>
      _db.transactionsDao.watchByAccount(accountId);

  Future<List<AccountRow>> getAccounts() => _db.accountsDao.getAll();

  // ---- Cuentas ----

  Future<String> createAccount({
    required String name,
    required AccountType type,
    int initialBalanceMinor = 0,
    String currency = 'CUP',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.accountsDao.upsert(AccountsCompanion.insert(
      id: id,
      name: name,
      type: type,
      initialBalanceMinor: Value(initialBalanceMinor),
      currency: Value(currency),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> updateAccount(AccountRow account) {
    return _db.accountsDao.upsert(
      account.copyWith(updatedAt: DateTime.now()).toCompanion(true),
    );
  }

  Future<void> archiveAccount(String id) =>
      _db.accountsDao.archive(id, DateTime.now());

  // ---- Categorías ----

  Future<String> createCategory({
    required String name,
    required CategoryKind kind,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final id = _uuid.v4();
    await _db.categoriesDao.upsert(CategoriesCompanion.insert(
      id: id,
      name: name,
      kind: kind,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      updatedAt: DateTime.now(),
    ));
    return id;
  }

  Future<void> updateCategory(CategoryRow category) {
    return _db.categoriesDao.upsert(
      category.copyWith(updatedAt: DateTime.now()).toCompanion(true),
    );
  }

  Future<void> archiveCategory(String id) =>
      _db.categoriesDao.archive(id, DateTime.now());

  // ---- Movimientos ----

  /// Crea un movimiento. Lanza [ArgumentError] si el borrador no es válido.
  Future<String> createTransaction({
    required TransactionDraft draft,
    required DateTime date,
    String? note,
  }) async {
    final error = validateTransaction(draft);
    if (error != null) throw ArgumentError(error);

    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.transactionsDao.upsert(TransactionsCompanion.insert(
      id: id,
      accountId: draft.accountId,
      categoryId: Value(draft.categoryId),
      type: draft.type,
      amountMinor: draft.amountMinor,
      note: Value(note),
      date: date,
      transferAccountId: Value(draft.transferAccountId),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  /// Edita un movimiento existente. Conserva su [id] y [createdAt] y refresca
  /// `updatedAt`. Lanza [ArgumentError] si el borrador no es válido.
  Future<void> updateTransaction({
    required String id,
    required TransactionDraft draft,
    required DateTime date,
    required DateTime createdAt,
    String? note,
  }) async {
    final error = validateTransaction(draft);
    if (error != null) throw ArgumentError(error);

    await _db.transactionsDao.upsert(TransactionsCompanion.insert(
      id: id,
      accountId: draft.accountId,
      categoryId: Value(draft.categoryId),
      type: draft.type,
      amountMinor: draft.amountMinor,
      note: Value(note),
      date: date,
      transferAccountId: Value(draft.transferAccountId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteTransaction(String id) =>
      _db.transactionsDao.deleteById(id);
}
