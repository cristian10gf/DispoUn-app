import '../models/horario.dart';
import '../services/json_parser_service.dart';
import '../services/file_storage_service.dart';
import '../../core/utils/time_utils.dart';

/// Repositorio para acceder y procesar datos de horarios
class HorarioRepository {
  final List<Horario> _horarios;
  final HorarioIndex _index;

  HorarioRepository._(this._horarios, this._index);

  /// Carga horarios desde un archivo JSON
  static Future<HorarioRepository> fromJsonFile(String filePath) async {
    final content = await FileStorageService.readJsonFile(filePath);
    if (content == null) {
      throw Exception('No se pudo leer el archivo');
    }
    return fromJsonString(content);
  }

  /// Carga horarios desde un string JSON
  static Future<HorarioRepository> fromJsonString(String jsonString) async {
    final horarios = await JsonParserService.parseHorarios(jsonString);
    final index = HorarioIndex.build(horarios);
    return HorarioRepository._(horarios, index);
  }

  /// Combina multiples repositorios en uno solo
  /// Los horarios duplicados se eliminan basandose en NRC + dia + hora
  static HorarioRepository combine(List<HorarioRepository> repositories) {
    if (repositories.isEmpty) {
      return HorarioRepository._([], HorarioIndex.build([]));
    }

    if (repositories.length == 1) {
      return repositories.first;
    }

    // Combinar todos los horarios eliminando duplicados
    final Set<String> seen = {};
    final List<Horario> combinedHorarios = [];

    for (final repo in repositories) {
      for (final horario in repo._horarios) {
        // Crear clave unica basada en NRC, dia y hora
        final key =
            '${horario.nrc}_${horario.dia}_${horario.horaInicio}_${horario.horaFin}';
        if (!seen.contains(key)) {
          seen.add(key);
          combinedHorarios.add(horario);
        }
      }
    }

    final index = HorarioIndex.build(combinedHorarios);
    return HorarioRepository._(combinedHorarios, index);
  }

  /// Obtiene todos los horarios
  List<Horario> get todos => _horarios;

  /// Obtiene el total de horarios
  int get total => _horarios.length;

  // ==================== CONSULTAS POR INDICE ====================

  /// Obtiene horarios de un profesor
  List<Horario> getHorariosPorProfesor(String profesor) {
    return _index.porProfesor[profesor] ?? [];
  }

  /// Obtiene horarios de un salon
  List<Horario> getHorariosPorSalon(String salon) {
    return _index.porSalon[salon] ?? [];
  }

  /// Obtiene horarios de un bloque
  List<Horario> getHorariosPorBloque(String bloque) {
    return _index.porBloque[bloque] ?? [];
  }

  /// Obtiene horarios por NRC
  List<Horario> getHorariosPorNrc(int nrc) {
    return _index.porNrc[nrc] ?? [];
  }

  /// Obtiene horarios por dia
  List<Horario> getHorariosPorDia(String dia) {
    return _index.porDia[dia] ?? [];
  }

  /// Obtiene horarios por materia
  List<Horario> getHorariosPorMateria(String nombreMateria) {
    return _index.porMateria[nombreMateria] ?? [];
  }

  /// Obtiene horarios por codigo de conjunto
  List<Horario> getHorariosPorCodigoConjunto(String codigo) {
    return _index.porCodigoConjunto[codigo] ?? [];
  }

  // ==================== LISTAS UNICAS ====================

  /// Obtiene lista de profesores unicos
  List<String> get profesores => _index.porProfesor.keys.toList()..sort();

  /// Obtiene lista de salones unicos
  List<String> get salones => _index.porSalon.keys.toList()..sort();

  /// Obtiene lista de bloques unicos
  List<String> get bloques => _index.porBloque.keys.toList()..sort();

  /// Obtiene lista de materias unicas
  List<String> get materias => _index.porMateria.keys.toList()..sort();

  /// Obtiene lista de NRCs unicos
  List<int> get nrcs => _index.porNrc.keys.toList()..sort();

  /// Obtiene lista de codigos de conjunto unicos
  List<String> get codigosConjunto =>
      _index.porCodigoConjunto.keys.toList()..sort();

  // ==================== BUSQUEDAS ====================

  /// Busca profesores por nombre parcial
  List<String> buscarProfesores(String query) {
    if (query.isEmpty) return profesores;
    final queryLower = query.toLowerCase();
    return profesores
        .where((p) => p.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Busca materias por nombre parcial
  List<String> buscarMaterias(String query) {
    if (query.isEmpty) return materias;
    final queryLower = query.toLowerCase();
    return materias.where((m) => m.toLowerCase().contains(queryLower)).toList();
  }

  /// Busca salones por nombre parcial
  List<String> buscarSalones(String query) {
    if (query.isEmpty) return salones;
    final queryLower = query.toLowerCase();
    return salones.where((s) => s.toLowerCase().contains(queryLower)).toList();
  }

  // ==================== DISPONIBILIDAD ====================

  /// Obtiene salones disponibles segun filtros
  List<SalonDisponibilidad> getSalonesDisponibles({
    required String horaInicio,
    required String horaFin,
    required String dia,
    String? bloque,
    bool incluirOcupados = false,
  }) {
    // Obtener todos los salones del bloque o todos
    final salonesAConsultar = bloque != null
        ? _index.salonesPorBloque[bloque] ?? <String>{}
        : _index.porSalon.keys.toSet();

    final resultado = <SalonDisponibilidad>[];

    for (final salon in salonesAConsultar) {
      final horariosDelSalon = _index.porSalon[salon] ?? [];

      // Buscar si hay algun horario que ocupe el salon en ese rango
      Horario? ocupadoPor;
      for (final horario in horariosDelSalon) {
        if (horario.dia == dia &&
            TimeUtils.isTimeOverlapping(
              horario.horaInicio,
              horario.horaFin,
              horaInicio,
              horaFin,
            )) {
          ocupadoPor = horario;
          break;
        }
      }

      final disponible = ocupadoPor == null;

      if (disponible || incluirOcupados) {
        resultado.add(
          SalonDisponibilidad(
            nombreSalon: salon,
            nombreBloque: _getBloqueForSalon(salon),
            disponible: disponible,
            ocupadoPor: ocupadoPor,
          ),
        );
      }
    }

    // Ordenar: disponibles primero, luego por bloque y salon
    resultado.sort((a, b) {
      if (a.disponible != b.disponible) {
        return a.disponible ? -1 : 1;
      }
      final bloqueComp = a.nombreBloque.compareTo(b.nombreBloque);
      if (bloqueComp != 0) return bloqueComp;
      return a.nombreSalon.compareTo(b.nombreSalon);
    });

    return resultado;
  }

  String _getBloqueForSalon(String salon) {
    final horarios = _index.porSalon[salon];
    if (horarios != null && horarios.isNotEmpty) {
      return horarios.first.nombreBloque;
    }
    return '';
  }

  /// Obtiene el nombre del bloque para un salon
  String getBloqueForSalon(String salon) => _getBloqueForSalon(salon);
}

/// Indice de horarios para busquedas rapidas
class HorarioIndex {
  final Map<String, List<Horario>> porProfesor;
  final Map<String, List<Horario>> porSalon;
  final Map<String, List<Horario>> porBloque;
  final Map<int, List<Horario>> porNrc;
  final Map<String, List<Horario>> porDia;
  final Map<String, List<Horario>> porMateria;
  final Map<String, List<Horario>> porCodigoConjunto;
  final Map<String, Set<String>> salonesPorBloque;

  HorarioIndex._({
    required this.porProfesor,
    required this.porSalon,
    required this.porBloque,
    required this.porNrc,
    required this.porDia,
    required this.porMateria,
    required this.porCodigoConjunto,
    required this.salonesPorBloque,
  });

  /// Construye el indice a partir de una lista de horarios
  factory HorarioIndex.build(List<Horario> horarios) {
    final porProfesor = <String, List<Horario>>{};
    final porSalon = <String, List<Horario>>{};
    final porBloque = <String, List<Horario>>{};
    final porNrc = <int, List<Horario>>{};
    final porDia = <String, List<Horario>>{};
    final porMateria = <String, List<Horario>>{};
    final porCodigoConjunto = <String, List<Horario>>{};
    final salonesPorBloque = <String, Set<String>>{};

    for (final horario in horarios) {
      // Por profesor
      (porProfesor[horario.profesor] ??= []).add(horario);

      // Por salon
      (porSalon[horario.nombreSalon] ??= []).add(horario);

      // Por bloque
      (porBloque[horario.nombreBloque] ??= []).add(horario);

      // Por NRC
      (porNrc[horario.nrc] ??= []).add(horario);

      // Por dia
      (porDia[horario.dia] ??= []).add(horario);

      // Por materia
      (porMateria[horario.nombreMateria] ??= []).add(horario);

      // Por codigo de conjunto
      (porCodigoConjunto[horario.codigoConjunto] ??= []).add(horario);

      // Salones por bloque
      (salonesPorBloque[horario.nombreBloque] ??= {}).add(horario.nombreSalon);
    }

    return HorarioIndex._(
      porProfesor: porProfesor,
      porSalon: porSalon,
      porBloque: porBloque,
      porNrc: porNrc,
      porDia: porDia,
      porMateria: porMateria,
      porCodigoConjunto: porCodigoConjunto,
      salonesPorBloque: salonesPorBloque,
    );
  }
}

/// Resultado de disponibilidad de un salon
class SalonDisponibilidad {
  final String nombreSalon;
  final String nombreBloque;
  final bool disponible;
  final Horario? ocupadoPor;

  const SalonDisponibilidad({
    required this.nombreSalon,
    required this.nombreBloque,
    required this.disponible,
    this.ocupadoPor,
  });
}

