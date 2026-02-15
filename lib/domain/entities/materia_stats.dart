import 'package:freezed_annotation/freezed_annotation.dart';

part 'materia_stats.freezed.dart';

/// Estadisticas de una materia
@freezed
abstract class MateriaStats with _$MateriaStats {
  const factory MateriaStats({
    required String nombre,
    required String codigoConjunto,
    required int idMateria,
    required int clases,
    required int nrcs,
    required int profesores,
    required int cuposTotales,
    required Set<int> nrcsSet,
    required Set<String> profesoresSet,
  }) = _MateriaStats;

  const MateriaStats._();

  /// Crea estadisticas vacias
  factory MateriaStats.empty(String nombre, String codigo, int id) =>
      MateriaStats(
        nombre: nombre,
        codigoConjunto: codigo,
        idMateria: id,
        clases: 0,
        nrcs: 0,
        profesores: 0,
        cuposTotales: 0,
        nrcsSet: const {},
        profesoresSet: const {},
      );
}
