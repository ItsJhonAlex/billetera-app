import 'package:flutter/material.dart';

import '../../core/material_icon.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../labels.dart';

/// Fila de un movimiento con el estilo del diseño: tile de icono con tinte,
/// título + cuenta, e importe agrupado (Space Grotesk) con color y signo.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.tx,
    required this.accountsById,
    required this.categoriesById,
    this.showDivider = false,
    this.onTap,
  });

  final TransactionRow tx;
  final Map<String, AccountRow> accountsById;
  final Map<String, CategoryRow> categoriesById;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isTransfer = tx.type == TransactionType.transferencia;
    final isIncome = tx.type == TransactionType.ingreso;
    final category = tx.categoryId == null ? null : categoriesById[tx.categoryId];
    final account = accountsById[tx.accountId];

    final String title;
    final IconData icon;
    final Color color;
    if (isTransfer) {
      final dest = accountsById[tx.transferAccountId];
      title = '${account?.name ?? '—'} → ${dest?.name ?? '—'}';
      icon = Icons.swap_horiz;
      color = t.transfer;
    } else if (category != null) {
      title = category.name;
      icon = materialIcon(category.iconCodePoint);
      color = Color(category.colorValue);
    } else {
      title = tx.type.label;
      icon = tx.type.icon;
      color = t.flow(isIncome: isIncome);
    }

    final flowColor = t.flow(isIncome: isIncome, isTransfer: isTransfer);
    final sign = isTransfer ? '' : (isIncome ? '+' : '−');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? Border(bottom: BorderSide(color: t.bd1)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.tx1,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (account != null) account.name,
                      if (tx.note != null && tx.note!.isNotEmpty) tx.note!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.txm, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${Money.grouped(tx.amountMinor)}',
              style: TextStyle(
                  fontFamily: BilleteraTheme.numberFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: flowColor),
            ),
          ],
        ),
      ),
    );
  }
}
