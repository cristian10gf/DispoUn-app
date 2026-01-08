import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_availability.freezed.dart';

/// Disponibilidad de un salon
@freezed
class SalonAvailability with _$SalonAvailability {
  const factory SalonAvailability({
    required String nombreSalon,
    required String nombreBloque,
    required bool disponible,
    String? ocupadoPor, // Nombre de la materia que lo ocupa
    String? profesor,
    int? nrc,
  }) = _SalonAvailability;
}

/// Filtros para consultar disponibilidad
@freezed
class AvailabilityFilter with _$AvailabilityFilter {
  const factory AvailabilityFilter({
    required String horaInicio,
    required String horaFin,
    required String dia,
    String? bloque,
    String? salon,
    @Default(false) bool incluirNoDisponibles,
    DateTime? fecha,
  }) = _AvailabilityFilter;

  const AvailabilityFilter._();

  /// Filtro por defecto: hora actual + 1 hora, dia actual
  factory AvailabilityFilter.defaultFilter() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final dia = _getDiaActual(now.weekday);

    return AvailabilityFilter(
      horaInicio: '${currentHour.toString().padLeft(2, '0')}:00:00',
      horaFin: '${(currentHour + 1).toString().padLeft(2, '0')}:00:00',
      dia: dia,
      fecha: now,
    );
  }

  static String _getDiaActual(int weekday) {
    const dias = ['L', 'M', 'I', 'J', 'V', 'S', 'S'];
    return dias[weekday - 1];
  }
}

/// Estadisticas generales
@freezed
class GeneralStats with _$GeneralStats {
  const factory GeneralStats({
    required int totalClases,
    required int totalNrcs,
    required int totalProfesores,
    required int totalMaterias,
    required int totalSalones,
    required int totalBloques,
    required Map<String, int> clasesPorBloque,
    required Map<String, int> clasesPorDia,
  }) = _GeneralStats;

  const GeneralStats._();

  factory GeneralStats.empty() => const GeneralStats(
    totalClases: 0,
    totalNrcs: 0,
    totalProfesores: 0,
    totalMaterias: 0,
    totalSalones: 0,
    totalBloques: 0,
    clasesPorBloque: {},
    clasesPorDia: {},
  );
}
