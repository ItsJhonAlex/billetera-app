import 'package:flutter/material.dart';

import '../domain/enums.dart';

/// Etiquetas e iconos legibles para los enums del dominio. Vive en presentación
/// porque es texto/UI; el dominio se mantiene sin Flutter.
extension AccountTypeDisplay on AccountType {
  String get label => switch (this) {
        AccountType.efectivo => 'Efectivo',
        AccountType.banco => 'Banco',
        AccountType.tarjeta => 'Tarjeta',
        AccountType.otro => 'Otro',
      };

  IconData get icon => switch (this) {
        AccountType.efectivo => Icons.payments,
        AccountType.banco => Icons.account_balance,
        AccountType.tarjeta => Icons.credit_card,
        AccountType.otro => Icons.account_balance_wallet,
      };
}

extension CategoryKindDisplay on CategoryKind {
  String get label => switch (this) {
        CategoryKind.gasto => 'Gasto',
        CategoryKind.ingreso => 'Ingreso',
      };
}

extension TransactionTypeDisplay on TransactionType {
  String get label => switch (this) {
        TransactionType.gasto => 'Gasto',
        TransactionType.ingreso => 'Ingreso',
        TransactionType.transferencia => 'Transferencia',
      };

  IconData get icon => switch (this) {
        TransactionType.gasto => Icons.arrow_upward,
        TransactionType.ingreso => Icons.arrow_downward,
        TransactionType.transferencia => Icons.swap_horiz,
      };
}

extension RecurringModeDisplay on RecurringMode {
  String get label => switch (this) {
        RecurringMode.automatica => 'Automática',
        RecurringMode.manual => 'Manual',
      };
}

extension RecurringScheduleDisplay on RecurringSchedule {
  String get label => switch (this) {
        RecurringSchedule.diaDelMes => 'Día del mes',
        RecurringSchedule.cadaNDias => 'Cada N días',
      };
}
