import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';
import 'account_form_screen.dart';

/// Lista de cuentas con su saldo, y acciones para crear/editar/archivar.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final balances = ref.watch(balancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: accounts.isEmpty
          ? const Center(child: Text('No tienes cuentas todavía.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = accounts[i];
                final balance = balances[a.id] ?? a.initialBalanceMinor;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(a.type.icon)),
                    title: Text(a.name),
                    subtitle: Text(a.type.label),
                    trailing: Text(
                      Money.format(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: balance < 0 ? Colors.redAccent : null,
                      ),
                    ),
                    onTap: () => _openForm(context, account: a),
                    onLongPress: () => _confirmArchive(context, ref, a),
                  ),
                );
              },
            ),
    );
  }

  void _openForm(BuildContext context, {AccountRow? account}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountFormScreen(account: account)),
    );
  }

  Future<void> _confirmArchive(
      BuildContext context, WidgetRef ref, AccountRow account) async {
    final ok = await confirmDialog(
      context,
      title: '¿Archivar "${account.name}"?',
      message:
          'La cuenta se ocultará pero su historial de movimientos se conserva.',
      confirmLabel: 'Archivar',
      destructive: false,
    );
    if (ok) {
      await ref.read(walletRepositoryProvider).archiveAccount(account.id);
    }
  }
}
