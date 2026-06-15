import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/data/repositories/wallet_repository.dart';
import 'package:billetera/domain/balance.dart';
import 'package:billetera/domain/enums.dart';
import 'package:billetera/domain/transaction_validation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WalletRepository(db);
  });

  tearDown(() async => db.close());

  test('siembra categorías por defecto al crear la base', () async {
    final cats = await db.categoriesDao.getAll();
    expect(cats, isNotEmpty);
    expect(cats.any((c) => c.kind == CategoryKind.gasto), isTrue);
    expect(cats.any((c) => c.kind == CategoryKind.ingreso), isTrue);
  });

  test('un gasto reduce el saldo calculado de la cuenta', () async {
    final accId = await repo.createAccount(
      name: 'Efectivo',
      type: AccountType.efectivo,
      initialBalanceMinor: 10000,
    );
    final cat = (await db.categoriesDao.getAll())
        .firstWhere((c) => c.kind == CategoryKind.gasto);

    await repo.createTransaction(
      draft: TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 2500,
        accountId: accId,
        categoryId: cat.id,
      ),
      date: DateTime(2026, 1, 1),
    );

    final txns = await db.transactionsDao.watchAll().first;
    final balance = computeAccountBalance(
      accountId: accId,
      initialBalanceMinor: 10000,
      entries: txns.map((t) => BalanceEntry(
            type: t.type,
            amountMinor: t.amountMinor,
            accountId: t.accountId,
            transferAccountId: t.transferAccountId,
          )),
    );
    expect(balance, 7500);
  });

  test('una transferencia mueve dinero entre cuentas sin perderlo', () async {
    final a = await repo.createAccount(
        name: 'Banco', type: AccountType.banco, initialBalanceMinor: 5000);
    final b = await repo.createAccount(
        name: 'Efectivo', type: AccountType.efectivo);

    await repo.createTransaction(
      draft: TransactionDraft(
        type: TransactionType.transferencia,
        amountMinor: 2000,
        accountId: a,
        transferAccountId: b,
      ),
      date: DateTime(2026, 1, 1),
    );

    final txns = await db.transactionsDao.watchAll().first;
    final entries = txns.map((t) => BalanceEntry(
          type: t.type,
          amountMinor: t.amountMinor,
          accountId: t.accountId,
          transferAccountId: t.transferAccountId,
        ));
    final saldoA = computeAccountBalance(
        accountId: a, initialBalanceMinor: 5000, entries: entries);
    final saldoB = computeAccountBalance(
        accountId: b, initialBalanceMinor: 0, entries: entries);

    expect(saldoA, 3000);
    expect(saldoB, 2000);
  });

  test('editar un movimiento cambia el importe y recalcula el saldo', () async {
    final accId = await repo.createAccount(
      name: 'Efectivo',
      type: AccountType.efectivo,
      initialBalanceMinor: 10000,
    );
    final cat = (await db.categoriesDao.getAll())
        .firstWhere((c) => c.kind == CategoryKind.gasto);

    final txId = await repo.createTransaction(
      draft: TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 2500,
        accountId: accId,
        categoryId: cat.id,
      ),
      date: DateTime(2026, 1, 1),
    );

    final original =
        (await db.transactionsDao.watchAll().first).single;

    // Editar: subir el gasto de 2500 a 4000.
    await repo.updateTransaction(
      id: txId,
      createdAt: original.createdAt,
      draft: TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 4000,
        accountId: accId,
        categoryId: cat.id,
      ),
      date: DateTime(2026, 1, 1),
      note: 'corregido',
    );

    final txns = await db.transactionsDao.watchAll().first;
    expect(txns.length, 1, reason: 'no debe duplicar el movimiento');
    final updated = txns.single;
    expect(updated.id, txId);
    expect(updated.amountMinor, 4000);
    expect(updated.note, 'corregido');
    expect(updated.createdAt, original.createdAt);

    final balance = computeAccountBalance(
      accountId: accId,
      initialBalanceMinor: 10000,
      entries: txns.map((t) => BalanceEntry(
            type: t.type,
            amountMinor: t.amountMinor,
            accountId: t.accountId,
            transferAccountId: t.transferAccountId,
          )),
    );
    expect(balance, 6000);
  });

  test('rechaza un movimiento inválido', () async {
    final a = await repo.createAccount(
        name: 'Caja', type: AccountType.efectivo);
    expect(
      () => repo.createTransaction(
        draft: TransactionDraft(
          type: TransactionType.gasto,
          amountMinor: 100,
          accountId: a,
          // sin categoría -> inválido
        ),
        date: DateTime(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });
}
