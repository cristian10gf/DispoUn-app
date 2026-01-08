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
    return _parseList(jsonList);
  }

  /// Funcion que se ejecuta en el Isolate para parsear lista
  static List<Horario> _parseHorariosFromListIsolate(List<dynamic> jsonList) {
    return _parseList(jsonList);
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
    return horarios;
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
