import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/balance.dart';

/// Instancia única de la base de datos, cerrada al desecharse.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repositorio: única API de datos para la UI.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(databaseProvider));
});

// ---- Streams de lectura ----

final accountsProvider = StreamProvider<List<AccountRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchAccounts();
});

final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchCategories();
});

final transactionsProvider = StreamProvider<List<TransactionRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchTransactions();
});

final recurringRulesProvider = StreamProvider<List<RecurringRuleRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchRecurringRules();
});

// ---- Derivados ----

/// Saldo (en centavos) por id de cuenta. Se recalcula cuando cambian las
/// cuentas o los movimientos.
final balancesProvider = Provider<Map<String, int>>((ref) {
  final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
  final txns = ref.watch(transactionsProvider).asData?.value ?? const [];

  final entries = txns
      .map((t) => BalanceEntry(
            type: t.type,
            amountMinor: t.amountMinor,
            accountId: t.accountId,
            transferAccountId: t.transferAccountId,
          ))
      .toList(growable: false);

  return {
    for (final a in accounts)
      a.id: computeAccountBalance(
        accountId: a.id,
        initialBalanceMinor: a.initialBalanceMinor,
        entries: entries,
      ),
  };
});

/// Saldo total de la billetera (suma de todas las cuentas).
final totalBalanceProvider = Provider<int>((ref) {
  return computeTotalBalance(ref.watch(balancesProvider));
});

/// Mapa id -> cuenta, para resolver nombres en las listas.
final accountsByIdProvider = Provider<Map<String, AccountRow>>((ref) {
  final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
  return {for (final a in accounts) a.id: a};
});

/// Mapa id -> categoría, para resolver nombre/icono en las listas.
final categoriesByIdProvider = Provider<Map<String, CategoryRow>>((ref) {
  final cats = ref.watch(categoriesProvider).asData?.value ?? const [];
  return {for (final c in cats) c.id: c};
});
