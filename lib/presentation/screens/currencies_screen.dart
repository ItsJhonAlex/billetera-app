import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/wallet_repository.dart';
import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';

/// Gestión de monedas (catálogo + predeterminada) y tasas de cambio.
class CurrenciesScreen extends ConsumerWidget {
  const CurrenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currenciesProvider).asData?.value ?? const [];
    final rates = ref.watch(exchangeRatesProvider).asData?.value ?? const [];
    final repo = ref.read(walletRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monedas')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Header('Monedas'),
          for (final c in currencies)
            ListTile(
              leading: CircleAvatar(child: Text(c.symbol)),
              title: Text('${c.code} — ${c.name}'),
              subtitle: c.isDefault ? const Text('Predeterminada') : null,
              trailing: PopupMenuButton<String>(
                onSelected: (a) => _onCurrencyAction(context, ref, c, a),
                itemBuilder: (_) => [
                  if (!c.isDefault)
                    const PopupMenuItem(
                        value: 'default', child: Text('Hacer predeterminada')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (!c.isDefault)
                    const PopupMenuItem(value: 'delete', child: Text('Borrar')),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _editCurrency(context, repo),
              icon: const Icon(Icons.add),
              label: const Text('Añadir moneda'),
            ),
          ),
          const _Header('Tasas de cambio'),
          if (rates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Define tasas como "1 USD = 680 CUP". Si falta un par, se calcula '
                'puenteando por la moneda predeterminada.',
              ),
            ),
          for (final r in rates)
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: Text('1 ${r.fromCode} = ${_fmt(r.rate)} ${r.toCode}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editRate(context, ref, currencies, r),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => repo.deleteRate(r.id),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: currencies.length < 2
                  ? null
                  : () => _editRate(context, ref, currencies, null),
              icon: const Icon(Icons.add),
              label: const Text('Añadir tasa'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double r) =>
      r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();

  Future<void> _onCurrencyAction(
    BuildContext context,
    WidgetRef ref,
    CurrencyRow c,
    String action,
  ) async {
    final repo = ref.read(walletRepositoryProvider);
    switch (action) {
      case 'default':
        await repo.setDefaultCurrency(c.code);
      case 'edit':
        await _editCurrency(context, repo, existing: c);
      case 'delete':
        final accounts = ref.read(accountsProvider).asData?.value ?? const [];
        final inUse = accounts.where((a) => a.currency == c.code).length;
        if (inUse > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No se puede borrar ${c.code}: la usan $inUse cuenta(s).'),
            ),
          );
          return;
        }
        final ok = await confirmDialog(
          context,
          title: '¿Borrar ${c.code}?',
          message: 'Se quita del catálogo y sus tasas asociadas dejan de aplicar.',
          confirmLabel: 'Borrar',
        );
        if (ok) await repo.deleteCurrency(c.code);
    }
  }

  Future<void> _editCurrency(
    BuildContext context,
    WalletRepository repo, {
    CurrencyRow? existing,
  }) async {
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => _CurrencyDialog(existing: existing),
    );
    if (result == null) return;
    await repo.saveCurrency(
      code: result.$1,
      name: result.$2,
      symbol: result.$3,
    );
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    List<CurrencyRow> currencies,
    ExchangeRateRow? existing,
  ) async {
    final result = await showDialog<(String, String, double)>(
      context: context,
      builder: (_) => _RateDialog(currencies: currencies, existing: existing),
    );
    if (result == null) return;
    await ref.read(walletRepositoryProvider).saveRate(
          id: existing?.id,
          fromCode: result.$1,
          toCode: result.$2,
          rate: result.$3,
        );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Diálogo para crear/editar una moneda. Devuelve (code, name, symbol).
class _CurrencyDialog extends StatefulWidget {
  const _CurrencyDialog({this.existing});
  final CurrencyRow? existing;

  @override
  State<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<_CurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _symbol;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.existing?.code ?? '');
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _symbol = TextEditingController(text: widget.existing?.symbol ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _symbol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar moneda' : 'Nueva moneda'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _code,
              enabled: !isEdit, // el código es la clave
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Código', hintText: 'USD, EUR, CUP…'),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Mínimo 2 letras' : null,
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            TextFormField(
              controller: _symbol,
              decoration: const InputDecoration(
                  labelText: 'Símbolo', hintText: r'$, €, US$…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un símbolo' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              _code.text.trim().toUpperCase(),
              _name.text.trim(),
              _symbol.text.trim(),
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Diálogo para crear/editar una tasa. Devuelve (fromCode, toCode, rate).
class _RateDialog extends StatefulWidget {
  const _RateDialog({required this.currencies, this.existing});
  final List<CurrencyRow> currencies;
  final ExchangeRateRow? existing;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rate;
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    final codes = widget.currencies.map((c) => c.code).toList();
    _from = widget.existing?.fromCode ?? codes.first;
    _to = widget.existing?.toCode ?? codes.firstWhere((c) => c != _from,
        orElse: () => codes.first);
    _rate = TextEditingController(
        text: widget.existing == null ? '' : _fmt(widget.existing!.rate));
  }

  String _fmt(double r) =>
      r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codes = widget.currencies.map((c) => c.code).toList();
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nueva tasa' : 'Editar tasa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('1  '),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _from,
                    items: [
                      for (final c in codes)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _from = v ?? _from),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'equivale a…'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Tasa mayor que 0';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('de  '),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _to,
                    items: [
                      for (final c in codes)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _to = v ?? _to),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_from == _to) return;
            if (!_formKey.currentState!.validate()) return;
            final n = double.parse(_rate.text.replaceAll(',', '.'));
            Navigator.pop(context, (_from, _to, n));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
