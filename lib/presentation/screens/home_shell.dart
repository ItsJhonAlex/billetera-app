import 'package:flutter/material.dart';

import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

/// Contenedor principal con barra de navegación inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El botón "+" solo tiene sentido en Inicio y Movimientos.
    final showFab = _index == 0 || _index == 1;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
