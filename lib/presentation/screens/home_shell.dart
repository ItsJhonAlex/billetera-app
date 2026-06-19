import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/notification_service.dart';
import '../providers/budget_providers.dart';
import '../providers/providers.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'recurring_screen.dart';
import 'transactions_screen.dart';

/// Contenedor principal con barra de navegación inferior.
///
/// Ejecuta la recuperación de movimientos recurrentes al iniciar y cada vez que
/// la app vuelve del segundo plano.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    RecurringScreen(),
    BudgetsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runCatchUp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runCatchUp();
  }

  /// Registra los cobros automáticos vencidos desde la última vez.
  Future<void> _runCatchUp() async {
    await ref.read(walletRepositoryProvider).runRecurringCatchUp(DateTime.now());
  }

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reprograma las notificaciones cada vez que cambian las reglas recurrentes
    // (crear, editar, pagar, pausar o borrar).
    ref.listen(recurringRulesProvider, (_, next) {
      final rules = next.asData?.value;
      if (rules != null) NotificationService.instance.syncAll(rules);
    });

    // Evalúa las alertas de presupuesto cuando cambian los movimientos.
    ref.listen(transactionsProvider, (_, next) {
      if (next.asData?.value != null) evaluateBudgetAlerts(ref);
    });

    // El botón "+" de movimientos solo tiene sentido en Inicio y Movimientos.
    final showFab = _index == 0 || _index == 1;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
