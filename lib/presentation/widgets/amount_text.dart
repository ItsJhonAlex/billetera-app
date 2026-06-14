import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';

/// Muestra un importe (en centavos) con color y signo según el flujo.
class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amountMinor,
    this.isIncome = true,
    this.isTransfer = false,
    this.showSign = true,
    this.style,
  });

  /// Importe en centavos. Si [showSign] es falso se muestra tal cual (saldos).
  final int amountMinor;
  final bool isIncome;
  final bool isTransfer;
  final bool showSign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = showSign
        ? BilleteraTheme.colorForFlow(isIncome: isIncome, isTransfer: isTransfer)
        : (amountMinor < 0 ? BilleteraTheme.expense : null);

    final sign = showSign ? (isIncome ? '+' : '−') : '';
    final text = '$sign${Money.format(amountMinor.abs())}';

    return Text(
      text,
      style: (style ?? const TextStyle(fontWeight: FontWeight.w600))
          .copyWith(color: color),
    );
  }
}
