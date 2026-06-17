import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../providers/budget_providers.dart';
import '../providers/providers.dart';
import '../widgets/amount_field.dart';

/// Crea o edita el presupuesto de una categoría de gasto.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});

  final BudgetRow? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _percent;
  BudgetLimitType _type = BudgetLimitType.fijo;
  String? _categoryId;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _type = b?.limitType ?? BudgetLimitType.fijo;
    _categoryId = b?.categoryId;
    _amount = TextEditingController(
      text: b?.amountMinor == null ? '' : Money.toUnits(b!.amountMinor!).toString(),
    );
    _percent = TextEditingController(text: b?.percent?.toString() ?? '10');
  }

  @override
  void dispose() {
    _amount.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(walletRepositoryProvider);
    final isFixed = _type == BudgetLimitType.fijo;
    await repo.saveBudget(
      id: widget.budget?.id,
      categoryId: _categoryId!,
      limitType: _type,
      amountMinor: isFixed ? Money.parseExpression(_amount.text) : null,
      percent: isFixed ? null : int.tryParse(_percent.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final existing = ref.watch(budgetsProvider).asData?.value ?? const [];
    // Categorías de gasto sin presupuesto (más la actual si se está editando).
    final usedCatIds = existing
        .where((b) => b.id != widget.budget?.id)
        .map((b) => b.categoryId)
        .toSet();
    final available = categories
        .where((c) => c.kind == CategoryKind.gasto && !usedCatIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Editar presupuesto' : 'Nuevo presupuesto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in available)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(materialIcon(c.iconCodePoint),
                            size: 18, color: Color(c.colorValue)),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
              onChanged:
                  _isEdit ? null : (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 20),
            SegmentedButton<BudgetLimitType>(
              segments: const [
                ButtonSegment(
                    value: BudgetLimitType.fijo, label: Text('Monto fijo')),
                ButtonSegment(
                    value: BudgetLimitType.porcentaje,
                    label: Text('% del saldo')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            if (_type == BudgetLimitType.fijo)
              AmountField(
                controller: _amount,
                label: 'Límite mensual',
                requirePositive: true,
              )
            else
              _PercentField(controller: _percent),
            const SizedBox(height: 8),
            Text(
              _type == BudgetLimitType.fijo
                  ? 'Un monto fijo cada mes.'
                  : 'Un porcentaje del saldo (al inicio del mes) de las cuentas '
                      'incluidas en el presupuesto.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Guardar cambios' : 'Crear presupuesto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentField extends StatelessWidget {
  const _PercentField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Porcentaje del saldo',
        suffixText: '%',
      ),
      keyboardType: TextInputType.number,
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < 1 || n > 100) return 'Porcentaje entre 1 y 100';
        return null;
      },
    );
  }
}
