import 'package:billetera/data/backup/backup_service.dart';
import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/data/repositories/wallet_repository.dart';
import 'package:billetera/domain/enums.dart';
import 'package:billetera/domain/transaction_validation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;
  late BackupService backup;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WalletRepository(db);
    backup = BackupService(db);
  });

  tearDown(() async => db.close());

  test('round-trip: exportar y reimportar reemplaza y conserva los datos',
      () async {
    final accId = await repo.createAccount(
        name: 'Banco', type: AccountType.banco, initialBalanceMinor: 50000);
    final cat = (await db.categoriesDao.getAll())
        .firstWhere((c) => c.kind == CategoryKind.gasto);
    await repo.createTransaction(
      draft: TransactionDraft(
        type: TransactionType.gasto,
        amountMinor: 1234,
        accountId: accId,
        categoryId: cat.id,
      ),
      date: DateTime(2026, 3, 1),
      note: 'café',
    );

    final json = await backup.exportJson(now: DateTime(2026, 6, 17));

    // Cambiar el estado: una cuenta extra que NO debe sobrevivir al import.
    await repo.createAccount(name: 'Extra', type: AccountType.efectivo);
    expect((await db.accountsDao.getAll()).length, 2);

    await backup.importJson(json);

    final accounts = await db.accountsDao.getAll();
    expect(accounts.length, 1, reason: 'el import reemplaza todo');
    expect(accounts.single.name, 'Banco');
    expect(accounts.single.initialBalanceMinor, 50000);

    final txns = await db.transactionsDao.watchAll().first;
    expect(txns.length, 1);
    expect(txns.single.amountMinor, 1234);
    expect(txns.single.note, 'café');
  });

  test('importJson rechaza un archivo que no es de Billetera', () async {
    expect(
      () => backup.importJson('{"app":"otra","schemaVersion":4,"data":{}}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('importJson rechaza otra versión de esquema', () async {
    expect(
      () => backup.importJson('{"app":"billetera","schemaVersion":999,"data":{}}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('importJson rechaza texto inválido', () async {
    expect(
      () => backup.importJson('no es json'),
      throwsA(isA<FormatException>()),
    );
  });
}
