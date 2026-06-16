import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/data/repositories/wallet_repository.dart';
import 'package:billetera/domain/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  late String accId;
  late String catId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WalletRepository(db);
    accId = await repo.createAccount(
        name: 'Banco', type: AccountType.banco, initialBalanceMinor: 100000);
    catId = (await db.categoriesDao.getAll())
        .firstWhere((c) => c.kind == CategoryKind.gasto)
        .id;
  });

  tearDown(() async => db.close());

  test('createRule calcula el primer vencimiento (día del mes)', () async {
    final id = await repo.createRule(
      name: 'Luz',
      txType: TransactionType.gasto,
      mode: RecurringMode.manual,
      scheduleType: RecurringSchedule.diaDelMes,
      dayOfMonth: 5,
      amountMinor: 3000,
      accountId: accId,
      categoryId: catId,
      start: DateTime(2026, 6, 10), // ya pasó el 5 -> julio 5
    );
    final rule = await db.recurringRulesDao.getById(id);
    expect(rule!.nextDueDate, DateTime(2026, 7, 5));
  });

  test('payRecurring crea el movimiento y avanza el vencimiento', () async {
    final id = await repo.createRule(
      name: 'Luz',
      txType: TransactionType.gasto,
      mode: RecurringMode.manual,
      scheduleType: RecurringSchedule.diaDelMes,
      dayOfMonth: 5,
      amountMinor: 3000, // estimado
      accountId: accId,
      categoryId: catId,
      start: DateTime(2026, 6, 1), // primer vencimiento 5 jun
    );

    await repo.payRecurring(
      ruleId: id,
      amountMinor: 3450, // monto real ajustado
      date: DateTime(2026, 6, 5),
    );

    final txns = await db.transactionsDao.watchAll().first;
    expect(txns.length, 1);
    expect(txns.single.amountMinor, 3450);
    expect(txns.single.type, TransactionType.gasto);

    final rule = await db.recurringRulesDao.getById(id);
    expect(rule!.nextDueDate, DateTime(2026, 7, 5));
    expect(rule.lastPaidDate, DateTime(2026, 6, 5));
  });

  test('runRecurringCatchUp registra cada cobro automático perdido', () async {
    final id = await repo.createRule(
      name: 'Netflix',
      txType: TransactionType.gasto,
      mode: RecurringMode.automatica,
      scheduleType: RecurringSchedule.diaDelMes,
      dayOfMonth: 5,
      amountMinor: 500,
      accountId: accId,
      categoryId: catId,
      start: DateTime(2026, 4, 1), // primer vencimiento 5 abr
    );

    final created = await repo.runRecurringCatchUp(DateTime(2026, 6, 20));

    expect(created, 3); // abr, may, jun
    final txns = await db.transactionsDao.watchAll().first;
    expect(txns.length, 3);
    expect(txns.every((t) => t.amountMinor == 500), isTrue);

    final rule = await db.recurringRulesDao.getById(id);
    expect(rule!.nextDueDate, DateTime(2026, 7, 5));
    expect(rule.lastPaidDate, DateTime(2026, 6, 5));
  });

  test('catch-up NO toca las reglas manuales', () async {
    await repo.createRule(
      name: 'Luz',
      txType: TransactionType.gasto,
      mode: RecurringMode.manual,
      scheduleType: RecurringSchedule.diaDelMes,
      dayOfMonth: 5,
      amountMinor: 3000,
      accountId: accId,
      categoryId: catId,
      start: DateTime(2026, 1, 1),
    );

    final created = await repo.runRecurringCatchUp(DateTime(2026, 6, 20));

    expect(created, 0);
    expect(await db.transactionsDao.watchAll().first, isEmpty);
  });

  test('catch-up sin nada vencido no crea movimientos', () async {
    await repo.createRule(
      name: 'Netflix',
      txType: TransactionType.gasto,
      mode: RecurringMode.automatica,
      scheduleType: RecurringSchedule.cadaNDias,
      intervalDays: 30,
      amountMinor: 500,
      accountId: accId,
      categoryId: catId,
      start: DateTime(2026, 6, 25),
    );

    final created = await repo.runRecurringCatchUp(DateTime(2026, 6, 20));
    expect(created, 0);
  });
}
