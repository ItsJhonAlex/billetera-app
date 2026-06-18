import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/balance.dart';
import '../../domain/exchange.dart';

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

/// Servicio de copia de seguridad (exportar/importar JSON).
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
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

final currenciesProvider = StreamProvider<List<CurrencyRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchCurrencies();
});

final exchangeRatesProvider = StreamProvider<List<ExchangeRateRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchExchangeRates();
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
            transferAmountMinor: t.transferAmountMinor,
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

/// Mapa code -> moneda.
final currenciesByCodeProvider = Provider<Map<String, CurrencyRow>>((ref) {
  final list = ref.watch(currenciesProvider).asData?.value ?? const [];
  return {for (final c in list) c.code: c};
});

/// Moneda predeterminada (la marcada; si no hay, la primera). `null` si no hay.
final defaultCurrencyProvider = Provider<CurrencyRow?>((ref) {
  final list = ref.watch(currenciesProvider).asData?.value ?? const [];
  for (final c in list) {
    if (c.isDefault) return c;
  }
  return list.isEmpty ? null : list.first;
});

/// Mapa de tasas "FROM>TO" -> rate, para los conversores.
final ratesMapProvider = Provider<Map<String, double>>((ref) {
  final rates = ref.watch(exchangeRatesProvider).asData?.value ?? const [];
  return {for (final r in rates) rateKey(r.fromCode, r.toCode): r.rate};
});

/// Saldo total convertido a la moneda predeterminada, con las monedas sin tasa.
final totalBalanceProvider = Provider<({int totalMinor, Set<String> missing})>(
  (ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final balances = ref.watch(balancesProvider);
    final def = ref.watch(defaultCurrencyProvider);
    if (def == null) return (totalMinor: 0, missing: <String>{});
    final rates = ref.watch(ratesMapProvider);
    final amounts = accounts.map((a) => (
          currency: a.currency,
          minor: balances[a.id] ?? a.initialBalanceMinor,
        ));
    return totalInDefault(amounts, rates, def.code);
  },
);

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
