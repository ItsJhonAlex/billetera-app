import 'package:billetera/domain/enums.dart';
import 'package:billetera/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDueAfter diaDelMes', () {
    test('mismo mes si el día aún no pasó', () {
      final r = nextDueAfter(RecurringSchedule.diaDelMes,
          dayOfMonth: 15, from: DateTime(2026, 6, 10));
      expect(r, DateTime(2026, 6, 15));
    });

    test('mes siguiente si el día ya pasó o es hoy', () {
      final r = nextDueAfter(RecurringSchedule.diaDelMes,
          dayOfMonth: 5, from: DateTime(2026, 6, 5));
      expect(r, DateTime(2026, 7, 5));
    });

    test('ajusta el día 31 al último día de un mes corto', () {
      // Desde ende enero, el día 31 cae en febrero -> 28 (2026 no bisiesto).
      final r = nextDueAfter(RecurringSchedule.diaDelMes,
          dayOfMonth: 31, from: DateTime(2026, 1, 31));
      expect(r, DateTime(2026, 2, 28));
    });
  });

  group('nextDueAfter cadaNDias', () {
    test('suma el intervalo', () {
      final r = nextDueAfter(RecurringSchedule.cadaNDias,
          intervalDays: 30, from: DateTime(2026, 6, 1));
      expect(r, DateTime(2026, 7, 1));
    });
  });

  group('firstDueFrom', () {
    test('diaDelMes: hoy mismo si la fecha de inicio cae en el día', () {
      final r = firstDueFrom(RecurringSchedule.diaDelMes,
          dayOfMonth: 5, start: DateTime(2026, 6, 5));
      expect(r, DateTime(2026, 6, 5));
    });

    test('diaDelMes: mes siguiente si ya pasó', () {
      final r = firstDueFrom(RecurringSchedule.diaDelMes,
          dayOfMonth: 5, start: DateTime(2026, 6, 10));
      expect(r, DateTime(2026, 7, 5));
    });

    test('cadaNDias: el inicio elegido es el primer vencimiento', () {
      final r = firstDueFrom(RecurringSchedule.cadaNDias,
          intervalDays: 30, start: DateTime(2026, 6, 10));
      expect(r, DateTime(2026, 6, 10));
    });
  });

  group('advanceAfterPayment', () {
    test('diaDelMes: mismo día del mes siguiente, aunque se pague tarde', () {
      final r = advanceAfterPayment(
        RecurringSchedule.diaDelMes,
        dayOfMonth: 5,
        currentDue: DateTime(2026, 6, 5),
        paidDate: DateTime(2026, 6, 9), // pagó tarde
      );
      expect(r, DateTime(2026, 7, 5));
    });

    test('cadaNDias: cuenta desde el día real de pago', () {
      final r = advanceAfterPayment(
        RecurringSchedule.cadaNDias,
        intervalDays: 30,
        currentDue: DateTime(2026, 6, 1),
        paidDate: DateTime(2026, 6, 4), // 3 días tarde
      );
      expect(r, DateTime(2026, 7, 4));
    });
  });

  group('dueOccurrences', () {
    test('sin nada vencido devuelve vacío', () {
      final r = dueOccurrences(
        nextDue: DateTime(2026, 7, 5),
        type: RecurringSchedule.diaDelMes,
        dayOfMonth: 5,
        now: DateTime(2026, 6, 20),
      );
      expect(r, isEmpty);
    });

    test('recupera varios cobros mensuales perdidos', () {
      // Próximo era 5 de abril; hoy 20 de junio -> abril, mayo, junio.
      final r = dueOccurrences(
        nextDue: DateTime(2026, 4, 5),
        type: RecurringSchedule.diaDelMes,
        dayOfMonth: 5,
        now: DateTime(2026, 6, 20),
      );
      expect(r, [
        DateTime(2026, 4, 5),
        DateTime(2026, 5, 5),
        DateTime(2026, 6, 5),
      ]);
    });

    test('recupera intervalos perdidos', () {
      final r = dueOccurrences(
        nextDue: DateTime(2026, 6, 1),
        type: RecurringSchedule.cadaNDias,
        intervalDays: 10,
        now: DateTime(2026, 6, 25),
      );
      expect(r, [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 21),
      ]);
    });

    test('respeta el tope de seguridad', () {
      final r = dueOccurrences(
        nextDue: DateTime(2000, 1, 1),
        type: RecurringSchedule.cadaNDias,
        intervalDays: 1,
        now: DateTime(2026, 1, 1),
      );
      expect(r.length, kMaxCatchUpOccurrences);
    });
  });
}
