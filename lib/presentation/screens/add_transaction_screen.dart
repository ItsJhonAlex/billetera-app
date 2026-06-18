import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../../domain/exchange.dart';
import '../../domain/transaction_validation.dart';
import '../providers/providers.dart';
import '../widgets/amount_field.dart';

/// Formulario para registrar o editar un gasto, ingreso o transferencia.
/// Si [existing] no es nulo, edita ese movimiento en lugar de crear uno nuevo.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.existing});

  final TransactionRow? existing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _fee = TextEditingController();
  final _received = TextEditingController();

  TransactionType _type = TransactionType.gasto;
  String? _accountId;
  String? _categoryId;
  String? _transferToId;
  String? _currencyFilter; // moneda elegida en gasto/ingreso (filtra cuentas)
  DateTime _date = DateTime.now();
  bool _feeIsPercent = false;

  bool get _isTransfer => _type == TransactionType.transferencia;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    if (tx != null) {
      _type = tx.type;
      _amount.text = Money.toUnits(tx.amountMinor).toString();
      _note.text = tx.note ?? '';
      _accountId = tx.accountId;
      _categoryId = tx.categoryId;
      _transferToId = tx.transferAccountId;
      _date = tx.date;
      if (tx.feeMinor != null) _fee.text = Money.toUnits(tx.feeMinor!).toString();
      if (tx.transferAmountMinor != null) {
        _received.text = Money.toUnits(tx.transferAmountMinor!).toString();
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _fee.dispose();
    _received.dispose();
    super.dispose();
  }

  /// Moneda de una cuenta por id.
  String _currencyOf(String? accountId) {
    final acc = ref.read(accountsByIdProvider)[accountId];
    return acc?.currency ?? ref.read(defaultCurrencyProvider)?.code ?? 'CUP';
  }

  bool get _isCrossCurrency =>
      _isTransfer &&
      _accountId != null &&
      _transferToId != null &&
      _currencyOf(_accountId) != _currencyOf(_transferToId);

  /// Comisión en centavos (moneda origen). Si es %, sobre [amountMinor].
  int? _computeFeeMinor(int amountMinor) {
    final text = _fee.text.trim();
    if (text.isEmpty) return null;
    if (_feeIsPercent) {
      final pct = double.tryParse(text.replaceAll(',', '.'));
      if (pct == null) return null;
      return (amountMinor * pct / 100).round();
    }
    return Money.parseExpression(text);
  }

  /// Convierte el neto (origen) a la moneda destino con la tasa definida.
  int? _convertedNet(int net) {
    final from = _currencyOf(_accountId);
    final to = _currencyOf(_transferToId);
    if (from == to) return net;
    final def = ref.read(defaultCurrencyProvider)?.code ?? 'CUP';
    return convertMinor(net, from, to, ref.read(ratesMapProvider), def);
  }

  /// Campo de comisión: valor + selector Monto/% .
  Widget _buildFeeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _fee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Comisión (opcional)',
              prefixText: _feeIsPercent ? null : r'$ ',
              suffixText: _feeIsPercent ? '%' : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('Monto')),
            ButtonSegment(value: true, label: Text('%')),
          ],
          selected: {_feeIsPercent},
          onSelectionChanged: (s) => setState(() => _feeIsPercent = s.first),
        ),
      ],
    );
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

  /// Saldo disponible de una cuenta para validar. Al editar, devuelve el efecto
  /// del movimiento original sobre esa cuenta para no dar falsos negativos.
  int _availableBalance(String accountId) {
    var available = ref.read(balancesProvider)[accountId] ?? 0;
    final ex = widget.existing;
    if (ex != null &&
        ex.accountId == accountId &&
        (ex.type == TransactionType.gasto ||
            ex.type == TransactionType.transferencia)) {
      available += ex.amountMinor; // lo que ya había restado este movimiento
    }
    return available;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amountMinor = Money.parseExpression(_amount.text);
    if (amountMinor == null) return;

    // Saldo insuficiente: gasto o salida de transferencia no pueden superar el
    // saldo disponible de la cuenta de origen.
    if ((_type == TransactionType.gasto || _isTransfer) &&
        _accountId != null &&
        amountMinor > _availableBalance(_accountId!)) {
      _showError('Saldo insuficiente en la cuenta seleccionada.');
      return;
    }

    int? feeMinor;
    int? receivedMinor;
    if (_isTransfer) {
      feeMinor = _computeFeeMinor(amountMinor);
      final net = amountMinor - (feeMinor ?? 0);
      // Monto recibido: lo que escribió el usuario, o el cálculo por tasa.
      receivedMinor = Money.parseExpression(_received.text) ??
          _convertedNet(net);
    }

    final draft = TransactionDraft(
      type: _type,
      amountMinor: amountMinor,
      accountId: _accountId ?? '',
      categoryId: _isTransfer ? null : _categoryId,
      transferAccountId: _isTransfer ? _transferToId : null,
      transferAmountMinor: _isTransfer ? receivedMinor : null,
      feeMinor: _isTransfer ? feeMinor : null,
    );

    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final repo = ref.read(walletRepositoryProvider);

    try {
      if (_isEdit) {
        await repo.updateTransaction(
          id: widget.existing!.id,
          createdAt: widget.existing!.createdAt,
          draft: draft,
          date: _date,
          note: note,
        );
      } else {
        await repo.createTransaction(draft: draft, date: _date, note: note);
      }
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
    final balances = ref.watch(balancesProvider);
    final currenciesByCode = ref.watch(currenciesByCodeProvider);

    // Categorías filtradas por el tipo de movimiento.
    final kind =
        _type == TransactionType.ingreso ? CategoryKind.ingreso : CategoryKind.gasto;
    final visibleCategories =
        categories.where((c) => c.kind == kind).toList();

    // Monedas que tienen al menos una cuenta (para el filtro de gasto/ingreso).
    final usedCurrencies =
        accounts.map((a) => a.currency).toSet().toList()..sort();
    // Moneda efectiva del filtro: la elegida, o la del movimiento editado, o la
    // predeterminada, o la primera disponible.
    final effectiveCurrency = _currencyFilter ??
        (_isEdit ? ref.read(accountsByIdProvider)[_accountId]?.currency : null) ??
        ref.watch(defaultCurrencyProvider)?.code ??
        (usedCurrencies.isNotEmpty ? usedCurrencies.first : null);

    // Etiqueta de una cuenta con su saldo en su propia moneda.
    String accountLabel(AccountRow a) {
      final sym = currenciesByCode[a.currency]?.symbol ?? a.currency;
      final bal = balances[a.id] ?? a.initialBalanceMinor;
      return '${a.name} · ${Money.format(bal, symbol: sym)}';
    }

    // Cuentas mostradas para origen: en gasto/ingreso, solo las de la moneda
    // elegida; en transferencia, todas.
    final originAccounts = _isTransfer
        ? accounts
        : accounts.where((a) => a.currency == effectiveCurrency).toList();
    final originValue =
        originAccounts.any((a) => a.id == _accountId) ? _accountId : null;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Editar movimiento' : 'Nuevo movimiento')),
      body: accounts.isEmpty
          ? const _NeedsAccount()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
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
                  AmountField(
                    controller: _amount,
                    label: 'Importe',
                    autofocus: true,
                    requirePositive: true,
                  ),
                  const SizedBox(height: 16),
                  if (!_isTransfer) ...[
                    DropdownButtonFormField<String>(
                      initialValue: effectiveCurrency,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: [
                        for (final code in usedCurrencies)
                          DropdownMenuItem(
                            value: code,
                            child: Text(
                                '$code — ${currenciesByCode[code]?.name ?? code}'),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _currencyFilter = v;
                        _accountId = null; // la cuenta anterior puede no aplicar
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: originValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _isTransfer ? 'Cuenta origen' : 'Cuenta',
                    ),
                    items: [
                      for (final a in originAccounts)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(accountLabel(a),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    validator: (v) => v == null ? 'Selecciona una cuenta' : null,
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  const SizedBox(height: 16),
                  if (_isTransfer) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _transferToId,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Cuenta destino'),
                      items: [
                        for (final a in accounts.where((a) => a.id != _accountId))
                          DropdownMenuItem(
                            value: a.id,
                            child: Text(accountLabel(a),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      validator: (v) =>
                          v == null ? 'Selecciona la cuenta destino' : null,
                      onChanged: (v) => setState(() => _transferToId = v),
                    ),
                    const SizedBox(height: 16),
                    _buildFeeRow(),
                    const SizedBox(height: 16),
                    AmountField(
                      controller: _received,
                      label: 'Monto recibido en destino',
                      helperText: _isCrossCurrency
                          ? 'Vacío = se calcula con la tasa (neto × tasa).'
                          : 'Vacío = el neto tras la comisión.',
                      allowEmpty: true,
                    ),
                  ] else
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
                    label: Text(_isEdit ? 'Guardar cambios' : 'Guardar'),
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
