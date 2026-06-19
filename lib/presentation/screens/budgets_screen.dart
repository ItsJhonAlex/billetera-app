import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/budget.dart';
import '../providers/budget_providers.dart';
import '../providers/providers.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/dashed_button.dart';
import 'budget_form_screen.dart';

/// Lista de presupuestos con anillo de resumen y barras por categoría.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final statuses = ref.watch(budgetStatusesProvider);
    final catsById = ref.watch(categoriesByIdProvider);

    final totalSpent = statuses.fold<int>(0, (s, x) => s + x.spentMinor);
    final totalLimit = statuses.fold<int>(0, (s, x) => s + x.limitMinor);
    final overallPct = consumedPct(totalSpent, totalLimit);
    final remaining = totalLimit - totalSpent;
    final month = DateFormat('MMMM y', 'es').format(DateTime.now());

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presupuestos',
                    style: TextStyle(
                        fontFamily: BilleteraTheme.displayFont,
                        fontSize: 24,
                        color: t.tx1)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${month[0].toUpperCase()}${month.substring(1)} · límites del mes',
                    style: TextStyle(color: t.txm, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          if (statuses.isEmpty)
            const _Empty()
          else ...[
            _RingSummary(
              pct: overallPct,
              spentMinor: totalSpent,
              limitMinor: totalLimit,
              remainingMinor: remaining,
            ),
            for (final s in statuses)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _BudgetCard(
                  status: s,
                  categoryName:
                      catsById[s.budget.categoryId]?.name ?? 'Categoría',
                  iconCodePoint: catsById[s.budget.categoryId]?.iconCodePoint,
                  colorValue: catsById[s.budget.categoryId]?.colorValue,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: DashedButton(
                label: 'Nuevo presupuesto',
                onTap: () => _openForm(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
    );
  }
}

class _RingSummary extends StatelessWidget {
  const _RingSummary({
    required this.pct,
    required this.spentMinor,
    required this.limitMinor,
    required this.remainingMinor,
  });

  final int pct, spentMinor, limitMinor, remainingMinor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.leatherGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.bd3),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: (pct.clamp(0, 100)) / 100,
                    strokeWidth: 9,
                    backgroundColor: t.bd2,
                    valueColor: AlwaysStoppedAnimation(
                        pct >= 90 ? t.expense : t.gold),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$pct%',
                        style: TextStyle(
                            fontFamily: BilleteraTheme.numberFont,
                            color: t.txBright,
                            fontSize: 19,
                            fontWeight: FontWeight.w600)),
                    Text('USADO',
                        style: TextStyle(
                            color: t.txm,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastado este mes',
                    style: TextStyle(
                        color: t.tx3, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    text: Money.grouped(spentMinor),
                    style: TextStyle(
                        fontFamily: BilleteraTheme.numberFont,
                        color: t.txBright,
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: '  / ${Money.grouped(limitMinor)}',
                        style: TextStyle(
                            fontFamily: BilleteraTheme.numberFont,
                            color: t.txm,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remainingMinor >= 0
                      ? 'Te quedan ${Money.grouped(remainingMinor)}'
                      : 'Te pasaste ${Money.grouped(-remainingMinor)}',
                  style: TextStyle(
                      color: remainingMinor >= 0 ? t.income : t.expense,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final t = context.tokens;
    final limit = status.limitMinor;
    final spent = status.spentMinor;
    final remaining = limit - spent;
    final pct = consumedPct(spent, limit);
    final fraction = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final catColor = colorValue != null ? Color(colorValue!) : t.gold;

    final Color barColor;
    if (pct >= 90) {
      barColor = t.expense;
    } else if (pct >= 60) {
      barColor = const Color(0xFFE0A23B);
    } else {
      barColor = t.income;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BudgetFormScreen(budget: status.budget),
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: t.surfaceGradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.bd1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                        iconCodePoint != null
                            ? materialIcon(iconCodePoint!)
                            : Icons.savings,
                        size: 20,
                        color: catColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(categoryName,
                            style: TextStyle(
                                color: t.tx1,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(
                          remaining >= 0
                              ? '${Money.grouped(spent)} de ${Money.grouped(limit)} · quedan ${Money.grouped(remaining)}'
                              : '${Money.grouped(spent)} de ${Money.grouped(limit)} · te pasaste',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.txm, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Text('$pct%',
                      style: TextStyle(
                          fontFamily: BilleteraTheme.numberFont,
                          color: barColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  backgroundColor: t.bg,
                  color: barColor,
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
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 10),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.surf2A, t.surfB]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: t.bd3, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.savings, size: 42, color: t.txf),
          ),
          const SizedBox(height: 20),
          Text('Sin presupuestos',
              style: TextStyle(
                  color: t.tx1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Pulsa "Nuevo presupuesto" para fijar un límite mensual a una '
            'categoría.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.txm, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
