import 'package:freezed_annotation/freezed_annotation.dart';

part 'profesor_stats.freezed.dart';

/// Estadisticas de un profesor
@freezed
abstract class ProfesorStats with _$ProfesorStats {
  const factory ProfesorStats({
    required String nombre,
    required int clases,
    required int materias,
    required double horasSemana,
    required int nrcs,
    required Set<String> materiasSet,
    required Set<int> nrcsSet,
  }) = _ProfesorStats;

  const ProfesorStats._();

  /// Crea estadisticas vacias
  factory ProfesorStats.empty(String nombre) => ProfesorStats(
    nombre: nombre,
    clases: 0,
    materias: 0,
    horasSemana: 0,
    nrcs: 0,
    materiasSet: const {},
    nrcsSet: const {},
  );
}
