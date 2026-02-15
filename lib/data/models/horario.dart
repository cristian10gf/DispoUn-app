// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'horario.freezed.dart';
part 'horario.g.dart';

/// Modelo principal que representa un horario de clase
@freezed
abstract class Horario with _$Horario {
  const Horario._();

  const factory Horario({
    @JsonKey(name: 'codigo_conjunto') required String codigoConjunto,
    @JsonKey(name: 'id_materia') required int idMateria,
    @JsonKey(name: 'nombre_materia') required String nombreMateria,
    required String departamento,
    required String nivel,
    required int nrc,
    required int grupo,
    required int matriculados,
    required int cupos,
    required String modalidad,
    @JsonKey(name: 'nombre_bloque') required String nombreBloque,
    @JsonKey(name: 'nombre_salon') required String nombreSalon,
    String? piso,
    required String profesor,
    required String dia,
    @JsonKey(name: 'hora_inicio') required String horaInicio,
    @JsonKey(name: 'hora_fin') required String horaFin,
    @JsonKey(name: 'fecha_inicio') required String fechaInicio,
    @JsonKey(name: 'fecha_fin') required String fechaFin,
    required bool active,
  }) = _Horario;

  factory Horario.fromJson(Map<String, dynamic> json) =>
      _$HorarioFromJson(json);

  /// Indica si la materia es virtual (salon NNS o dia Domingo)
  bool get esVirtual =>
      nombreSalon.toUpperCase() == 'NNS' ||
      dia.toUpperCase() == 'D' ||
      nombreSalon.toUpperCase() == 'VIRT';
}
