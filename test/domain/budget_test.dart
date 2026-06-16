import 'package:billetera/domain/budget.dart';
import 'package:billetera/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLimitMinor', () {
    test('fijo devuelve el monto', () {
      expect(
        resolveLimitMinor(
            type: BudgetLimitType.fijo, amountMinor: 3000, baseBalanceMinor: 0),
        3000,
      );
    });

    test('porcentaje sobre la base', () {
      expect(
        resolveLimitMinor(
            type: BudgetLimitType.porcentaje,
            percent: 20,
            baseBalanceMinor: 100000),
        20000,
      );
    });

    test('porcentaje con base negativa = 0', () {
      expect(
        resolveLimitMinor(
            type: BudgetLimitType.porcentaje,
            percent: 20,
            baseBalanceMinor: -500),
        0,
      );
    });
  });

  group('consumedPct', () {
    test('calcula y redondea', () {
      expect(consumedPct(750, 1000), 75);
      expect(consumedPct(1, 300), 0); // 0.33% -> 0
      expect(consumedPct(2, 3), 67); // 66.6% -> 67
    });
    test('límite 0 = 0%', () {
      expect(consumedPct(500, 0), 0);
    });
  });

  group('evaluateAlerts', () {
    test('cruza varios umbrales de una vez', () {
      final d = evaluateAlerts(
          pct: 95, alertMonthKey: 202606, alertMaxThreshold: 0, currentMonthKey: 202606);
      expect(d.toNotify, [60, 75, 90]);
      expect(d.newMaxThreshold, 90);
    });

    test('no repite umbrales ya avisados', () {
      final d = evaluateAlerts(
          pct: 80, alertMonthKey: 202606, alertMaxThreshold: 75, currentMonthKey: 202606);
      expect(d.toNotify, isEmpty);
      expect(d.newMaxThreshold, 75);
    });

    test('avisa el siguiente umbral al subir el consumo', () {
      final d = evaluateAlerts(
          pct: 92, alertMonthKey: 202606, alertMaxThreshold: 75, currentMonthKey: 202606);
      expect(d.toNotify, [90]);
      expect(d.newMaxThreshold, 90);
    });

    test('100% también avisa', () {
      final d = evaluateAlerts(
          pct: 120, alertMonthKey: 202606, alertMaxThreshold: 90, currentMonthKey: 202606);
      expect(d.toNotify, [100]);
    });

    test('reinicia al cambiar de mes', () {
      final d = evaluateAlerts(
          pct: 65, alertMonthKey: 202605, alertMaxThreshold: 100, currentMonthKey: 202606);
      expect(d.toNotify, [60]); // mes nuevo: el máximo previo se ignora
      expect(d.newMaxThreshold, 60);
    });
  });

  test('monthKey', () {
    expect(monthKey(DateTime(2026, 6, 15)), 202606);
  });
}
