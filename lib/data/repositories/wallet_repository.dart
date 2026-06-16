import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';
import '../../domain/recurrence.dart';
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
    bool includeInBudget = true,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.accountsDao.upsert(AccountsCompanion.insert(
      id: id,
      name: name,
      type: type,
      initialBalanceMinor: Value(initialBalanceMinor),
      currency: Value(currency),
      includeInBudget: Value(includeInBudget),
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

  // ---- Reglas recurrentes ----

  Stream<List<RecurringRuleRow>> watchRecurringRules() =>
      _db.recurringRulesDao.watchActive();

  /// Crea una regla recurrente. [start] es la fecha base elegida; el primer
  /// vencimiento se calcula con [firstDueFrom].
  Future<String> createRule({
    required String name,
    required TransactionType txType,
    required RecurringMode mode,
    required RecurringSchedule scheduleType,
    int? dayOfMonth,
    int? intervalDays,
    required int amountMinor,
    required String accountId,
    String? categoryId,
    String? note,
    required DateTime start,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final firstDue = firstDueFrom(
      scheduleType,
      dayOfMonth: dayOfMonth,
      intervalDays: intervalDays,
      start: start,
    );
    await _db.recurringRulesDao.upsert(RecurringRulesCompanion.insert(
      id: id,
      name: name,
      txType: txType,
      mode: mode,
      scheduleType: scheduleType,
      dayOfMonth: Value(dayOfMonth),
      intervalDays: Value(intervalDays),
      amountMinor: amountMinor,
      accountId: accountId,
      categoryId: Value(categoryId),
      note: Value(note),
      nextDueDate: firstDue,
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  /// Edita los datos de una regla. Conserva `nextDueDate` y `lastPaidDate`.
  Future<void> updateRule({
    required String id,
    required String name,
    required TransactionType txType,
    required RecurringMode mode,
    required RecurringSchedule scheduleType,
    int? dayOfMonth,
    int? intervalDays,
    required int amountMinor,
    required String accountId,
    String? categoryId,
    String? note,
  }) async {
    final rule = await _db.recurringRulesDao.getById(id);
    if (rule == null) throw ArgumentError('Regla no encontrada: $id');
    await _db.recurringRulesDao.upsert(rule
        .copyWith(
          name: name,
          txType: txType,
          mode: mode,
          scheduleType: scheduleType,
          dayOfMonth: Value(dayOfMonth),
          intervalDays: Value(intervalDays),
          amountMinor: amountMinor,
          accountId: accountId,
          categoryId: Value(categoryId),
          note: Value(note),
          updatedAt: DateTime.now(),
        )
        .toCompanion(true));
  }

  Future<void> setRuleActive(String id, bool active) {
    return _db.recurringRulesDao.upsert(RecurringRulesCompanion(
      id: Value(id),
      active: Value(active),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> archiveRule(String id) =>
      _db.recurringRulesDao.archive(id, DateTime.now());

  /// Registra el pago de una regla manual (o un cobro puntual): crea el
  /// movimiento, avanza [RecurringRuleRow.nextDueDate] y fija `lastPaidDate`.
  Future<void> payRecurring({
    required String ruleId,
    required int amountMinor,
    required DateTime date,
  }) async {
    final rule = await _db.recurringRulesDao.getById(ruleId);
    if (rule == null) throw ArgumentError('Regla no encontrada: $ruleId');

    await _insertRuleTransaction(rule, amountMinor: amountMinor, date: date);

    final next = advanceAfterPayment(
      rule.scheduleType,
      dayOfMonth: rule.dayOfMonth,
      intervalDays: rule.intervalDays,
      currentDue: rule.nextDueDate,
      paidDate: date,
    );
    await _db.recurringRulesDao.upsert(rule
        .copyWith(
          nextDueDate: next,
          lastPaidDate: Value(date),
          updatedAt: DateTime.now(),
        )
        .toCompanion(true));
  }

  /// Recuperación al abrir la app: registra los cobros vencidos de las reglas
  /// automáticas, uno por cada fecha que tocó, y avanza su vencimiento.
  /// Devuelve cuántos movimientos creó.
  Future<int> runRecurringCatchUp(DateTime now) async {
    final rules = await _db.recurringRulesDao.getActiveAutomatic();
    var created = 0;
    for (final rule in rules) {
      final dates = dueOccurrences(
        nextDue: rule.nextDueDate,
        type: rule.scheduleType,
        dayOfMonth: rule.dayOfMonth,
        intervalDays: rule.intervalDays,
        now: now,
      );
      if (dates.isEmpty) continue;
      for (final d in dates) {
        await _insertRuleTransaction(rule, amountMinor: rule.amountMinor, date: d);
        created++;
      }
      final next = nextDueAfter(
        rule.scheduleType,
        dayOfMonth: rule.dayOfMonth,
        intervalDays: rule.intervalDays,
        from: dates.last,
      );
      await _db.recurringRulesDao.upsert(rule
          .copyWith(
            nextDueDate: next,
            lastPaidDate: Value(dates.last),
            updatedAt: DateTime.now(),
          )
          .toCompanion(true));
    }
    return created;
  }

  // ---- Presupuestos ----

  Stream<List<BudgetRow>> watchBudgets() => _db.budgetsDao.watchActive();

  Future<List<BudgetRow>> getBudgets() => _db.budgetsDao.getActive();

  /// Crea o reemplaza el presupuesto de una categoría.
  Future<void> saveBudget({
    String? id,
    required String categoryId,
    required BudgetLimitType limitType,
    int? amountMinor,
    int? percent,
  }) async {
    final now = DateTime.now();
    await _db.budgetsDao.upsert(BudgetsCompanion.insert(
      id: id ?? _uuid.v4(),
      categoryId: categoryId,
      limitType: limitType,
      amountMinor: Value(amountMinor),
      percent: Value(percent),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> archiveBudget(String id) =>
      _db.budgetsDao.archive(id, DateTime.now());

  /// Persiste el estado de alertas tras evaluarlas (Fase B).
  Future<void> updateBudgetAlertState(
    BudgetRow budget, {
    required int alertMonthKey,
    required int alertMaxThreshold,
  }) {
    return _db.budgetsDao.upsert(budget
        .copyWith(
          alertMonthKey: alertMonthKey,
          alertMaxThreshold: alertMaxThreshold,
          updatedAt: DateTime.now(),
        )
        .toCompanion(true));
  }

  /// Inserta el movimiento que genera una regla (gasto o ingreso).
  Future<void> _insertRuleTransaction(
    RecurringRuleRow rule, {
    required int amountMinor,
    required DateTime date,
  }) {
    final now = DateTime.now();
    return _db.transactionsDao.upsert(TransactionsCompanion.insert(
      id: _uuid.v4(),
      accountId: rule.accountId,
      categoryId: Value(rule.categoryId),
      type: rule.txType,
      amountMinor: amountMinor,
      note: Value(rule.note),
      date: date,
      createdAt: now,
      updatedAt: now,
    ));
  }
}
