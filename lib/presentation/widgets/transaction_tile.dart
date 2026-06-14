import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/material_icon.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import 'amount_text.dart';

/// Fila de un movimiento en una lista. Resuelve nombres de cuenta y categoría
/// a partir de los mapas que le pasa la pantalla.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    required this.accountsById,
    required this.categoriesById,
    this.onTap,
  });

  final TransactionRow tx;
  final Map<String, AccountRow> accountsById;
  final Map<String, CategoryRow> categoriesById;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTransfer = tx.type == TransactionType.transferencia;
    final isIncome = tx.type == TransactionType.ingreso;

    final category = tx.categoryId == null ? null : categoriesById[tx.categoryId];
    final account = accountsById[tx.accountId];

    final String title;
    final IconData icon;
    final Color iconColor;

    if (isTransfer) {
      final dest = accountsById[tx.transferAccountId];
      title = '${account?.name ?? '—'} → ${dest?.name ?? '—'}';
      icon = Icons.swap_horiz;
      iconColor = Theme.of(context).colorScheme.primary;
    } else if (category != null) {
      title = category.name;
      icon = materialIcon(category.iconCodePoint);
      iconColor = Color(category.colorValue);
    } else {
      title = tx.type.label;
      icon = tx.type.icon;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    final subtitleParts = <String>[
      DateFormat('d MMM', 'es').format(tx.date),
      if (!isTransfer && account != null) account.name,
      if (tx.note != null && tx.note!.isNotEmpty) tx.note!,
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.18),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: AmountText(
        amountMinor: tx.amountMinor,
        isIncome: isIncome,
        isTransfer: isTransfer,
      ),
      onTap: onTap,
    );
  }
}
