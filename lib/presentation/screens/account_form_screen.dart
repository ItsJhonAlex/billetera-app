import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';

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
    final initialMinor = Money.parse(_balance.text) ?? 0;

    if (_isEdit) {
      await repo.updateAccount(widget.account!.copyWith(
        name: _name.text.trim(),
        type: _type,
        initialBalanceMinor: initialMinor,
      ));
    } else {
      await repo.createAccount(
        name: _name.text.trim(),
        type: _type,
        initialBalanceMinor: initialMinor,
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
          padding: const EdgeInsets.all(16),
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
            TextFormField(
              controller: _balance,
              decoration: const InputDecoration(
                labelText: 'Saldo inicial',
                prefixText: r'$ ',
                helperText: 'El saldo con el que arranca la cuenta',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // 0 por defecto
                return Money.parse(v) == null ? 'Importe no válido' : null;
              },
            ),
            const SizedBox(height: 24),
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
