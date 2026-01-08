import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/horario.dart';
import '../../core/utils/time_utils.dart';
import '../entities/profesor_stats.dart';
import '../entities/materia_stats.dart';
import '../entities/salon_availability.dart';
import 'data_provider.dart';

/// Provider para estadisticas generales
final generalStatsProvider = Provider<GeneralStats>((ref) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return GeneralStats.empty();

  final horarios = repo.todos;
  final nrcsUnicos = <int>{};
  final profesoresUnicos = <String>{};
  final materiasUnicas = <String>{};
  final salonesUnicos = <String>{};
  final bloquesUnicos = <String>{};
  final clasesPorBloque = <String, int>{};
  final clasesPorDia = <String, int>{};

  for (final h in horarios) {
    nrcsUnicos.add(h.nrc);
    profesoresUnicos.add(h.profesor);
    materiasUnicas.add(h.nombreMateria);
    salonesUnicos.add(h.nombreSalon);
    bloquesUnicos.add(h.nombreBloque);
    clasesPorBloque[h.nombreBloque] =
        (clasesPorBloque[h.nombreBloque] ?? 0) + 1;
    clasesPorDia[h.dia] = (clasesPorDia[h.dia] ?? 0) + 1;
  }

  return GeneralStats(
    totalClases: horarios.length,
    totalNrcs: nrcsUnicos.length,
    totalProfesores: profesoresUnicos.length,
    totalMaterias: materiasUnicas.length,
    totalSalones: salonesUnicos.length,
    totalBloques: bloquesUnicos.length,
    clasesPorBloque: clasesPorBloque,
    clasesPorDia: clasesPorDia,
  );
});

/// Provider para estadisticas de un profesor
final profesorStatsProvider = Provider.family<ProfesorStats?, String>((
  ref,
  profesor,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return null;

  final horarios = repo.getHorariosPorProfesor(profesor);
  if (horarios.isEmpty) return ProfesorStats.empty(profesor);

  final materiasSet = <String>{};
  final nrcsSet = <int>{};
  double horasTotales = 0;

  for (final h in horarios) {
    materiasSet.add(h.nombreMateria);
    nrcsSet.add(h.nrc);
    horasTotales += TimeUtils.calculateDurationHours(h.horaInicio, h.horaFin);
  }

  return ProfesorStats(
    nombre: profesor,
    clases: horarios.length,
    materias: materiasSet.length,
    horasSemana: horasTotales,
    nrcs: nrcsSet.length,
    materiasSet: materiasSet,
    nrcsSet: nrcsSet,
  );
});

/// Provider para estadisticas de una materia
final materiaStatsProvider = Provider.family<MateriaStats?, String>((
  ref,
  materia,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return null;

  final horarios = repo.getHorariosPorMateria(materia);
  if (horarios.isEmpty) {
    return MateriaStats.empty(materia, '', 0);
  }

  final nrcsSet = <int>{};
  final profesoresSet = <String>{};
  int cuposTotales = 0;
  final visitedNrcs = <int>{};

  for (final h in horarios) {
    nrcsSet.add(h.nrc);
    profesoresSet.add(h.profesor);

    // Solo sumar cupos una vez por NRC
    if (!visitedNrcs.contains(h.nrc)) {
      cuposTotales += h.matriculados + h.cupos;
      visitedNrcs.add(h.nrc);
    }
  }

  return MateriaStats(
    nombre: materia,
    codigoConjunto: horarios.first.codigoConjunto,
    idMateria: horarios.first.idMateria,
    clases: horarios.length,
    nrcs: nrcsSet.length,
    profesores: profesoresSet.length,
    cuposTotales: cuposTotales,
    nrcsSet: nrcsSet,
    profesoresSet: profesoresSet,
  );
});

/// Provider para top profesores (por numero de clases)
final topProfesoresProvider = Provider<List<ProfesorStats>>((ref) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];

  final profesores = repo.profesores;
  final stats = <ProfesorStats>[];

  for (final profesor in profesores) {
    final stat = ref.read(profesorStatsProvider(profesor));
    if (stat != null) {
      stats.add(stat);
    }
  }

  // Ordenar por numero de clases descendente
  stats.sort((a, b) => b.clases.compareTo(a.clases));

  return stats.take(20).toList();
});

/// Provider para top materias (por numero de NRCs)
final topMateriasProvider = Provider<List<MateriaStats>>((ref) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];

  final materias = repo.materias;
  final stats = <MateriaStats>[];

  for (final materia in materias) {
    final stat = ref.read(materiaStatsProvider(materia));
    if (stat != null) {
      stats.add(stat);
    }
  }

  // Ordenar por numero de NRCs descendente
  stats.sort((a, b) => b.nrcs.compareTo(a.nrcs));

  return stats.take(20).toList();
});

/// Provider para horarios de un profesor
final horariosProfesorProvider = Provider.family<List<Horario>, String>((
  ref,
  profesor,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.getHorariosPorProfesor(profesor);
});

/// Provider para horarios de una materia
final horariosMateriaProvider = Provider.family<List<Horario>, String>((
  ref,
  materia,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.getHorariosPorMateria(materia);
});

/// Provider para horarios de un salon
final horariosSalonProvider = Provider.family<List<Horario>, String>((
  ref,
  salon,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.getHorariosPorSalon(salon);
});

/// Provider para horarios de un NRC
final horariosNrcProvider = Provider.family<List<Horario>, int>((ref, nrc) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.getHorariosPorNrc(nrc);
});

/// Provider para horarios de un codigo de conjunto
final horariosCodigoConjuntoProvider = Provider.family<List<Horario>, String>((
  ref,
  codigo,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.getHorariosPorCodigoConjunto(codigo);
});

/// Provider para estadisticas de un salon
final salonStatsProvider = Provider.family<Map<String, dynamic>?, String>((
  ref,
  salon,
) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return null;

  final horarios = repo.getHorariosPorSalon(salon);
  if (horarios.isEmpty) return null;

  final nrcsUnicos = <int>{};
  final materiasUnicas = <String>{};
  final profesoresUnicos = <String>{};
  double horasTotales = 0;

  for (final h in horarios) {
    nrcsUnicos.add(h.nrc);
    materiasUnicas.add(h.nombreMateria);
    profesoresUnicos.add(h.profesor);
    horasTotales += TimeUtils.calculateDurationHours(h.horaInicio, h.horaFin);
  }

  return {
    'clases': horarios.length,
    'nrcs': nrcsUnicos.length,
    'materias': materiasUnicas.length,
    'profesores': profesoresUnicos.length,
    'horasSemana': horasTotales,
    'bloque': horarios.first.nombreBloque,
  };
});

