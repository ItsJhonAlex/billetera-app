import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../domain/enums.dart';
import '../../domain/transaction_validation.dart';
import '../providers/providers.dart';

/// Formulario para registrar un gasto, ingreso o transferencia.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  TransactionType _type = TransactionType.gasto;
  String? _accountId;
  String? _categoryId;
  String? _transferToId;
  DateTime _date = DateTime.now();

  bool get _isTransfer => _type == TransactionType.transferencia;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amountMinor = Money.parse(_amount.text);
    if (amountMinor == null) return;

    final draft = TransactionDraft(
      type: _type,
      amountMinor: amountMinor,
      accountId: _accountId ?? '',
      categoryId: _isTransfer ? null : _categoryId,
      transferAccountId: _isTransfer ? _transferToId : null,
    );

    try {
      await ref.read(walletRepositoryProvider).createTransaction(
            draft: draft,
            date: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];

    // Categorías filtradas por el tipo de movimiento.
    final kind =
        _type == TransactionType.ingreso ? CategoryKind.ingreso : CategoryKind.gasto;
    final visibleCategories =
        categories.where((c) => c.kind == kind).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: accounts.isEmpty
          ? const _NeedsAccount()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.gasto,
                        label: Text('Gasto'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: TransactionType.ingreso,
                        label: Text('Ingreso'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: TransactionType.transferencia,
                        label: Text('Transf.'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _categoryId = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amount,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Importe',
                      prefixText: r'$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final m = Money.parse(v ?? '');
                      if (m == null) return 'Importe no válido';
                      if (m <= 0) return 'Debe ser mayor que cero';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _accountId,
                    decoration: InputDecoration(
                      labelText: _isTransfer ? 'Cuenta origen' : 'Cuenta',
                    ),
                    items: [
                      for (final a in accounts)
                        DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    validator: (v) => v == null ? 'Selecciona una cuenta' : null,
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  const SizedBox(height: 16),
                  if (_isTransfer)
                    DropdownButtonFormField<String>(
                      initialValue: _transferToId,
                      decoration:
                          const InputDecoration(labelText: 'Cuenta destino'),
                      items: [
                        for (final a in accounts.where((a) => a.id != _accountId))
                          DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      validator: (v) =>
                          v == null ? 'Selecciona la cuenta destino' : null,
                      onChanged: (v) => setState(() => _transferToId = v),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration:
                          const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final c in visibleCategories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(
                                  materialIcon(c.iconCodePoint),
                                  size: 18,
                                  color: Color(c.colorValue),
                                ),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                      ],
                      validator: (v) =>
                          v == null ? 'Selecciona una categoría' : null,
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Fecha'),
                    subtitle:
                        Text(DateFormat('EEEE d MMMM y', 'es').format(_date)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NeedsAccount extends StatelessWidget {
  const _NeedsAccount();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Primero crea una cuenta en la pestaña "Cuentas" para registrar movimientos.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
