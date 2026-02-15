import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/horario.dart';

/// Servicio para manejar notificaciones locales de recordatorio de clase
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Canal de notificaciones Android para recordatorios de clase
  static const _androidChannel = AndroidNotificationChannel(
    'class_reminders',
    'Recordatorios de clase',
    description: 'Notificaciones de recordatorio antes de cada clase',
    importance: Importance.high,
  );

  /// Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Crear canal en Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannel.id,
        _androidChannel.name,
        description: _androidChannel.description,
        importance: _androidChannel.importance,
      ),
    );

    _initialized = true;
    developer.log(
      'NotificationService initialized',
      name: 'dispoun.notifications',
    );
  }

  /// Solicita permiso para enviar notificaciones
  static Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    // Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();

    // iOS
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? false;
  }

  /// Programa recordatorios semanales para todas las clases del horario
  static Future<void> scheduleClassReminders({
    required List<Horario> horarios,
    required int minutesBefore,
  }) async {
    if (!_initialized) await initialize();

    // Cancelar todas las notificaciones existentes primero
    await cancelAll();

    int notificationId = 0;

    for (final horario in horarios) {
      final dayOfWeek = _getDayOfWeek(horario.dia);
      if (dayOfWeek == null) continue;

      final classTime = _parseTime(horario.horaInicio);
      if (classTime == null) continue;

      // Calcular la proxima ocurrencia de esta clase
      final nextClassTime = _getNextWeekday(dayOfWeek, classTime);
      final reminderTime = nextClassTime.subtract(
        Duration(minutes: minutesBefore),
      );

      // Solo programar si el recordatorio esta en el futuro
      if (reminderTime.isAfter(tz.TZDateTime.now(tz.local))) {
        try {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: horario.nombreMateria,
            body:
                'En $minutesBefore min en salon ${horario.nombreSalon}'
                ' - ${horario.profesor}',
            scheduledDate: reminderTime,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          notificationId++;
        } catch (e) {
          developer.log(
            'Error scheduling notification: $e',
            name: 'dispoun.notifications',
            level: 900,
          );
        }
      }
    }

    developer.log(
      'Scheduled $notificationId class reminders ($minutesBefore min before)',
      name: 'dispoun.notifications',
    );
  }

  /// Cancela todas las notificaciones programadas
  static Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
    developer.log('All notifications cancelled', name: 'dispoun.notifications');
  }

  /// Convierte el dia de la semana del formato del horario a int (1=Lunes)
  static int? _getDayOfWeek(String dia) {
    const days = {
      'L': DateTime.monday,
      'M': DateTime.tuesday,
      'X': DateTime.wednesday,
      'J': DateTime.thursday,
      'V': DateTime.friday,
      'S': DateTime.saturday,
      'D': DateTime.sunday,
    };
    return days[dia.toUpperCase()];
  }

  /// Parsea una hora en formato "HH:mm:ss" o "HH:mm"
  @visibleForTesting
  static ({int hour, int minute})? parseTime(String time) => _parseTime(time);

  static ({int hour, int minute})? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour: hour, minute: minute);
  }

  /// Obtiene la proxima ocurrencia de un dia de la semana con hora
  static tz.TZDateTime _getNextWeekday(
    int dayOfWeek,
    ({int hour, int minute}) time,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Avanzar al dia de la semana correcto
    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Si ya paso, avanzar una semana
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
