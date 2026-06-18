import 'package:billetera/data/database/app_database.dart';
import 'package:billetera/domain/enums.dart';
import 'package:billetera/presentation/providers/providers.dart';
import 'package:billetera/presentation/screens/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Datos falsos para no depender de la base de datos real en los widget tests
// (Drift deja timers pendientes al disponer el scope, que ensucian el test).
final _now = DateTime(2026, 1, 1);

CurrencyRow _cup() => CurrencyRow(
      code: 'CUP',
      name: 'Peso cubano',
      symbol: r'$',
      decimalDigits: 2,
      isDefault: true,
      createdAt: _now,
      updatedAt: _now,
    );

AccountRow _account() => AccountRow(
      id: 'a1',
      name: 'Banco',
      type: AccountType.banco,
      initialBalanceMinor: 50000,
      currency: 'CUP',
      archived: false,
      includeInBudget: true,
      createdAt: _now,
      updatedAt: _now,
    );

Widget _host({required List<AccountRow> accounts}) {
  return ProviderScope(
    overrides: [
      accountsProvider.overrideWith((ref) => Stream.value(accounts)),
      transactionsProvider.overrideWith((ref) => Stream.value(const [])),
      currenciesProvider.overrideWith((ref) => Stream.value([_cup()])),
    ],
    child: const MaterialApp(home: AccountsScreen()),
  );
}

void main() {
  testWidgets('estado vacío cuando no hay cuentas', (t) async {
    await t.pumpWidget(_host(accounts: const []));
    await t.pumpAndSettle();
    expect(find.text('No tienes cuentas todavía.'), findsOneWidget);
  });

  testWidgets('muestra una cuenta con su saldo', (t) async {
    await t.pumpWidget(_host(accounts: [_account()]));
    await t.pumpAndSettle();

    expect(find.text('Banco'), findsOneWidget);
    expect(find.textContaining('500'), findsWidgets); // saldo 500.00
  });
}
