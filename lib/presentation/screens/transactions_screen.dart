import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../providers/transaction_filter.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/tx_row.dart';
import 'add_transaction_screen.dart';

/// Historial de movimientos con búsqueda, filtros y resumen del periodo.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(transactionFilterProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _searchController.clear();
      ref.read(transactionFilterProvider.notifier).setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyTxn =
        (ref.watch(transactionsProvider).asData?.value ?? const []).isNotEmpty;
    final filtered = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final accountsById = ref.watch(accountsByIdProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar en notas…',
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(transactionFilterProvider.notifier).setQuery(v),
              )
            : const Text('Movimientos'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Cerrar búsqueda' : 'Buscar',
            onPressed: _toggleSearch,
          ),
          _FilterButton(
            active: filter.dateRange != null ||
                filter.accountId != null ||
                filter.type != null,
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filter.hasFilters)
            _ActiveFilterChips(filter: filter, accountsById: accountsById),
          if (filtered.isNotEmpty) const _SummaryStrip(),
          Expanded(
            child: !hasAnyTxn
                ? const _EmptyState(
                    icon: Icons.receipt_long,
                    message: 'Aún no hay movimientos.\nPulsa "+" para añadir uno.',
                  )
                : filtered.isEmpty
                    ? _EmptyState(
                        icon: Icons.filter_alt_off,
                        message: 'Ningún movimiento coincide con el filtro.',
                        action: TextButton(
                          onPressed: () => ref
                              .read(transactionFilterProvider.notifier)
                              .clear(),
                          child: const Text('Limpiar filtros'),
                        ),
                      )
                    : _GroupedList(
                        txns: filtered,
                        accountsById: accountsById,
                        categoriesById: categoriesById,
                        onTapTx: (tx) => _showActions(context, tx),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FilterSheet(),
    );
  }

  Future<void> _showActions(BuildContext context, TransactionRow tx) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar movimiento'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar movimiento'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context, 'cancel'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: tx)),
      );
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: '¿Eliminar movimiento?',
        message: 'Esta acción no se puede deshacer y ajustará el saldo de la '
            'cuenta.',
        confirmLabel: 'Eliminar',
      );
      if (ok) {
        await ref.read(walletRepositoryProvider).deleteTransaction(tx.id);
      }
    }
  }
}

/// Botón de filtros con un punto indicador cuando hay filtros activos.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filtros',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        child: const Icon(Icons.tune),
      ),
    );
  }
}

/// Chips de los filtros activos, cada uno eliminable.
class _ActiveFilterChips extends ConsumerWidget {
  const _ActiveFilterChips({required this.filter, required this.accountsById});

  final TransactionFilter filter;
  final Map<String, AccountRow> accountsById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(transactionFilterProvider.notifier);
    final df = DateFormat('d MMM', 'es');

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (filter.type != null)
            _chip(
              context,
              label: filter.type!.label,
              onDeleted: () => notifier.setType(null),
            ),
          if (filter.accountId != null)
            _chip(
              context,
              label: accountsById[filter.accountId]?.name ?? 'Cuenta',
              onDeleted: () => notifier.setAccount(null),
            ),
          if (filter.dateRange != null)
            _chip(
              context,
              label:
                  '${df.format(filter.dateRange!.start)} – ${df.format(filter.dateRange!.end)}',
              onDeleted: () => notifier.setDateRange(null),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ActionChip(
              label: const Text('Limpiar'),
              avatar: const Icon(Icons.clear_all, size: 18),
              onPressed: notifier.clear,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label, required VoidCallback onDeleted}) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onDeleted,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
          decoration: BoxDecoration(
            color: t.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: t.goldSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Icon(Icons.close, size: 15, color: t.goldSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja con ingresos y gastos del conjunto filtrado.
class _SummaryStrip extends ConsumerWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(filteredSummaryProvider);
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: _cell(
              t,
              label: 'Ingresos',
              text: '+${Money.grouped(summary.incomeMinor)}',
              color: t.income,
              icon: Icons.south_west,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _cell(
              t,
              label: 'Gastos',
              text: '−${Money.grouped(summary.expenseMinor)}',
              color: t.expense,
              icon: Icons.north_east,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    BilleteraTokens t, {
    required String label,
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: BilleteraTheme.numberFont,
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Lista de movimientos agrupada por día con encabezados.
class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.txns,
    required this.accountsById,
    required this.categoriesById,
    required this.onTapTx,
  });

  final List<TransactionRow> txns;
  final Map<String, AccountRow> accountsById;
  final Map<String, CategoryRow> categoriesById;
  final void Function(TransactionRow tx) onTapTx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Agrupa por día conservando el orden (descendente).
    final groups = <DateTime, List<TransactionRow>>{};
    for (final tx in txns) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      (groups[day] ??= []).add(tx);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 110),
      children: [
        for (final entry in groups.entries) ...[
          _DayHeader(day: entry.key, count: entry.value.length),
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            padding: const EdgeInsets.all(6),
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
              children: [
                for (var i = 0; i < entry.value.length; i++)
                  TxRow(
                    tx: entry.value[i],
                    accountsById: accountsById,
                    categoriesById: categoriesById,
                    showDivider: i != entry.value.length - 1,
                    onTap: () => onTapTx(entry.value[i]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    final text = DateFormat('EEEE d MMM', 'es').format(day);
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      child: Row(
        children: [
          Text(
            _label().toUpperCase(),
            style: TextStyle(
                color: t.gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 1.5),
              painter: _DashedLinePainter(t.bd2),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count mov.',
              style: TextStyle(
                  fontFamily: BilleteraTheme.numberFont,
                  color: t.txm,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 4.0, gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: Icon(icon, size: 42, color: t.txf),
            ),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.tx2, height: 1.4)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para configurar los filtros (tipo, cuenta, rango de fechas).
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final accounts = ref.watch(accountsProvider).asData?.value ?? const [];
    final df = DateFormat('d MMM y', 'es');

    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        // Teclado (viewInsets) + barra de navegación del sistema (viewPadding).
        16 + media.viewInsets.bottom + media.viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filtros',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (filter.hasFilters)
                TextButton(
                  onPressed: notifier.clear,
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Tipo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: filter.type == null,
                onSelected: (_) => notifier.setType(null),
              ),
              for (final t in TransactionType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: filter.type == t,
                  onSelected: (_) => notifier.setType(t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: filter.accountId,
            decoration: const InputDecoration(
              labelText: 'Cuenta',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              for (final a in accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: notifier.setAccount,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range),
            title: const Text('Rango de fechas'),
            subtitle: Text(
              filter.dateRange == null
                  ? 'Todas las fechas'
                  : '${df.format(filter.dateRange!.start)} – ${df.format(filter.dateRange!.end)}',
            ),
            trailing: filter.dateRange == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => notifier.setDateRange(null),
                  ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(now.year + 1),
                initialDateRange: filter.dateRange,
                locale: const Locale('es'),
              );
              if (picked != null) notifier.setDateRange(picked);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ),
        ],
      ),
    );
  }
}
