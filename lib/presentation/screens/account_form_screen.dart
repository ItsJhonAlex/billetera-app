import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../widgets/amount_field.dart';

/// Crea o edita una cuenta. Si [account] es nulo, crea una nueva.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final AccountRow? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late AccountType _type;
  late bool _includeInBudget;
  String? _currency;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _name = TextEditingController(text: a?.name ?? '');
    _balance = TextEditingController(
      text: a == null ? '' : Money.toUnits(a.initialBalanceMinor).toString(),
    );
    _type = a?.type ?? AccountType.efectivo;
    _includeInBudget = a?.includeInBudget ?? true;
    _currency = a?.currency;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(walletRepositoryProvider);
    final initialMinor = Money.parseExpression(_balance.text) ?? 0;

    final currency = _currency ??
        ref.read(defaultCurrencyProvider)?.code ??
        'CUP';

    if (_isEdit) {
      await repo.updateAccount(widget.account!.copyWith(
        name: _name.text.trim(),
        type: _type,
        initialBalanceMinor: initialMinor,
        includeInBudget: _includeInBudget,
        currency: currency,
      ));
    } else {
      await repo.createAccount(
        name: _name.text.trim(),
        type: _type,
        initialBalanceMinor: initialMinor,
        includeInBudget: _includeInBudget,
        currency: currency,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar cuenta' : 'Nueva cuenta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in AccountType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(t.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final currencies =
                  ref.watch(currenciesProvider).asData?.value ?? const [];
              final defCode = ref.watch(defaultCurrencyProvider)?.code;
              final selected = _currency ?? defCode;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Moneda'),
                items: [
                  for (final c in currencies)
                    DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} — ${c.name}'),
                    ),
                ],
                onChanged: _isEdit
                    ? null // no cambiar la moneda de una cuenta con movimientos
                    : (v) => setState(() => _currency = v),
                disabledHint: selected == null ? null : Text(selected),
              );
            }),
            const SizedBox(height: 16),
            AmountField(
              controller: _balance,
              label: 'Saldo inicial',
              helperText: 'El saldo con el que arranca la cuenta',
              allowEmpty: true,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeInBudget,
              onChanged: (v) => setState(() => _includeInBudget = v),
              title: const Text('Incluir en presupuesto'),
              subtitle: const Text(
                  'Cuenta para el % de los presupuestos. Desactívalo en cuentas '
                  'de ahorro o emergencia.'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Guardar' : 'Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
