import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/notifications/notification_service.dart';
import '../../domain/balance.dart';
import '../../domain/budget.dart';
import '../../domain/enums.dart';
import 'providers.dart';

/// Estado de un presupuesto para la UI: límite y gastado del mes en curso.
typedef BudgetStatus = ({BudgetRow budget, int limitMinor, int spentMinor});

final budgetsProvider = StreamProvider<List<BudgetRow>>((ref) {
  return ref.watch(walletRepositoryProvider).watchBudgets();
});

/// Saldo base para los presupuestos por % = suma del saldo (al inicio del mes
/// en curso) de las cuentas marcadas como incluidas.
final budgetBaseBalanceProvider = Provider<int>((ref) {
  final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
  final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final entriesBefore = txns
      .where((t) => t.date.isBefore(monthStart))
      .map((t) => BalanceEntry(
            type: t.type,
            amountMinor: t.amountMinor,
            accountId: t.accountId,
            transferAccountId: t.transferAccountId,
          ))
      .toList(growable: false);

  var base = 0;
  for (final a in accounts.where((a) => a.includeInBudget)) {
    base += computeAccountBalance(
      accountId: a.id,
      initialBalanceMinor: a.initialBalanceMinor,
      entries: entriesBefore,
    );
  }
  return base;
});

/// Estados de todos los presupuestos para el mes en curso.
final budgetStatusesProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider).asData?.value ?? const [];
  if (budgets.isEmpty) return const [];

  final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
  final base = ref.watch(budgetBaseBalanceProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);

  int spentFor(String categoryId) {
    var spent = 0;
    for (final t in txns) {
      if (t.type == TransactionType.gasto &&
          t.categoryId == categoryId &&
          !t.date.isBefore(monthStart) &&
          t.date.isBefore(nextMonth)) {
        spent += t.amountMinor;
      }
    }
    return spent;
  }

  return [
    for (final b in budgets)
      (
        budget: b,
        limitMinor: resolveLimitMinor(
          type: b.limitType,
          amountMinor: b.amountMinor,
          percent: b.percent,
          baseBalanceMinor: base,
        ),
        spentMinor: spentFor(b.categoryId),
      ),
  ];
});

/// Evalúa los presupuestos y dispara una notificación por cada umbral
/// (60/75/90/100%) recién cruzado este mes; persiste el estado para no repetir.
/// Se llama al cambiar los movimientos.
Future<void> evaluateBudgetAlerts(WidgetRef ref) async {
  final statuses = ref.read(budgetStatusesProvider);
  if (statuses.isEmpty) return;
  final catsById = ref.read(categoriesByIdProvider);
  final repo = ref.read(walletRepositoryProvider);
  final mk = monthKey(DateTime.now());

  for (final s in statuses) {
    final pct = consumedPct(s.spentMinor, s.limitMinor);
    final decision = evaluateAlerts(
      pct: pct,
      alertMonthKey: s.budget.alertMonthKey,
      alertMaxThreshold: s.budget.alertMaxThreshold,
      currentMonthKey: mk,
    );

    for (final threshold in decision.toNotify) {
      await NotificationService.instance.showBudgetAlert(
        budgetId: s.budget.id,
        categoryName: catsById[s.budget.categoryId]?.name ?? 'Categoría',
        threshold: threshold,
      );
    }

    final monthChanged = s.budget.alertMonthKey != mk;
    if (decision.toNotify.isNotEmpty ||
        (monthChanged && s.budget.alertMaxThreshold != 0)) {
      await repo.updateBudgetAlertState(
        s.budget,
        alertMonthKey: mk,
        alertMaxThreshold: decision.newMaxThreshold,
      );
    }
  }
}
