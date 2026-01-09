import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/horario_repository.dart';
import '../../data/services/file_storage_service.dart';
import '../../data/services/json_parser_service.dart';

/// Estado del repositorio de datos
class DataState {
  final HorarioRepository? repository;
  final bool isLoading;
  final String? error;
  /// Lista de rutas de archivos activos (puede ser uno o varios combinados)
  final List<String> activeFilePaths;
  final List<FileInfo> availableFiles;

  const DataState({
    this.repository,
    this.isLoading = false,
    this.error,
    this.activeFilePaths = const [],
    this.availableFiles = const [],
  });

  /// Compatibilidad: obtiene el primer archivo activo o null
  String? get activeFilePath =>
      activeFilePaths.isNotEmpty ? activeFilePaths.first : null;

  /// Indica si hay multiples archivos combinados
  bool get isMultipleFiles => activeFilePaths.length > 1;

  DataState copyWith({
    HorarioRepository? repository,
    bool? isLoading,
    String? error,
    List<String>? activeFilePaths,
    List<FileInfo>? availableFiles,
  }) {
    return DataState(
      repository: repository ?? this.repository,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeFilePaths: activeFilePaths ?? this.activeFilePaths,
      availableFiles: availableFiles ?? this.availableFiles,
    );
  }
}

/// Provider principal para el estado de datos
class DataNotifier extends StateNotifier<DataState> {
  DataNotifier() : super(const DataState());

  /// Inicializa cargando datos desde assets o archivo guardado
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Primero intentar cargar archivos guardados
      final files = await FileStorageService.listJsonFiles();

      if (files.isNotEmpty) {
        // Cargar el archivo mas reciente
        await loadFromFile(files.first.path);
        state = state.copyWith(availableFiles: files);
      } else {
        // Cargar desde assets si existe
        await _loadFromAssets();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al inicializar: $e',
      );
    }
  }

  /// Carga datos desde assets
  Future<void> _loadFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/datos.json');

      // Guardar en almacenamiento local
      final savedPath = await FileStorageService.saveJsonFile(
        jsonString,
        'datos.json',
      );

      if (savedPath != null) {
        final repository = await HorarioRepository.fromJsonString(jsonString);
        final files = await FileStorageService.listJsonFiles();

        state = state.copyWith(
          repository: repository,
          isLoading: false,
          activeFilePaths: [savedPath],
          availableFiles: files,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se encontro archivo de datos',
      );
    }
  }

  /// Carga datos desde un archivo especifico (reemplaza la seleccion actual)
  Future<void> loadFromFile(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = await HorarioRepository.fromJsonFile(filePath);
      final files = await FileStorageService.listJsonFiles();

      state = state.copyWith(
        repository: repository,
        isLoading: false,
        activeFilePaths: [filePath],
        availableFiles: files,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar archivo: $e',
      );
    }
  }

  /// Carga datos desde multiples archivos (combina la informacion)
  Future<void> loadFromMultipleFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      state = state.copyWith(
        repository: null,
        activeFilePaths: [],
      );
      return;
    }

    // Si solo hay un archivo, usar el metodo simple
    if (filePaths.length == 1) {
      await loadFromFile(filePaths.first);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cargar todos los repositorios
      final repositories = <HorarioRepository>[];
      for (final path in filePaths) {
        final repo = await HorarioRepository.fromJsonFile(path);
        repositories.add(repo);
      }

      // Combinar todos los repositorios
      final combinedRepository = HorarioRepository.combine(repositories);
      final files = await FileStorageService.listJsonFiles();

      state = state.copyWith(
        repository: combinedRepository,
        isLoading: false,
        activeFilePaths: filePaths,
        availableFiles: files,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al combinar archivos: $e',
      );
    }
  }

  /// Agrega un archivo a la seleccion actual (combina datos)
  Future<void> addFileToSelection(String filePath) async {
    final currentPaths = List<String>.from(state.activeFilePaths);
    if (currentPaths.contains(filePath)) return;

    currentPaths.add(filePath);
    await loadFromMultipleFiles(currentPaths);
  }

  /// Remueve un archivo de la seleccion actual
  Future<void> removeFileFromSelection(String filePath) async {
    final currentPaths = List<String>.from(state.activeFilePaths);
    currentPaths.remove(filePath);
    await loadFromMultipleFiles(currentPaths);
  }

  /// Alterna la seleccion de un archivo
  Future<void> toggleFileSelection(String filePath) async {
    if (state.activeFilePaths.contains(filePath)) {
      await removeFileFromSelection(filePath);
    } else {
      await addFileToSelection(filePath);
    }
  }

  /// Verifica si un archivo esta seleccionado
  bool isFileSelected(String filePath) {
    return state.activeFilePaths.contains(filePath);
  }

  /// Importa un nuevo archivo JSON
  Future<bool> importFile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await FileStorageService.importJsonFile();

      if (result == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Validar formato
      final isValid = await JsonParserService.validateJsonFormat(
        result.content,
      );
      if (!isValid) {
        state = state.copyWith(
          isLoading: false,
          error: 'El archivo no tiene un formato valido',
        );
        return false;
      }

      // Cargar datos
      final repository = await HorarioRepository.fromJsonString(result.content);
      final files = await FileStorageService.listJsonFiles();

      state = state.copyWith(
        repository: repository,
        isLoading: false,
        activeFilePaths: [result.filePath],
        availableFiles: files,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al importar archivo: $e',
      );
      return false;
    }
  }

  /// Elimina un archivo JSON
  Future<bool> deleteFile(String filePath) async {
    final deleted = await FileStorageService.deleteJsonFile(filePath);

    if (deleted) {
      final files = await FileStorageService.listJsonFiles();
      final currentPaths = List<String>.from(state.activeFilePaths);

      // Remover el archivo de la seleccion si estaba seleccionado
      currentPaths.remove(filePath);

      if (currentPaths.isEmpty && files.isNotEmpty) {
        // Si no quedan archivos seleccionados, cargar el primero disponible
        await loadFromFile(files.first.path);
      } else if (files.isEmpty) {
        state = state.copyWith(
          repository: null,
          activeFilePaths: [],
          availableFiles: [],
        );
      } else if (currentPaths.isEmpty) {
        state = state.copyWith(
          repository: null,
          activeFilePaths: [],
          availableFiles: files,
        );
      } else {
        // Recargar con los archivos restantes
        await loadFromMultipleFiles(currentPaths);
      }
    }

    return deleted;
  }

  /// Actualiza la lista de archivos disponibles
  Future<void> refreshFileList() async {
    final files = await FileStorageService.listJsonFiles();
    state = state.copyWith(availableFiles: files);
  }
}

/// Provider del notificador de datos
final dataNotifierProvider = StateNotifierProvider<DataNotifier, DataState>((
  ref,
) {
  final notifier = DataNotifier();
  notifier.initialize();
  return notifier;
});

/// Provider para acceder al repositorio directamente
final repositoryProvider = Provider<HorarioRepository?>((ref) {
  return ref.watch(dataNotifierProvider).repository;
});

/// Provider para verificar si hay datos cargados
final hasDataProvider = Provider<bool>((ref) {
  return ref.watch(repositoryProvider) != null;
});

/// Provider para la lista de profesores
final profesoresListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo?.profesores ?? [];
});

/// Provider para la lista de materias
final materiasListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo?.materias ?? [];
});

/// Nombres de bloques a excluir
const _bloquesExcluidos = ['Bloque Sin Especificar', 'Sin Especificar', 'NNS'];

/// Provider para la lista de bloques (excluyendo bloques sin especificar)
final bloquesListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  if (repo == null) return [];
  return repo.bloques
      .where((b) => !_bloquesExcluidos.any(
            (excluido) => b.toLowerCase().contains(excluido.toLowerCase()),
          ))
      .toList();
});

/// Provider para la lista de salones
final salonesListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo?.salones ?? [];
});

/// Provider para la lista de codigos de conjunto
final codigosConjuntoProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo?.codigosConjunto ?? [];
});
