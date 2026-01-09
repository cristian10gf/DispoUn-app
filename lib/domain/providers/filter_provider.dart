import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/horario_repository.dart';
import 'data_provider.dart';

/// Tipo de filtro de disponibilidad
enum DisponibilidadFiltro { todos, disponibles, ocupados }

/// Estado de los filtros de disponibilidad
class AvailabilityFilterState {
  final String horaInicio;
  final String horaFin;
  final String dia;
  final String? bloque;
  final bool incluirOcupados;
  final DisponibilidadFiltro disponibilidadFiltro;

  const AvailabilityFilterState({
    required this.horaInicio,
    required this.horaFin,
    required this.dia,
    this.bloque,
    this.incluirOcupados = false,
    this.disponibilidadFiltro = DisponibilidadFiltro.todos,
  });

  factory AvailabilityFilterState.defaultState() {
    final now = DateTime.now();
    final currentHour = now.hour.clamp(6, 20);
    final nextHour = (currentHour + 1).clamp(7, 21);
    final dia = _getDiaActual(now.weekday);

    return AvailabilityFilterState(
      horaInicio: '${currentHour.toString().padLeft(2, '0')}:00:00',
      horaFin: '${nextHour.toString().padLeft(2, '0')}:00:00',
      dia: dia,
    );
  }

  static String _getDiaActual(int weekday) {
    const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final index = (weekday - 1).clamp(0, 6);
    return dias[index];
  }

  AvailabilityFilterState copyWith({
    String? horaInicio,
    String? horaFin,
    String? dia,
    String? bloque,
    bool? incluirOcupados,
    DisponibilidadFiltro? disponibilidadFiltro,
    bool clearBloque = false,
  }) {
    return AvailabilityFilterState(
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      dia: dia ?? this.dia,
      bloque: clearBloque ? null : (bloque ?? this.bloque),
      incluirOcupados: incluirOcupados ?? this.incluirOcupados,
      disponibilidadFiltro: disponibilidadFiltro ?? this.disponibilidadFiltro,
    );
  }
}

/// Notificador de filtros de disponibilidad
class AvailabilityFilterNotifier
    extends StateNotifier<AvailabilityFilterState> {
  AvailabilityFilterNotifier() : super(AvailabilityFilterState.defaultState());

  void setHoraInicio(String hora) {
    state = state.copyWith(horaInicio: hora);
  }

  void setHoraFin(String hora) {
    state = state.copyWith(horaFin: hora);
  }

  void setDia(String dia) {
    state = state.copyWith(dia: dia);
  }

  void setBloque(String? bloque) {
    if (bloque == null) {
      state = state.copyWith(clearBloque: true);
    } else {
      state = state.copyWith(bloque: bloque);
    }
  }

  void setIncluirOcupados(bool incluir) {
    state = state.copyWith(incluirOcupados: incluir);
  }

  void setDisponibilidadFiltro(DisponibilidadFiltro filtro) {
    state = state.copyWith(disponibilidadFiltro: filtro);
  }

  void reset() {
    state = AvailabilityFilterState.defaultState();
  }
}

/// Provider del notificador de filtros
final availabilityFilterProvider =
    StateNotifierProvider<AvailabilityFilterNotifier, AvailabilityFilterState>(
      (ref) => AvailabilityFilterNotifier(),
    );

/// Nombres de bloques a excluir
const _bloquesExcluidos = ['Bloque Sin Especificar', 'Sin Especificar', 'NNS'];

/// Provider para los resultados de disponibilidad
final salonesDisponiblesProvider = Provider<List<SalonDisponibilidad>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final filter = ref.watch(availabilityFilterProvider);

  if (repo == null) return [];

  // Siempre incluir ocupados para poder filtrar despues
  final todosLosSalones = repo.getSalonesDisponibles(
    horaInicio: filter.horaInicio,
    horaFin: filter.horaFin,
    dia: filter.dia,
    bloque: filter.bloque,
    incluirOcupados: true,
  );

  // Filtrar bloques sin especificar
  var resultado = todosLosSalones.where((s) => !_bloquesExcluidos.any(
        (excluido) => s.nombreBloque.toLowerCase().contains(excluido.toLowerCase()),
      )).toList();

  // Aplicar filtro de disponibilidad
  switch (filter.disponibilidadFiltro) {
    case DisponibilidadFiltro.disponibles:
      resultado = resultado.where((s) => s.disponible).toList();
      break;
    case DisponibilidadFiltro.ocupados:
      resultado = resultado.where((s) => !s.disponible).toList();
      break;
    case DisponibilidadFiltro.todos:
      // No filtrar
      break;
  }

  return resultado;
});

/// Provider para salones sin filtro de disponibilidad (para contar totales)
final salonesDisponiblesSinFiltroProvider = Provider<List<SalonDisponibilidad>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final filter = ref.watch(availabilityFilterProvider);

  if (repo == null) return [];

  final todosLosSalones = repo.getSalonesDisponibles(
    horaInicio: filter.horaInicio,
    horaFin: filter.horaFin,
    dia: filter.dia,
    bloque: filter.bloque,
    incluirOcupados: true,
  );

  // Solo filtrar bloques sin especificar
  return todosLosSalones.where((s) => !_bloquesExcluidos.any(
        (excluido) => s.nombreBloque.toLowerCase().contains(excluido.toLowerCase()),
      )).toList();
});

/// Provider para busqueda de profesores
final profesorSearchQueryProvider = StateProvider<String>((ref) => '');

final profesoresFilteredProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final query = ref.watch(profesorSearchQueryProvider);

  if (repo == null) return [];
  return repo.buscarProfesores(query);
});

/// Provider para busqueda de materias
final materiaSearchQueryProvider = StateProvider<String>((ref) => '');

final materiasFilteredProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  final query = ref.watch(materiaSearchQueryProvider);

  if (repo == null) return [];
  return repo.buscarMaterias(query);
});

/// Provider para profesor seleccionado (para vista de detalle)
final selectedProfesorProvider = StateProvider<String?>((ref) => null);

/// Provider para materia seleccionada
final selectedMateriaProvider = StateProvider<String?>((ref) => null);

/// Provider para NRC seleccionado
final selectedNrcProvider = StateProvider<int?>((ref) => null);

/// Provider para salon seleccionado
final selectedSalonProvider = StateProvider<String?>((ref) => null);

/// Provider para codigo de conjunto seleccionado
final selectedCodigoConjuntoProvider = StateProvider<String?>((ref) => null);
