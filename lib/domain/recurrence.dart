import 'enums.dart';

/// Lógica pura del cálculo de fechas de las reglas recurrentes.
/// Sin dependencias de Flutter ni de la base de datos: fácil de testear.

/// Tope de seguridad de ocurrencias recuperadas de una sola vez, para no entrar
/// en bucles si los datos quedaran corruptos.
const int kMaxCatchUpOccurrences = 60;

/// Normaliza a medianoche (ignora la hora).
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Último día del mes [month] del año [year] (28–31).
int _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Devuelve la fecha del día [dayOfMonth] en el mes de [reference], ajustando al
/// último día del mes cuando el mes no tiene ese día (ej. 31 en febrero).
DateTime _dayInMonth(DateTime reference, int dayOfMonth) {
  final last = _lastDayOfMonth(reference.year, reference.month);
  return DateTime(reference.year, reference.month, dayOfMonth.clamp(1, last));
}

/// Calcula el siguiente vencimiento ESTRICTAMENTE posterior a [from].
///
/// - [RecurringSchedule.diaDelMes]: la próxima aparición de [dayOfMonth]
///   (este mes si aún no pasó, si no el mes siguiente), con ajuste de mes corto.
/// - [RecurringSchedule.cadaNDias]: `from + intervalDays`.
DateTime nextDueAfter(
  RecurringSchedule type, {
  int? dayOfMonth,
  int? intervalDays,
  required DateTime from,
}) {
  final base = _dateOnly(from);
  switch (type) {
    case RecurringSchedule.diaDelMes:
      assert(dayOfMonth != null, 'diaDelMes requiere dayOfMonth');
      final thisMonth = _dayInMonth(base, dayOfMonth!);
      if (thisMonth.isAfter(base)) return thisMonth;
      // Pasar al mes siguiente.
      final nextMonthRef = DateTime(base.year, base.month + 1, 1);
      return _dayInMonth(nextMonthRef, dayOfMonth);
    case RecurringSchedule.cadaNDias:
      assert(intervalDays != null && intervalDays > 0,
          'cadaNDias requiere intervalDays > 0');
      return base.add(Duration(days: intervalDays!));
  }
}

/// Calcula el primer vencimiento para una regla nueva a partir de una fecha de
/// inicio elegida por el usuario. Para [diaDelMes], si la fecha de inicio cae
/// justo en el día, ese mismo día es el primer vencimiento.
DateTime firstDueFrom(
  RecurringSchedule type, {
  int? dayOfMonth,
  int? intervalDays,
  required DateTime start,
}) {
  final base = _dateOnly(start);
  switch (type) {
    case RecurringSchedule.diaDelMes:
      final thisMonth = _dayInMonth(base, dayOfMonth!);
      if (!thisMonth.isBefore(base)) return thisMonth; // hoy o futuro
      final nextMonthRef = DateTime(base.year, base.month + 1, 1);
      return _dayInMonth(nextMonthRef, dayOfMonth);
    case RecurringSchedule.cadaNDias:
      // El inicio elegido es el primer vencimiento.
      return base;
  }
}

/// Avanza el vencimiento tras un pago.
///
/// - [diaDelMes]: el mismo día del mes siguiente al de [currentDue] (no depende
///   de cuándo se pagó realmente).
/// - [cadaNDias]: [paidDate] + intervalDays (cuenta desde el día real de pago).
DateTime advanceAfterPayment(
  RecurringSchedule type, {
  int? dayOfMonth,
  int? intervalDays,
  required DateTime currentDue,
  required DateTime paidDate,
}) {
  switch (type) {
    case RecurringSchedule.diaDelMes:
      final ref = DateTime(currentDue.year, currentDue.month + 1, 1);
      return _dayInMonth(ref, dayOfMonth!);
    case RecurringSchedule.cadaNDias:
      return _dateOnly(paidDate).add(Duration(days: intervalDays!));
  }
}

/// Todas las fechas de cobro vencidas (≤ [now]) a partir de [nextDue],
/// avanzando según la programación. Para la recuperación de cobros perdidos de
/// reglas automáticas. Devuelve lista vacía si aún no vence nada.
List<DateTime> dueOccurrences({
  required DateTime nextDue,
  required RecurringSchedule type,
  int? dayOfMonth,
  int? intervalDays,
  required DateTime now,
}) {
  final today = _dateOnly(now);
  final occurrences = <DateTime>[];
  var due = _dateOnly(nextDue);
  while (!due.isAfter(today) && occurrences.length < kMaxCatchUpOccurrences) {
    occurrences.add(due);
    due = nextDueAfter(
      type,
      dayOfMonth: dayOfMonth,
      intervalDays: intervalDays,
      from: due,
    );
  }
  return occurrences;
}
