import 'package:billetera/data/notifications/notification_schedule.dart';
import 'package:billetera/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reminderOffsetsFor', () {
    test('automática avisa a 3, 1 y 0 días', () {
      expect(reminderOffsetsFor(RecurringMode.automatica), [3, 1, 0]);
    });
    test('manual avisa a 1 y 0 días', () {
      expect(reminderOffsetsFor(RecurringMode.manual), [1, 0]);
    });
  });

  group('remindersForRule', () {
    test('automática programa los tres avisos futuros a las 9:00', () {
      final r = remindersForRule(
        mode: RecurringMode.automatica,
        nextDueDate: DateTime(2026, 6, 10),
        now: DateTime(2026, 6, 1, 12),
      );
      expect(r.map((x) => x.when), [
        DateTime(2026, 6, 7, 9), // 3 días antes
        DateTime(2026, 6, 9, 9), // 1 día antes
        DateTime(2026, 6, 10, 9), // el día
      ]);
    });

    test('omite los avisos que ya pasaron', () {
      // Hoy es 9 jun por la tarde: el aviso de 3 y 1 día ya pasaron; queda el del día.
      final r = remindersForRule(
        mode: RecurringMode.automatica,
        nextDueDate: DateTime(2026, 6, 10),
        now: DateTime(2026, 6, 9, 15),
      );
      expect(r.length, 1);
      expect(r.single.daysBefore, 0);
    });

    test('manual solo programa 1 y 0 días', () {
      final r = remindersForRule(
        mode: RecurringMode.manual,
        nextDueDate: DateTime(2026, 6, 10),
        now: DateTime(2026, 6, 1),
      );
      expect(r.map((x) => x.daysBefore), [1, 0]);
    });
  });

  group('reminderText', () {
    test('automática el día del cobro', () {
      final t = reminderText(
          ruleName: 'Netflix', mode: RecurringMode.automatica, daysBefore: 0);
      expect(t.body, contains('Hoy se cobra'));
    });

    test('manual con antelación', () {
      final t = reminderText(
          ruleName: 'Luz', mode: RecurringMode.manual, daysBefore: 3);
      expect(t.body, contains('En 3 días'));
      expect(t.body, contains('vence'));
    });
  });
}
