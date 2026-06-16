import 'enums.dart';

/// Lógica pura de los presupuestos por categoría. Sin Flutter ni Drift.

/// Umbrales de alerta (en % del presupuesto).
const List<int> kBudgetThresholds = [60, 75, 90, 100];

/// Clave de mes comparable: año*100 + mes.
int monthKey(DateTime d) => d.year * 100 + d.month;

/// Límite del presupuesto en centavos.
/// - [BudgetLimitType.fijo] → [amountMinor].
/// - [BudgetLimitType.porcentaje] → `percent% × baseBalanceMinor`.
int resolveLimitMinor({
  required BudgetLimitType type,
  int? amountMinor,
  int? percent,
  required int baseBalanceMinor,
}) {
  switch (type) {
    case BudgetLimitType.fijo:
      return amountMinor ?? 0;
    case BudgetLimitType.porcentaje:
      final base = baseBalanceMinor < 0 ? 0 : baseBalanceMinor;
      return base * (percent ?? 0) ~/ 100;
  }
}

/// Porcentaje consumido (redondeado). 0 si el límite es 0.
int consumedPct(int spentMinor, int limitMinor) {
  if (limitMinor <= 0) return 0;
  return (spentMinor * 100 / limitMinor).round();
}

/// Resultado de evaluar las alertas de un presupuesto.
typedef AlertDecision = ({
  List<int> toNotify,
  int newMaxThreshold,
  int monthKey,
});

/// Decide qué umbrales hay que avisar dados el % consumido y el estado guardado.
///
/// Si cambió el mes ([currentMonthKey] != [alertMonthKey]), el máximo previo se
/// reinicia a 0. Devuelve los umbrales cruzados aún no avisados y el nuevo
/// máximo a persistir.
AlertDecision evaluateAlerts({
  required int pct,
  required int alertMonthKey,
  required int alertMaxThreshold,
  required int currentMonthKey,
}) {
  final prevMax = currentMonthKey == alertMonthKey ? alertMaxThreshold : 0;
  final toNotify =
      kBudgetThresholds.where((t) => t <= pct && t > prevMax).toList();
  final newMax = toNotify.isEmpty ? prevMax : toNotify.last;
  return (
    toNotify: toNotify,
    newMaxThreshold: newMax,
    monthKey: currentMonthKey,
  );
}
