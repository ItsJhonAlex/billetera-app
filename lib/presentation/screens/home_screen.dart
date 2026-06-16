import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../providers/providers.dart';
import '../widgets/transaction_tile.dart';
import 'account_form_screen.dart';
import 'summary_screen.dart';

/// Pantalla de inicio: saldo total, tarjetas de cuentas y últimos movimientos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final balances = ref.watch(balancesProvider);
    final total = ref.watch(totalBalanceProvider);
    final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
    final accountsById = ref.watch(accountsByIdProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);

    final recent = txns.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Resumen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _TotalCard(totalMinor: total),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tus cuentas',
                  style: Theme.of(context).textTheme.titleMedium),
              if (accounts.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _addAccount(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            _EmptyAccounts(onCreate: () => _addAccount(context))
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final a = accounts[i];
                  return _AccountMiniCard(
                    name: a.name,
                    balanceMinor: balances[a.id] ?? a.initialBalanceMinor,
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Text('Movimientos recientes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aún no hay movimientos.\nPulsa "+" para añadir uno.',
                    textAlign: TextAlign.center),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final tx in recent)
                    TransactionTile(
                      tx: tx,
                      accountsById: accountsById,
                      categoriesById: categoriesById,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _addAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountFormScreen()),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalMinor});

  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BilleteraTheme.leatherLight, BilleteraTheme.leather],
        ),
        border: Border.all(color: BilleteraTheme.stitchSoft, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: BilleteraTheme.stitch, size: 20),
              const SizedBox(width: 8),
              Text('Saldo total',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: const Color(0xFFB9AE9F))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Money.format(totalMinor),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: totalMinor < 0 ? BilleteraTheme.expense : null,
                ),
          ),
          const SizedBox(height: 4),
          const Text('CUP', style: TextStyle(color: Color(0xFF8A7E72))),
        ],
      ),
    );
  }
}

class _AccountMiniCard extends StatelessWidget {
  const _AccountMiniCard({required this.name, required this.balanceMinor});

  final String name;
  final int balanceMinor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BilleteraTheme.leather,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BilleteraTheme.leatherLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            Money.format(balanceMinor),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: balanceMinor < 0 ? BilleteraTheme.expense : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.add_card, size: 40, color: BilleteraTheme.stitch),
            const SizedBox(height: 12),
            const Text('Crea tu primera cuenta para empezar',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
