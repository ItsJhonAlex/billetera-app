import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../widgets/amount_field.dart';

/// Crea o edita una regla recurrente. Si [rule] es nulo, crea una nueva.
class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.rule});

  final RecurringRuleRow? rule;

  @override
  ConsumerState<RecurringFormScreen> createState() =>
      _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _dayOfMonth;
  late final TextEditingController _intervalDays;

  TransactionType _txType = TransactionType.gasto;
  RecurringMode _mode = RecurringMode.manual;
  RecurringSchedule _schedule = RecurringSchedule.diaDelMes;
  String? _accountId;
  String? _categoryId;
  DateTime _start = DateTime.now();

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _name = TextEditingController(text: r?.name ?? '');
    _amount = TextEditingController(
      text: r == null ? '' : Money.toUnits(r.amountMinor).toString(),
    );
    _note = TextEditingController(text: r?.note ?? '');
    _dayOfMonth = TextEditingController(text: r?.dayOfMonth?.toString() ?? '1');
    _intervalDays =
        TextEditingController(text: r?.intervalDays?.toString() ?? '30');
    if (r != null) {
      _txType = r.txType;
      _mode = r.mode;
      _schedule = r.scheduleType;
      _accountId = r.accountId;
      _categoryId = r.categoryId;
      _start = r.nextDueDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    _dayOfMonth.dispose();
    _intervalDays.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = Money.parseExpression(_amount.text);
    if (amount == null) return;

    final dayOfMonth = _schedule == RecurringSchedule.diaDelMes
        ? int.tryParse(_dayOfMonth.text)
        : null;
    final intervalDays = _schedule == RecurringSchedule.cadaNDias
        ? int.tryParse(_intervalDays.text)
        : null;
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final repo = ref.read(walletRepositoryProvider);

    if (_isEdit) {
      await repo.updateRule(
        id: widget.rule!.id,
        name: _name.text.trim(),
        txType: _txType,
        mode: _mode,
        scheduleType: _schedule,
        dayOfMonth: dayOfMonth,
        intervalDays: intervalDays,
        amountMinor: amount,
        accountId: _accountId!,
        categoryId: _categoryId,
        note: note,
      );
    } else {
      await repo.createRule(
        name: _name.text.trim(),
        txType: _txType,
        mode: _mode,
        scheduleType: _schedule,
        dayOfMonth: dayOfMonth,
        intervalDays: intervalDays,
        amountMinor: amount,
        accountId: _accountId!,
        categoryId: _categoryId,
        note: note,
        start: _start,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final kind = _txType == TransactionType.ingreso
        ? CategoryKind.ingreso
        : CategoryKind.gasto;
    final visibleCategories =
        categories.where((c) => c.kind == kind).toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Editar recurrente' : 'Nuevo recurrente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Netflix, Luz, Salario…',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                    value: TransactionType.gasto, label: Text('Gasto')),
                ButtonSegment(
                    value: TransactionType.ingreso, label: Text('Ingreso')),
              ],
              selected: {_txType},
              onSelectionChanged: (s) => setState(() {
                _txType = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            SegmentedButton<RecurringMode>(
              segments: [
                for (final m in RecurringMode.values)
                  ButtonSegment(value: m, label: Text(m.label)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                _mode == RecurringMode.automatica
                    ? 'Se registra sola al vencer, con el importe fijo.'
                    : 'Te avisa y registras tú; el importe es solo una estimación.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              label: _mode == RecurringMode.automatica
                  ? 'Importe'
                  : 'Importe estimado',
              requirePositive: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Cuenta'),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              validator: (v) => v == null ? 'Selecciona una cuenta' : null,
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in visibleCategories)
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
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 20),
            Text('Programación', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<RecurringSchedule>(
              segments: [
                for (final s in RecurringSchedule.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {_schedule},
              onSelectionChanged: (s) => setState(() => _schedule = s.first),
            ),
            const SizedBox(height: 12),
            if (_schedule == RecurringSchedule.diaDelMes)
              TextFormField(
                controller: _dayOfMonth,
                decoration: const InputDecoration(
                  labelText: 'Día del mes (1–31)',
                  helperText: 'Si el mes no tiene ese día, se usa el último.',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 31) return 'Día entre 1 y 31';
                  return null;
                },
              )
            else
              TextFormField(
                controller: _intervalDays,
                decoration: const InputDecoration(
                  labelText: 'Cada cuántos días',
                  helperText: 'Cuenta desde el último pago.',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Número de días mayor que 0';
                  return null;
                },
              ),
            if (!_isEdit) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Desde'),
                subtitle: Text(DateFormat('d MMM y', 'es').format(_start)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _start = picked);
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? 'Guardar cambios' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
