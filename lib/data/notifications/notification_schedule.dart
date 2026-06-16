import '../../domain/enums.dart';

/// Hora del día (24h) a la que se disparan los recordatorios.
const int kReminderHour = 9;

/// Días de antelación del aviso según el modo de la regla.
/// Automática: 3, 1 y 0 (el día). Manual: 1 y 0.
List<int> reminderOffsetsFor(RecurringMode mode) {
  return switch (mode) {
    RecurringMode.automatica => const [3, 1, 0],
    RecurringMode.manual => const [1, 0],
  };
}

/// Un recordatorio calculado: cuándo dispararlo y a cuántos días del vencimiento.
typedef Reminder = ({int daysBefore, DateTime when});

/// Calcula los recordatorios FUTUROS para una regla, a partir de su próximo
/// vencimiento. Cada aviso se programa a las [kReminderHour] del día
/// correspondiente. Solo se incluyen los que caen después de [now].
///
/// Función pura (sin plugin ni zonas horarias): testeable de forma aislada.
List<Reminder> remindersForRule({
  required RecurringMode mode,
  required DateTime nextDueDate,
  required DateTime now,
}) {
  final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
  final reminders = <Reminder>[];
  for (final daysBefore in reminderOffsetsFor(mode)) {
    final day = due.subtract(Duration(days: daysBefore));
    final when = DateTime(day.year, day.month, day.day, kReminderHour);
    if (when.isAfter(now)) {
      reminders.add((daysBefore: daysBefore, when: when));
    }
  }
  return reminders;
}

/// Texto del aviso según el tipo y los días de antelación.
({String title, String body}) reminderText({
  required String ruleName,
  required RecurringMode mode,
  required int daysBefore,
}) {
  final auto = mode == RecurringMode.automatica;
  final String body;
  if (daysBefore == 0) {
    body = auto ? 'Hoy se cobra "$ruleName".' : 'Hoy vence "$ruleName".';
  } else if (daysBefore == 1) {
    body = auto ? 'Mañana se cobra "$ruleName".' : 'Mañana vence "$ruleName".';
  } else {
    body = auto
        ? 'En $daysBefore días se cobra "$ruleName".'
        : 'En $daysBefore días vence "$ruleName".';
  }
  return (title: 'Pago recurrente', body: body);
}
