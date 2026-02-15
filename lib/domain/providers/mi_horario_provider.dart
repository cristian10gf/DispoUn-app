import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/horario.dart';
import '../../data/models/mi_horario_config.dart';
import '../../data/services/mi_horario_storage_service.dart';
import 'data_provider.dart';

/// Estado de Mi Horario
class MiHorarioState {
  final MiHorarioConfig config;
  final bool isLoading;
  final String? error;

  const MiHorarioState({
    this.config = const MiHorarioConfig(),
    this.isLoading = false,
    this.error,
  });

  MiHorarioState copyWith({
    MiHorarioConfig? config,
    bool? isLoading,
    String? error,
  }) {
    return MiHorarioState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Indica si hay NRCs configurados
  bool get tieneNrcs => config.tieneNrcs;

  /// Lista de NRCs
  List<int> get nrcs => config.nrcs;

  /// Si Mi Horario es la pantalla principal
  bool get esPantallaPrincipal => config.esPantallaPrincipal;
}

/// Provider para manejar el estado de Mi Horario
class MiHorarioNotifier extends Notifier<MiHorarioState> {
  @override
  MiHorarioState build() {
    Future.microtask(() => _initialize());
    return const MiHorarioState();
  }

  /// Inicializa cargando la configuracion guardada
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      final config = await MiHorarioStorageService.loadConfig();
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar configuracion: $e',
      );
    }
  }

  /// Agrega un NRC a la lista
  Future<bool> addNrc(int nrc) async {
    // Validar que el NRC existe en los datos
    final repo = ref.read(repositoryProvider);
    if (repo == null) {
      state = state.copyWith(error: 'No hay datos cargados');
      return false;
    }

    final horarios = repo.getHorariosPorNrc(nrc);
    if (horarios.isEmpty) {
      state = state.copyWith(error: 'NRC $nrc no encontrado');
      return false;
    }

    // Verificar si ya existe
    if (state.config.nrcs.contains(nrc)) {
      state = state.copyWith(error: 'NRC $nrc ya esta agregado');
      return false;
    }

    try {
      final newConfig = await MiHorarioStorageService.addNrc(nrc);
      state = state.copyWith(config: newConfig, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Error al agregar NRC: $e');
      return false;
    }
  }

  /// Agrega multiples NRCs a la vez
  Future<AddNrcsResult> addMultipleNrcs(List<int> nrcs) async {
    final repo = ref.read(repositoryProvider);
    if (repo == null) {
      return AddNrcsResult(
        agregados: [],
        noEncontrados: nrcs,
        yaExistentes: [],
      );
    }

    final agregados = <int>[];
    final noEncontrados = <int>[];
    final yaExistentes = <int>[];

    for (final nrc in nrcs) {
      // Verificar si ya existe
      if (state.config.nrcs.contains(nrc)) {
        yaExistentes.add(nrc);
        continue;
      }

      // Verificar si el NRC existe en los datos
      final horarios = repo.getHorariosPorNrc(nrc);
      if (horarios.isEmpty) {
        noEncontrados.add(nrc);
        continue;
      }

      // Agregar
      try {
        final newConfig = await MiHorarioStorageService.addNrc(nrc);
        state = state.copyWith(config: newConfig, error: null);
        agregados.add(nrc);
      } catch (e) {
        noEncontrados.add(nrc);
      }
    }

    return AddNrcsResult(
      agregados: agregados,
      noEncontrados: noEncontrados,
      yaExistentes: yaExistentes,
    );
  }

  /// Remueve un NRC de la lista
  Future<void> removeNrc(int nrc) async {
    try {
      final newConfig = await MiHorarioStorageService.removeNrc(nrc);
      state = state.copyWith(config: newConfig, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Error al remover NRC: $e');
    }
  }

  /// Limpia todos los NRCs
  Future<void> clearNrcs() async {
    try {
      final newConfig = await MiHorarioStorageService.clearNrcs();
      state = state.copyWith(config: newConfig, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Error al limpiar NRCs: $e');
    }
  }

  /// Establece si Mi Horario es la pantalla principal
  Future<void> setPantallaPrincipal(bool value) async {
    try {
      final newConfig = await MiHorarioStorageService.setPantallaPrincipal(
        value,
      );
      state = state.copyWith(config: newConfig, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Error al cambiar configuracion: $e');
    }
  }

  /// Limpia el error actual
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Resultado de agregar multiples NRCs
class AddNrcsResult {
  final List<int> agregados;
  final List<int> noEncontrados;
  final List<int> yaExistentes;

  const AddNrcsResult({
    required this.agregados,
    required this.noEncontrados,
    required this.yaExistentes,
  });

  bool get todosBien => noEncontrados.isEmpty && yaExistentes.isEmpty;
  bool get algunoAgregado => agregados.isNotEmpty;
}

/// Provider del notificador de Mi Horario
final miHorarioNotifierProvider =
    NotifierProvider<MiHorarioNotifier, MiHorarioState>(MiHorarioNotifier.new);

/// Provider para obtener los horarios filtrados por NRCs del usuario
final miHorarioHorariosProvider = Provider<List<Horario>>((ref) {
  final miHorarioState = ref.watch(miHorarioNotifierProvider);
  final repo = ref.watch(repositoryProvider);

  if (repo == null || !miHorarioState.tieneNrcs) {
    return [];
  }

  final horarios = <Horario>[];
  for (final nrc in miHorarioState.nrcs) {
    horarios.addAll(repo.getHorariosPorNrc(nrc));
  }

  return horarios;
});

/// Provider para obtener informacion de un NRC
final nrcInfoProvider = Provider.family<NrcInfo?, int>((ref, nrc) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return null;

  final horarios = repo.getHorariosPorNrc(nrc);
  if (horarios.isEmpty) return null;

  final first = horarios.first;
  return NrcInfo(
    nrc: nrc,
    nombreMateria: first.nombreMateria,
    profesor: first.profesor,
    cupos: first.cupos,
    matriculados: first.matriculados,
    codigoConjunto: first.codigoConjunto,
    modalidad: first.modalidad,
  );
});

/// Informacion basica de un NRC
class NrcInfo {
  final int nrc;
  final String nombreMateria;
  final String profesor;
  final int cupos;
  final int matriculados;
  final String codigoConjunto;
  final String modalidad;

  const NrcInfo({
    required this.nrc,
    required this.nombreMateria,
    required this.profesor,
    required this.cupos,
    required this.matriculados,
    required this.codigoConjunto,
    required this.modalidad,
  });

  int get cuposDisponibles => cupos - matriculados;
}
