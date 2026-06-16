import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import 'notification_schedule.dart';

/// Servicio fino sobre `flutter_local_notifications` para los recordatorios de
/// pagos recurrentes. Aísla el plugin del resto de la app.
///
/// Usa modo INEXACTO (`inexactAllowWhileIdle`): no requiere el permiso especial
/// de alarmas exactas y el aviso puede variar unos minutos, irrelevante para
/// recordatorios de días.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'recurring_reminders';
  static const _channelName = 'Pagos recurrentes';
  static const _budgetChannelId = 'budget_alerts';
  static const _budgetChannelName = 'Alertas de presupuesto';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Inicializa zonas horarias, el plugin y pide permiso de notificaciones.
  /// Es idempotente y nunca lanza: si algo falla, la app sigue sin avisos.
  Future<void> init() async {
    if (_ready) return;
    try {
      tz.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init falló: $e');
    }
  }

  /// Reprograma TODOS los avisos a partir de las reglas activas. Como los
  /// recordatorios de pagos son las únicas notificaciones de la app, cancela
  /// todo y vuelve a programar. Se llama cada vez que cambian las reglas.
  Future<void> syncAll(List<RecurringRuleRow> rules) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      for (final rule in rules) {
        if (!rule.active || rule.archived) continue;
        await _scheduleRule(rule, now);
      }
    } catch (e) {
      debugPrint('NotificationService syncAll falló: $e');
    }
  }

  Future<void> _scheduleRule(RecurringRuleRow rule, DateTime now) async {
    final reminders = remindersForRule(
      mode: rule.mode,
      nextDueDate: rule.nextDueDate,
      now: now,
    );
    for (final r in reminders) {
      final text = reminderText(
        ruleName: rule.name,
        mode: rule.mode,
        daysBefore: r.daysBefore,
      );
      await _plugin.zonedSchedule(
        _notificationId(rule.id, r.daysBefore),
        text.title,
        text.body,
        tz.TZDateTime.from(r.when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Recordatorios de suscripciones y facturas',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Id estable y positivo por (regla, díasAntes), para no duplicar avisos.
  int _notificationId(String ruleId, int daysBefore) {
    final base = ruleId.hashCode & 0x0FFFFFFF; // positivo y acotado
    return base * 10 + daysBefore;
  }

  /// Muestra una alerta inmediata al cruzar un umbral de presupuesto.
  Future<void> showBudgetAlert({
    required String budgetId,
    required String categoryName,
    required int threshold,
  }) async {
    if (!_ready) return;
    try {
      final body = threshold >= 100
          ? '$categoryName: alcanzaste el 100% del presupuesto.'
          : '$categoryName: llevas el $threshold% del presupuesto.';
      await _plugin.show(
        (budgetId.hashCode & 0x0FFFFFFF) * 10 + threshold ~/ 10,
        'Presupuesto',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId,
            _budgetChannelName,
            channelDescription: 'Avisos al acercarte al límite de una categoría',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('NotificationService showBudgetAlert falló: $e');
    }
  }
}
