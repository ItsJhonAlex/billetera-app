import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/database/app_database.dart';
import '../providers/providers.dart';
import '../providers/summary.dart';

/// Resumen con gráficos: totales, gasto por categoría y evolución, por periodo.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(summarySelectionProvider);
    final range = ref.watch(summaryRangeProvider);
    final totals = ref.watch(summaryTotalsProvider);
    final slices = ref.watch(expenseByCategoryProvider);
    final bars = ref.watch(evolutionProvider);
    final catsById = ref.watch(categoriesByIdProvider);
    final symbol = ref.watch(defaultCurrencyProvider)?.symbol ?? r'$';
    final fees = ref.watch(feesInPeriodProvider);
    final notifier = ref.read(summarySelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<SummaryPeriod>(
            segments: const [
              ButtonSegment(value: SummaryPeriod.mes, label: Text('Mes')),
              ButtonSegment(
                  value: SummaryPeriod.trimestre, label: Text('Trim.')),
              ButtonSegment(value: SummaryPeriod.semestre, label: Text('6m')),
              ButtonSegment(value: SummaryPeriod.anio, label: Text('Año')),
            ],
            selected: {sel.period},
            onSelectionChanged: (s) => notifier.setPeriod(s.first),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: notifier.prev,
              ),
              Text(
                _periodLabel(sel.period, range),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                // No deja navegar al futuro.
                onPressed: sel.offset < 0 ? notifier.next : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TotalsRow(totals: totals, symbol: symbol),
          if (fees > 0) ...[
            const SizedBox(height: 8),
            _FeesTile(feeMinor: fees, symbol: symbol),
          ],
          const SizedBox(height: 24),
          Text('Gasto por categoría',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _CategoryDonut(slices: slices, catsById: catsById, symbol: symbol),
          const SizedBox(height: 24),
          Text('Evolución', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _EvolutionChart(bars: bars, period: sel.period, symbol: symbol),
        ],
      ),
    );
  }

  String _periodLabel(SummaryPeriod p, Range r) {
    final y = r.start.year;
    switch (p) {
      case SummaryPeriod.mes:
        final t = DateFormat('MMMM y', 'es').format(r.start);
        return t[0].toUpperCase() + t.substring(1);
      case SummaryPeriod.trimestre:
        return 'T${(r.start.month - 1) ~/ 3 + 1} $y';
      case SummaryPeriod.semestre:
        return r.start.month == 1 ? 'Ene–Jun $y' : 'Jul–Dic $y';
      case SummaryPeriod.anio:
        return '$y';
    }
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.totals, required this.symbol});
  final SummaryTotals totals;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final balance = totals.incomeMinor - totals.expenseMinor;
    return Row(
      children: [
        Expanded(
          child: _TotalCell(
            label: 'Ingresos',
            amountMinor: totals.incomeMinor,
            symbol: symbol,
            color: Colors.green.shade400,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TotalCell(
            label: 'Gastos',
            amountMinor: totals.expenseMinor,
            symbol: symbol,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TotalCell(
            label: 'Balance',
            amountMinor: balance,
            symbol: symbol,
            color: balance < 0
                ? Theme.of(context).colorScheme.error
                : BilleteraTheme.stitch,
          ),
        ),
      ],
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    required this.color,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            Money.format(amountMinor, symbol: symbol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Comisiones perdidas en el periodo.
class _FeesTile extends StatelessWidget {
  const _FeesTile({required this.feeMinor, required this.symbol});
  final int feeMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.percent, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          const Expanded(child: Text('Comisiones perdidas')),
          Text(
            Money.format(feeMinor, symbol: symbol),
            style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Paleta de respaldo para categorías sin color propio o sin categoría.
const _fallbackColors = [
  Color(0xFFC9A227),
  Color(0xFF6D8B74),
  Color(0xFFB5651D),
  Color(0xFF8E7DBE),
  Color(0xFF4E8098),
  Color(0xFFB0413E),
];

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({
    required this.slices,
    required this.catsById,
    required this.symbol,
  });

  final List<CategorySlice> slices;
  final Map<String, CategoryRow> catsById;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const _EmptyChart(message: 'Sin gastos en este periodo.');
    }
    final total = slices.fold<int>(0, (s, x) => s + x.amountMinor);

    Color colorFor(CategorySlice s, int i) {
      final cat = s.categoryId == null ? null : catsById[s.categoryId];
      return cat != null
          ? Color(cat.colorValue)
          : _fallbackColors[i % _fallbackColors.length];
    }

    String nameFor(CategorySlice s) {
      final cat = s.categoryId == null ? null : catsById[s.categoryId];
      return cat?.name ?? 'Sin categoría';
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                for (var i = 0; i < slices.length; i++)
                  PieChartSectionData(
                    value: slices[i].amountMinor.toDouble(),
                    color: colorFor(slices[i], i),
                    radius: 50,
                    title: '${(slices[i].amountMinor * 100 / total).round()}%',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorFor(slices[i], i),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(nameFor(slices[i]))),
                Text(
                  '${Money.format(slices[i].amountMinor, symbol: symbol)}  ·  '
                  '${(slices[i].amountMinor * 100 / total).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({
    required this.bars,
    required this.period,
    required this.symbol,
  });

  final List<EvolutionBar> bars;
  final SummaryPeriod period;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (bars.every((b) => b.expenseMinor == 0)) {
      return const _EmptyChart(message: 'Sin gastos para graficar.');
    }
    final maxExpense =
        bars.map((b) => b.expenseMinor).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxExpense / 100) * 1.2; // en unidades, con holgura

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                Money.format((rod.toY * 100).round(), symbol: symbol),
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) => _bottomLabel(value.toInt()),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].expenseMinor / 100,
                    color: BilleteraTheme.stitch,
                    width: period == SummaryPeriod.mes ? 5 : 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomLabel(int index) {
    if (index < 0 || index >= bars.length) return const SizedBox.shrink();
    final d = bars[index].start;
    final String text;
    if (period == SummaryPeriod.mes) {
      // Solo cada 5 días para no saturar.
      if (d.day != 1 && d.day % 5 != 0) return const SizedBox.shrink();
      text = '${d.day}';
    } else {
      text = DateFormat('MMM', 'es').format(d);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.outline)),
    );
  }
}
