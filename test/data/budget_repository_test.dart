import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/data/repositories/wallet_repository.dart';
import 'package:billetera/domain/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  late String catId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WalletRepository(db);
    catId = (await db.categoriesDao.getAll())
        .firstWhere((c) => c.kind == CategoryKind.gasto)
        .id;
  });

  tearDown(() async => db.close());

  test('createAccount respeta includeInBudget', () async {
    final id = await repo.createAccount(
      name: 'Ahorro',
      type: AccountType.banco,
      includeInBudget: false,
    );
    final acc = (await db.accountsDao.getAll()).firstWhere((a) => a.id == id);
    expect(acc.includeInBudget, false);
  });

  test('saveBudget crea y luego edita el mismo presupuesto', () async {
    await repo.saveBudget(
      categoryId: catId,
      limitType: BudgetLimitType.fijo,
      amountMinor: 3000,
    );
    var budgets = await repo.getBudgets();
    expect(budgets.length, 1);
    expect(budgets.single.amountMinor, 3000);

    // Editar (mismo id) -> sigue habiendo uno.
    final id = budgets.single.id;
    await repo.saveBudget(
      id: id,
      categoryId: catId,
      limitType: BudgetLimitType.porcentaje,
      percent: 25,
    );
    budgets = await repo.getBudgets();
    expect(budgets.length, 1);
    expect(budgets.single.limitType, BudgetLimitType.porcentaje);
    expect(budgets.single.percent, 25);
  });

  test('archiveBudget lo quita de los activos', () async {
    await repo.saveBudget(
      categoryId: catId,
      limitType: BudgetLimitType.fijo,
      amountMinor: 1000,
    );
    final id = (await repo.getBudgets()).single.id;
    await repo.archiveBudget(id);
    expect(await repo.getBudgets(), isEmpty);
  });
}
