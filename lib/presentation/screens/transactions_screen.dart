import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../providers/providers.dart';
import '../widgets/transaction_tile.dart';

/// Historial completo de movimientos.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider);
    final accountsById = ref.watch(accountsByIdProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txns) {
          if (txns.isEmpty) {
            return const Center(
              child: Text('Aún no hay movimientos.\nPulsa "+" para añadir uno.',
                  textAlign: TextAlign.center),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            itemCount: txns.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final tx = txns[i];
              return TransactionTile(
                tx: tx,
                accountsById: accountsById,
                categoriesById: categoriesById,
                onTap: () => _showActions(context, ref, tx),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showActions(
      BuildContext context, WidgetRef ref, TransactionRow tx) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar movimiento'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );
    if (action == 'delete') {
      await ref.read(walletRepositoryProvider).deleteTransaction(tx.id);
    }
  }
}
