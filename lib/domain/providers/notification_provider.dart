import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/notification_service.dart';
import 'mi_horario_provider.dart';

/// Estado de configuracion de notificaciones
class NotificationSettings {
  /// Si las notificaciones estan habilitadas
  final bool enabled;

  /// Minutos de anticipacion antes de la clase
  final int minutesBefore;

  const NotificationSettings({this.enabled = false, this.minutesBefore = 15});

  NotificationSettings copyWith({bool? enabled, int? minutesBefore}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
    );
  }
}

/// Opciones disponibles de minutos de anticipacion
const notificationMinuteOptions = [5, 10, 15, 30, 60];

/// Provider para manejar la configuracion de notificaciones
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _enabledKey = 'notifications_enabled';
  static const _minutesKey = 'notifications_minutes_before';

  @override
  NotificationSettings build() {
    _loadSaved();
    return const NotificationSettings();
  }

  /// Carga configuracion guardada
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final minutes = prefs.getInt(_minutesKey) ?? 15;
    state = NotificationSettings(enabled: enabled, minutesBefore: minutes);

    if (enabled) {
      _scheduleNotifications();
    }
  }

  /// Activa o desactiva las notificaciones
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        state = state.copyWith(enabled: false);
        await prefs.setBool(_enabledKey, false);
        developer.log(
          'Notification permission denied',
          name: 'dispoun.notifications',
        );
        return;
      }
      await _scheduleNotifications();
    } else {
      await NotificationService.cancelAll();
    }
  }

  /// Establece los minutos de anticipacion
  Future<void> setMinutesBefore(int minutes) async {
    state = state.copyWith(minutesBefore: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minutesKey, minutes);

    if (state.enabled) {
      await _scheduleNotifications();
    }
  }

  /// Programa las notificaciones basado en el horario actual
  Future<void> _scheduleNotifications() async {
    final horarios = ref.read(miHorarioHorariosProvider);
    if (horarios.isEmpty) return;

    await NotificationService.initialize();
    await NotificationService.scheduleClassReminders(
      horarios: horarios,
      minutesBefore: state.minutesBefore,
    );
  }

  /// Reprograma las notificaciones (llamar cuando cambian los NRCs)
  Future<void> reschedule() async {
    if (!state.enabled) return;
    await _scheduleNotifications();
  }
}

/// Provider del notificador de configuracion de notificaciones
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
