import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import '../providers/providers.dart';
import '../providers/transaction_filter.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/transaction_tile.dart';
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
    final currenciesByCode = ref.watch(currenciesByCodeProvider);

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
                        currenciesByCode: currenciesByCode,
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
            padding: const EdgeInsets.symmetric(vertical: 6),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: InputChip(label: Text(label), onDeleted: onDeleted),
    );
  }
}

/// Franja con ingresos y gastos del conjunto filtrado.
class _SummaryStrip extends ConsumerWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(filteredSummaryProvider);
    final symbol = ref.watch(defaultCurrencyProvider)?.symbol ?? r'$';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell(
              context,
              label: 'Ingresos',
              amountMinor: summary.incomeMinor,
              symbol: symbol,
              color: Colors.green.shade400,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryCell(
              context,
              label: 'Gastos',
              amountMinor: summary.expenseMinor,
              symbol: symbol,
              color: theme.colorScheme.error,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(
    BuildContext context, {
    required String label,
    required int amountMinor,
    required String symbol,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              Text(
                Money.format(amountMinor, symbol: symbol),
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
    required this.currenciesByCode,
    required this.onTapTx,
  });

  final List<TransactionRow> txns;
  final Map<String, AccountRow> accountsById;
  final Map<String, CategoryRow> categoriesById;
  final Map<String, CurrencyRow> currenciesByCode;
  final void Function(TransactionRow tx) onTapTx;

  @override
  Widget build(BuildContext context) {
    // Construye una lista plana intercalando encabezados de día.
    final items = <Widget>[];
    DateTime? lastDay;
    for (final tx in txns) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (lastDay == null || day != lastDay) {
        items.add(_DayHeader(day: tx.date));
        lastDay = day;
      }
      items.add(TransactionTile(
        tx: tx,
        accountsById: accountsById,
        categoriesById: categoriesById,
        currenciesByCode: currenciesByCode,
        onTap: () => onTapTx(tx),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        _label(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

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
            if (action != null) ...[const SizedBox(height: 8), action!],
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
