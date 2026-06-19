import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tx_row.dart';
import 'account_form_screen.dart';
import 'summary_screen.dart';

/// Pantalla de inicio con el diseño "cartera de cuero": top bar, hero de saldo,
/// carrusel de cuentas y movimientos recientes.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final balances = ref.watch(balancesProvider);
    final total = ref.watch(totalBalanceProvider);
    final txns = ref.watch(transactionsProvider).asData?.value ?? const [];
    final accountsById = ref.watch(accountsByIdProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);
    final currenciesByCode = ref.watch(currenciesByCodeProvider);
    final defaultCode = ref.watch(defaultCurrencyProvider)?.code ?? 'CUP';

    final recent = txns.take(6).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) => ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _TopBar(
              onMenu: () => Scaffold.of(context).openDrawer(),
              onToggleTheme: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
              onSummary: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SummaryScreen()),
              ),
              isDark: ref.watch(themeModeProvider) == ThemeMode.dark,
            ),
            _BalanceHero(
              totalMinor: total.totalMinor,
              currencyCode: defaultCode,
              accountCount: accounts.length,
              missing: total.missing,
            ),
            const SizedBox(height: 8),
            _SectionHeader(
              title: 'Tus cuentas',
              actionLabel: accounts.isEmpty ? null : 'Ver todas',
              onAction: () => _goAccounts(context),
            ),
            if (accounts.isEmpty)
              _EmptyAccounts(onCreate: () => _addAccount(context))
            else
              SizedBox(
                height: 116,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
                  children: [
                    for (final a in accounts) ...[
                      _AccountCard(
                        account: a,
                        balanceMinor: balances[a.id] ?? a.initialBalanceMinor,
                        symbol: currenciesByCode[a.currency]?.symbol ?? a.currency,
                      ),
                      const SizedBox(width: 12),
                    ],
                    _NewAccountCard(onTap: () => _addAccount(context)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Movimientos recientes',
              actionLabel: recent.isEmpty ? null : 'Ver todos',
              onAction: () {}, // la pestaña Movimientos está en la barra inferior
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Center(
                  child: Text(
                    'Aún no hay movimientos.\nPulsa "+" para añadir uno.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.txm),
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: t.surfaceGradient,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: t.bd1),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      TxRow(
                        tx: recent[i],
                        accountsById: accountsById,
                        categoriesById: categoriesById,
                        showDivider: i != recent.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addAccount(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AccountFormScreen()),
      );

  void _goAccounts(BuildContext context) {
    // Inicio y Cuentas son pestañas hermanas; aquí abrimos el formulario rápido
    // no aplica. Dejamos el acceso por la barra inferior.
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onMenu,
    required this.onToggleTheme,
    required this.onSummary,
    required this.isDark,
  });

  final VoidCallback onMenu, onToggleTheme, onSummary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: Icon(Icons.menu, color: t.tx1),
          ),
          const Spacer(),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.bd3, t.surfA]),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: t.bd3),
            ),
            alignment: Alignment.center,
            child: Text('B',
                style: TextStyle(
                    fontFamily: BilleteraTheme.displayFont,
                    fontWeight: FontWeight.w600,
                    color: t.gold,
                    fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Text('Billetera',
              style: TextStyle(
                  fontFamily: BilleteraTheme.displayFont,
                  fontSize: 19,
                  color: t.tx1)),
          const Spacer(),
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: t.tx1, size: 22),
          ),
          IconButton(
            onPressed: onSummary,
            icon: Icon(Icons.bar_chart, color: t.tx1),
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.totalMinor,
    required this.currencyCode,
    required this.accountCount,
    required this.missing,
  });

  final int totalMinor;
  final String currencyCode;
  final int accountCount;
  final Set<String> missing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.leatherGradient,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.bd3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cosido dorado punteado.
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: t.gold.withValues(alpha: 0.38),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: t.gold),
                  const SizedBox(width: 7),
                  Text('SALDO TOTAL',
                      style: TextStyle(
                          color: t.tx3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      Money.grouped(totalMinor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: BilleteraTheme.numberFont,
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: t.txBright,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(currencyCode,
                      style: TextStyle(
                          fontFamily: BilleteraTheme.numberFont,
                          fontSize: 17,
                          color: t.tx3,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 15, color: t.txm),
                  const SizedBox(width: 6),
                  Text('$accountCount cuentas',
                      style: TextStyle(
                          color: t.txm,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500)),
                  if (missing.isNotEmpty) ...[
                    Text('  ·  ', style: TextStyle(color: t.txf)),
                    Flexible(
                      child: Text('faltan tasas: ${missing.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 10),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: t.tx1, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(actionLabel!,
                      style: TextStyle(
                          color: t.gold,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 15, color: t.gold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Color asociado a un tipo de cuenta, para los acentos.
Color _accountColor(BilleteraTokens t, AccountType type) => switch (type) {
      AccountType.efectivo => t.income,
      AccountType.banco => t.transfer,
      AccountType.tarjeta => t.gold,
      AccountType.otro => t.txm,
    };

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balanceMinor,
    required this.symbol,
  });

  final AccountRow account;
  final int balanceMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = _accountColor(t, account.type);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.surface2Gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.bd2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(account.type.icon, size: 19, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: t.chip,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(account.currency,
                    style: TextStyle(
                        fontFamily: BilleteraTheme.numberFont,
                        fontSize: 10.5,
                        color: t.txm,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: t.tx2, fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(Money.grouped(balanceMinor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: BilleteraTheme.numberFont,
                  color: balanceMinor < 0 ? t.expense : t.tx1,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

class _NewAccountCard extends StatelessWidget {
  const _NewAccountCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.bd3, width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 24, color: t.gold),
            const SizedBox(height: 7),
            Text('Nueva',
                style: TextStyle(
                    color: t.txm, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: t.surfaceGradient),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.bd1),
      ),
      child: Column(
        children: [
          Icon(Icons.add_card, size: 40, color: t.gold),
          const SizedBox(height: 12),
          Text('Crea tu primera cuenta para empezar',
              textAlign: TextAlign.center, style: TextStyle(color: t.tx2)),
          const SizedBox(height: 12),
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
