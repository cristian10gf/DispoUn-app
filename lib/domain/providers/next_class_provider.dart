import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/horario.dart';
import '../../core/utils/time_utils.dart';
import 'mi_horario_provider.dart';

/// Informacion de la proxima clase
class NextClassInfo {
  final Horario horario;
  final String nombreMateria;
  final Duration timeUntil;

  const NextClassInfo({
    required this.horario,
    required this.nombreMateria,
    required this.timeUntil,
  });

  /// Formato legible del tiempo restante
  String get timeUntilFormatted {
    if (timeUntil.inMinutes < 1) return 'Ahora';
    if (timeUntil.inMinutes < 60) return 'En ${timeUntil.inMinutes} min';
    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes % 60;
    if (minutes == 0) return 'En $hours h';
    return 'En $hours h $minutes min';
  }

  /// Hora de inicio formateada
  String get horaFormateada {
    return TimeUtils.formatTime(horario.horaInicio);
  }
}

/// Provider para la proxima clase del dia
final nextClassProvider = Provider<NextClassInfo?>((ref) {
  final horarios = ref.watch(miHorarioHorariosProvider);
  if (horarios.isEmpty) return null;

  final now = DateTime.now();
  final todayDia = _getDiaHoy(now.weekday);

  // Filtrar clases de hoy
  final todayClasses = horarios.where((h) => h.dia == todayDia).toList();
  if (todayClasses.isEmpty) return null;

  // Ordenar por hora de inicio
  todayClasses.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));

  // Encontrar la proxima clase que aun no ha terminado
  for (final horario in todayClasses) {
    final endTime = _parseTimeToday(horario.horaFin, now);
    if (endTime == null) continue;

    if (endTime.isAfter(now)) {
      final startTime = _parseTimeToday(horario.horaInicio, now);
      if (startTime == null) continue;

      final timeUntil = startTime.difference(now);

      return NextClassInfo(
        horario: horario,
        nombreMateria: horario.nombreMateria,
        timeUntil: timeUntil.isNegative ? Duration.zero : timeUntil,
      );
    }
  }

  return null;
});

String _getDiaHoy(int weekday) {
  const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  return dias[(weekday - 1).clamp(0, 6)];
}

DateTime? _parseTimeToday(String time, DateTime today) {
  final parts = time.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(today.year, today.month, today.day, hour, minute);
}
