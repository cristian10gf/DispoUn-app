import 'package:intl/intl.dart';

/// Utilidades para manejo de tiempo y fechas
class TimeUtils {
  TimeUtils._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _fullDateFormat = DateFormat(
    'EEEE, d MMMM yyyy',
    'es',
  );

  /// Parsea una hora en formato "HH:mm:ss" a minutos desde medianoche
  static int parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }

  /// Convierte minutos desde medianoche a formato "HH:mm"
  static String minutesToTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Calcula la duracion en horas entre dos tiempos
  static double calculateDurationHours(String horaInicio, String horaFin) {
    final inicio = parseTimeToMinutes(horaInicio);
    final fin = parseTimeToMinutes(horaFin);
    return (fin - inicio) / 60.0;
  }

  /// Verifica si un horario se superpone con un rango de tiempo
  static bool isTimeOverlapping(
    String horaInicio1,
    String horaFin1,
    String horaInicio2,
    String horaFin2,
  ) {
    final inicio1 = parseTimeToMinutes(horaInicio1);
    final fin1 = parseTimeToMinutes(horaFin1);
    final inicio2 = parseTimeToMinutes(horaInicio2);
    final fin2 = parseTimeToMinutes(horaFin2);

    return inicio1 < fin2 && fin1 > inicio2;
  }

  /// Verifica si una hora esta dentro de un rango
  static bool isTimeInRange(String time, String rangeStart, String rangeEnd) {
    final t = parseTimeToMinutes(time);
    final start = parseTimeToMinutes(rangeStart);
    final end = parseTimeToMinutes(rangeEnd);
    return t >= start && t < end;
  }

  /// Formatea una hora para mostrar
  static String formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  /// Formatea una fecha para mostrar
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formatea una fecha completa con nombre del dia
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Genera lista de franjas horarias (para el grid de horarios)
  static List<String> generateTimeSlots({
    int startHour = 6,
    int endHour = 21,
    int intervalMinutes = 60,
  }) {
    final slots = <String>[];
    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += intervalMinutes) {
        final time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(time);
      }
    }
    return slots;
  }

  /// Obtiene la franja horaria actual
  static String getCurrentTimeSlot() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:00';
  }

  /// Obtiene el indice de la fila en el grid para una hora
  static int getRowIndexForTime(String time, {int startHour = 6}) {
    final minutes = parseTimeToMinutes(time);
    final startMinutes = startHour * 60;
    return (minutes - startMinutes) ~/ 60;
  }

  /// Calcula cuantas filas ocupa un horario en el grid
  static int getRowSpanForSchedule(String horaInicio, String horaFin) {
    final inicio = parseTimeToMinutes(horaInicio);
    final fin = parseTimeToMinutes(horaFin);
    final duration = fin - inicio;
    return (duration / 60).ceil();
  }
}
