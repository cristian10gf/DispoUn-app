import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../models/horario.dart';

/// Servicio para parsear JSON de horarios usando Isolates para mejor rendimiento
class JsonParserService {
  JsonParserService._();

  /// Parsea una lista de horarios desde un JSON string usando un Isolate
  static Future<List<Horario>> parseHorarios(String jsonString) async {
    return compute(_parseHorariosIsolate, jsonString);
  }

  /// Parsea horarios desde una lista de mapas usando un Isolate
  static Future<List<Horario>> parseHorariosFromList(
    List<dynamic> jsonList,
  ) async {
    return compute(_parseHorariosFromListIsolate, jsonList);
  }

  /// Funcion que se ejecuta en el Isolate para parsear JSON string
  static List<Horario> _parseHorariosIsolate(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final fixedList = _fixEncodingInList(jsonList);
    return _parseList(fixedList);
  }

  /// Funcion que se ejecuta en el Isolate para parsear lista
  static List<Horario> _parseHorariosFromListIsolate(List<dynamic> jsonList) {
    final fixedList = _fixEncodingInList(jsonList);
    return _parseList(fixedList);
  }

  /// Corrige el encoding reemplazando "?" por "ñ" en todos los strings
  static dynamic _fixEncoding(dynamic value) {
    if (value is String) {
      return value.replaceAll('?', 'ñ');
    } else if (value is Map<String, dynamic>) {
      return _fixEncodingInMap(value);
    } else if (value is List) {
      return _fixEncodingInList(value);
    }
    return value;
  }

  /// Corrige el encoding en un Map
  static Map<String, dynamic> _fixEncodingInMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, _fixEncoding(value)));
  }

  /// Corrige el encoding en una List
  static List<dynamic> _fixEncodingInList(List<dynamic> list) {
    return list.map(_fixEncoding).toList();
  }

  /// Parsea una lista de JSON a objetos Horario
  static List<Horario> _parseList(List<dynamic> jsonList) {
    final horarios = <Horario>[];
    for (final item in jsonList) {
      try {
        if (item is Map<String, dynamic>) {
          horarios.add(Horario.fromJson(item));
        }
      } catch (e) {
        // Ignorar elementos mal formados
        debugPrint('Error parseando horario: $e');
      }
    }
    // Unificar horarios duplicados que solo difieren en fecha
    return _unificarHorariosDuplicados(horarios);
  }

  /// Genera una clave unica para un horario excluyendo las fechas
  static String _generarClaveHorario(Horario h) {
    return '${h.codigoConjunto}|${h.idMateria}|${h.nombreMateria}|'
        '${h.departamento}|${h.nivel}|${h.nrc}|${h.grupo}|'
        '${h.matriculados}|${h.cupos}|${h.modalidad}|'
        '${h.nombreBloque}|${h.nombreSalon}|${h.piso ?? ""}|'
        '${h.profesor}|${h.dia}|${h.horaInicio}|${h.horaFin}|${h.active}';
  }

  /// Unifica horarios duplicados que tienen todos los datos iguales
  /// y solo difieren en la fecha (donde fecha_inicio == fecha_fin)
  static List<Horario> _unificarHorariosDuplicados(List<Horario> horarios) {
    // Agrupar horarios por clave (todos los campos menos fechas)
    final grupos = <String, List<Horario>>{};

    for (final horario in horarios) {
      // Solo considerar para unificacion si es horario de un solo dia
      final esDiaUnico = horario.fechaInicio == horario.fechaFin;

      if (esDiaUnico) {
        final clave = _generarClaveHorario(horario);
        (grupos[clave] ??= []).add(horario);
      } else {
        // Si no es de un solo dia, agregarlo directamente sin unificar
        // Usamos una clave unica para que no se agrupe
        final claveUnica =
            '${_generarClaveHorario(horario)}|${horario.fechaInicio}|${horario.fechaFin}';
        grupos[claveUnica] = [horario];
      }
    }

    // Crear lista unificada
    final resultado = <Horario>[];

    for (final grupo in grupos.values) {
      if (grupo.length == 1) {
        // Solo hay uno, agregarlo tal cual
        resultado.add(grupo.first);
      } else {
        // Hay multiples, unificarlos
        resultado.add(_unificarGrupo(grupo));
      }
    }

    return resultado;
  }

  /// Unifica un grupo de horarios tomando la fecha mas temprana y mas tardia
  static Horario _unificarGrupo(List<Horario> grupo) {
    // Ordenar por fecha para encontrar la mas temprana y la mas tardia
    final fechas = grupo.map((h) => h.fechaInicio).toList()..sort();
    final fechaInicio = fechas.first;
    final fechaFin = fechas.last;

    // Tomar el primer horario como base y actualizar las fechas
    final base = grupo.first;

    return Horario(
      codigoConjunto: base.codigoConjunto,
      idMateria: base.idMateria,
      nombreMateria: base.nombreMateria,
      departamento: base.departamento,
      nivel: base.nivel,
      nrc: base.nrc,
      grupo: base.grupo,
      matriculados: base.matriculados,
      cupos: base.cupos,
      modalidad: base.modalidad,
      nombreBloque: base.nombreBloque,
      nombreSalon: base.nombreSalon,
      piso: base.piso,
      profesor: base.profesor,
      dia: base.dia,
      horaInicio: base.horaInicio,
      horaFin: base.horaFin,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      active: base.active,
    );
  }

  /// Valida si un JSON tiene el formato correcto de horarios
  static Future<bool> validateJsonFormat(String jsonString) async {
    return compute(_validateJsonFormatIsolate, jsonString);
  }

  static bool _validateJsonFormatIsolate(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! List || decoded.isEmpty) {
        return false;
      }

      // Verificar que el primer elemento tenga los campos requeridos
      final firstItem = decoded.first;
      if (firstItem is! Map<String, dynamic>) {
        return false;
      }

      final requiredFields = [
        'codigo_conjunto',
        'id_materia',
        'nombre_materia',
        'nrc',
        'profesor',
        'dia',
        'hora_inicio',
        'hora_fin',
        'nombre_salon',
        'nombre_bloque',
      ];

      for (final field in requiredFields) {
        if (!firstItem.containsKey(field)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convierte horarios a JSON string para guardar
  static Future<String> horariosToJson(List<Horario> horarios) async {
    return compute(_horariosToJsonIsolate, horarios);
  }

  static String _horariosToJsonIsolate(List<Horario> horarios) {
    final list = horarios.map((h) => h.toJson()).toList();
    return json.encode(list);
  }
}
