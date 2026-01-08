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
  final String? activeFilePath;
  final List<FileInfo> availableFiles;

  const DataState({
    this.repository,
    this.isLoading = false,
    this.error,
    this.activeFilePath,
    this.availableFiles = const [],
  });

  DataState copyWith({
    HorarioRepository? repository,
    bool? isLoading,
    String? error,
    String? activeFilePath,
    List<FileInfo>? availableFiles,
  }) {
    return DataState(
      repository: repository ?? this.repository,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeFilePath: activeFilePath ?? this.activeFilePath,
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
          activeFilePath: savedPath,
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

  /// Carga datos desde un archivo especifico
  Future<void> loadFromFile(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = await HorarioRepository.fromJsonFile(filePath);
      final files = await FileStorageService.listJsonFiles();

      state = state.copyWith(
        repository: repository,
        isLoading: false,
        activeFilePath: filePath,
        availableFiles: files,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar archivo: $e',
      );
    }
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
        activeFilePath: result.filePath,
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

      // Si se elimino el archivo activo, cargar otro
      if (filePath == state.activeFilePath && files.isNotEmpty) {
        await loadFromFile(files.first.path);
      } else if (files.isEmpty) {
        state = state.copyWith(
          repository: null,
          activeFilePath: null,
          availableFiles: [],
        );
      } else {
        state = state.copyWith(availableFiles: files);
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

/// Provider para la lista de bloques
final bloquesListProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo?.bloques ?? [];
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
