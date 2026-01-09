import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mi_horario_config.dart';

/// Servicio para persistir la configuracion de Mi Horario usando SharedPreferences
class MiHorarioStorageService {
  MiHorarioStorageService._();

  static const String _configKey = 'mi_horario_config';

  /// Guarda la configuracion de Mi Horario
  static Future<bool> saveConfig(MiHorarioConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());
      return await prefs.setString(_configKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Carga la configuracion de Mi Horario
  static Future<MiHorarioConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_configKey);

      if (jsonString == null) {
        return const MiHorarioConfig();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MiHorarioConfig.fromJson(json);
    } catch (e) {
      return const MiHorarioConfig();
    }
  }

  /// Agrega un NRC a la lista
  static Future<MiHorarioConfig> addNrc(int nrc) async {
    final config = await loadConfig();
    if (config.nrcs.contains(nrc)) {
      return config;
    }
    final newConfig = config.copyWith(nrcs: [...config.nrcs, nrc]);
    await saveConfig(newConfig);
    return newConfig;
  }

  /// Remueve un NRC de la lista
  static Future<MiHorarioConfig> removeNrc(int nrc) async {
    final config = await loadConfig();
    final newNrcs = config.nrcs.where((n) => n != nrc).toList();
    final newConfig = config.copyWith(nrcs: newNrcs);
    await saveConfig(newConfig);
    return newConfig;
  }

  /// Limpia todos los NRCs
  static Future<MiHorarioConfig> clearNrcs() async {
    final config = await loadConfig();
    final newConfig = config.copyWith(nrcs: []);
    await saveConfig(newConfig);
    return newConfig;
  }

  /// Establece si Mi Horario es la pantalla principal
  static Future<MiHorarioConfig> setPantallaPrincipal(bool value) async {
    final config = await loadConfig();
    final newConfig = config.copyWith(esPantallaPrincipal: value);
    await saveConfig(newConfig);
    return newConfig;
  }
}
