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
import '../widgets/confirm_dialog.dart';
import 'recurring_form_screen.dart';

/// Lista de reglas recurrentes, divididas en vencidas y próximas.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final accountsById = ref.watch(accountsByIdProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);
    final currenciesByCode = ref.watch(currenciesByCodeProvider);
    final hasAccounts =
        (ref.watch(accountsProvider).asData?.value ?? const []).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurrentes')),
      floatingActionButton: hasAccounts
          ? FloatingActionButton(
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (!hasAccounts) {
            return const _Empty(
              icon: Icons.event_repeat,
              message:
                  'Primero crea una cuenta para programar pagos recurrentes.',
            );
          }
          if (rules.isEmpty) {
            return const _Empty(
              icon: Icons.event_repeat,
              message:
                  'Sin pagos recurrentes.\nPulsa "+" para añadir suscripciones, '
                  'facturas o tu salario.',
            );
          }

          final today = _dateOnly(DateTime.now());
          final overdue = rules
              .where((r) => _dateOnly(r.nextDueDate).isBefore(today))
              .toList();
          final upcoming = rules
              .where((r) => !_dateOnly(r.nextDueDate).isBefore(today))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            children: [
              if (overdue.isNotEmpty) ...[
                const _Header('Vencidos', color: Colors.redAccent),
                for (final r in overdue)
                  _RuleCard(
                    rule: r,
                    accountsById: accountsById,
                    categoriesById: categoriesById,
                    currenciesByCode: currenciesByCode,
                  ),
              ],
              if (upcoming.isNotEmpty) ...[
                const _Header('Próximos'),
                for (final r in upcoming)
                  _RuleCard(
                    rule: r,
                    accountsById: accountsById,
                    categoriesById: categoriesById,
                    currenciesByCode: currenciesByCode,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {RecurringRuleRow? rule}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecurringFormScreen(rule: rule)),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String scheduleLabel(RecurringRuleRow r) {
  return switch (r.scheduleType) {
    RecurringSchedule.diaDelMes => 'Día ${r.dayOfMonth} de cada mes',
    RecurringSchedule.cadaNDias => 'Cada ${r.intervalDays} días',
  };
}

/// Texto relativo del vencimiento (y si está vencido).
({String text, bool overdue}) dueLabel(DateTime due, DateTime now) {
  final diff = _dateOnly(due).difference(_dateOnly(now)).inDays;
  if (diff == 0) return (text: 'Vence hoy', overdue: false);
  if (diff == 1) return (text: 'Vence mañana', overdue: false);
  if (diff > 1) return (text: 'En $diff días', overdue: false);
  final late = -diff;
  return (
    text: late == 1 ? 'Vencido ayer' : 'Vencido hace $late días',
    overdue: true,
  );
}

class _Header extends StatelessWidget {
  const _Header(this.title, {this.color});
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color ?? theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  const _RuleCard({
    required this.rule,
    required this.accountsById,
    required this.categoriesById,
    required this.currenciesByCode,
  });

  final RecurringRuleRow rule;
  final Map<String, AccountRow> accountsById;
  final Map<String, CategoryRow> categoriesById;
  final Map<String, CurrencyRow> currenciesByCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category =
        rule.categoryId == null ? null : categoriesById[rule.categoryId];
    final isIncome = rule.txType == TransactionType.ingreso;
    final isManual = rule.mode == RecurringMode.manual;
    final due = dueLabel(rule.nextDueDate, DateTime.now());

    final iconColor = category != null
        ? Color(category.colorValue)
        : (isIncome ? Colors.green.shade400 : theme.colorScheme.primary);
    final icon = category != null
        ? materialIcon(category.iconCodePoint)
        : rule.txType.icon;

    final symbol = currenciesByCode[accountsById[rule.accountId]?.currency]
            ?.symbol ??
        r'$';
    final amountText =
        '${isManual ? '≈ ' : ''}${Money.format(rule.amountMinor, symbol: symbol)}';

    return Card(
      child: Opacity(
        opacity: rule.active ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: iconColor.withValues(alpha: 0.18),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(rule.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium),
                            ),
                            _ModeBadge(mode: rule.mode),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$amountText · ${scheduleLabel(rule)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showActions(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    due.overdue ? Icons.warning_amber : Icons.schedule,
                    size: 16,
                    color: due.overdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rule.active ? due.text : 'Pausada',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: due.overdue && rule.active
                          ? theme.colorScheme.error
                          : null,
                      fontWeight:
                          due.overdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isManual && rule.active)
                    FilledButton.tonalIcon(
                      onPressed: () => _pay(context, ref),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Pagar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({int amount, DateTime date})>(
      context: context,
      builder: (_) => _PayDialog(rule: rule),
    );
    if (result == null) return;
    await ref.read(walletRepositoryProvider).payRecurring(
          ruleId: rule.id,
          amountMinor: result.amount,
          date: result.date,
        );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            if (rule.mode == RecurringMode.manual && rule.active)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Pagar ahora'),
                onTap: () => Navigator.pop(context, 'pay'),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(rule.active
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline),
              title: Text(rule.active ? 'Pausar' : 'Reanudar'),
              onTap: () => Navigator.pop(context, 'toggle'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Borrar'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final repo = ref.read(walletRepositoryProvider);
    switch (action) {
      case 'pay':
        await _pay(context, ref);
      case 'edit':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecurringFormScreen(rule: rule)),
        );
      case 'toggle':
        await repo.setRuleActive(rule.id, !rule.active);
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: '¿Borrar "${rule.name}"?',
          message: 'Se deja de programar. Los movimientos ya registrados se '
              'conservan.',
          confirmLabel: 'Borrar',
        );
        if (ok) await repo.archiveRule(rule.id);
    }
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});
  final RecurringMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auto = mode == RecurringMode.automatica;
    final color = auto ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        auto ? 'Auto' : 'Manual',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Diálogo para registrar el pago de una regla manual.
class _PayDialog extends StatefulWidget {
  const _PayDialog({required this.rule});
  final RecurringRuleRow rule;

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: Money.toUnits(widget.rule.amountMinor).toString(),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pagar "${widget.rule.name}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountField(
              controller: _amount,
              label: 'Monto pagado',
              autofocus: true,
              requirePositive: true,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('d MMM y', 'es').format(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
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
            final amount = Money.parseExpression(_amount.text);
            if (amount == null) return;
            Navigator.pop(context, (amount: amount, date: _date));
          },
          child: const Text('Registrar pago'),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
