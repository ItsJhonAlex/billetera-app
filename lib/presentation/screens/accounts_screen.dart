import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/dashed_button.dart';
import 'account_form_screen.dart';

/// Color de acento por tipo de cuenta.
Color accountAccent(BilleteraTokens t, AccountType type) => switch (type) {
      AccountType.efectivo => t.income,
      AccountType.banco => t.transfer,
      AccountType.tarjeta => t.gold,
      AccountType.otro => t.txm,
    };

/// Lista de cuentas con su saldo, y acciones para crear/editar/archivar.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final balances = ref.watch(balancesProvider);
    final currenciesByCode = ref.watch(currenciesByCodeProvider);
    final currencyCount = accounts.map((a) => a.currency).toSet().length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuentas',
                    style: TextStyle(
                        fontFamily: BilleteraTheme.displayFont,
                        fontSize: 24,
                        color: t.tx1)),
                if (accounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${accounts.length} cuenta${accounts.length == 1 ? '' : 's'} activa${accounts.length == 1 ? '' : 's'} · $currencyCount moneda${currencyCount == 1 ? '' : 's'}',
                      style: TextStyle(color: t.txm, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),
          if (accounts.isEmpty)
            _Empty(onCreate: () => _openForm(context))
          else ...[
            for (final a in accounts)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _AccountTile(
                  account: a,
                  balanceMinor: balances[a.id] ?? a.initialBalanceMinor,
                  symbol: currenciesByCode[a.currency]?.symbol ?? a.currency,
                  onTap: () => _openForm(context, account: a),
                  onLong: () => _confirmArchive(context, ref, a),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: DashedButton(
                label: 'Nueva cuenta',
                onTap: () => _openForm(context),
              ),
            ),
          ],
        ],
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

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.balanceMinor,
    required this.symbol,
    required this.onTap,
    required this.onLong,
  });

  final AccountRow account;
  final int balanceMinor;
  final String symbol;
  final VoidCallback onTap, onLong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = accountAccent(t, account.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLong,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.surface2Gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.bd2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(width: 4, height: 64, color: color),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(account.type.icon, size: 24, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: t.tx1,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${account.type.label} · ${account.currency}',
                        style: TextStyle(color: t.txm, fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                child: Text(
                  Money.grouped(balanceMinor),
                  style: TextStyle(
                      fontFamily: BilleteraTheme.numberFont,
                      color: balanceMinor < 0 ? t.expense : t.tx1,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 10),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.surf2A, t.surfB]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: t.bd3, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.account_balance_wallet, size: 42, color: t.txf),
          ),
          const SizedBox(height: 20),
          Text('Sin cuentas',
              style: TextStyle(
                  color: t.tx1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Crea tu primera cuenta —efectivo, banco o tarjeta— para empezar a '
            'registrar tu dinero.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.txm, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Nueva cuenta'),
          ),
        ],
      ),
    );
  }
}
