import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../domain/budget.dart';
import '../providers/budget_providers.dart';
import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';
import 'budget_form_screen.dart';

/// Lista de presupuestos por categoría con barra de progreso del mes.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(budgetStatusesProvider);
    final catsById = ref.watch(categoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: statuses.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                for (final s in statuses)
                  _BudgetCard(
                    status: s,
                    categoryName:
                        catsById[s.budget.categoryId]?.name ?? 'Categoría',
                    iconCodePoint:
                        catsById[s.budget.categoryId]?.iconCodePoint,
                    colorValue: catsById[s.budget.categoryId]?.colorValue,
                  ),
              ],
            ),
    );

    // ignore: dead_code
    // (gastoCategories se usa al abrir el formulario)
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.status,
    required this.categoryName,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final BudgetStatus status;
  final String categoryName;
  final int? iconCodePoint;
  final int? colorValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final limit = status.limitMinor;
    final spent = status.spentMinor;
    final remaining = limit - spent;
    final pct = consumedPct(spent, limit);
    final fraction = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);

    final Color barColor;
    if (pct >= 90) {
      barColor = theme.colorScheme.error;
    } else if (pct >= 60) {
      barColor = Colors.amber.shade700;
    } else {
      barColor = Colors.green.shade500;
    }

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BudgetFormScreen(budget: status.budget),
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (iconCodePoint != null)
                    Icon(materialIcon(iconCodePoint!),
                        size: 20,
                        color: colorValue != null ? Color(colorValue!) : null),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(categoryName,
                        style: theme.textTheme.titleMedium),
                  ),
                  Text('$pct%',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: barColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gastaste ${Money.format(spent)} de ${Money.format(limit)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                remaining >= 0
                    ? 'Te queda ${Money.format(remaining)}'
                    : 'Te pasaste ${Money.format(-remaining)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: remaining < 0 ? theme.colorScheme.error : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: '¿Quitar presupuesto de "$categoryName"?',
      message: 'La categoría y sus movimientos no se tocan; solo se quita el '
          'límite.',
      confirmLabel: 'Quitar',
    );
    if (ok) {
      await ref.read(walletRepositoryProvider).archiveBudget(status.budget.id);
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'Sin presupuestos.\nPulsa "+" para fijar un límite mensual a una '
              'categoría.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
