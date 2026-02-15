import 'package:freezed_annotation/freezed_annotation.dart';

part 'mi_horario_config.freezed.dart';
part 'mi_horario_config.g.dart';

/// Configuracion del horario personal del usuario
@freezed
abstract class MiHorarioConfig with _$MiHorarioConfig {
  const MiHorarioConfig._();

  const factory MiHorarioConfig({
    /// Lista de NRCs en los que el usuario esta inscrito
    @Default([]) List<int> nrcs,

    /// Si el usuario quiere que Mi Horario sea la pantalla principal
    @Default(false) bool esPantallaPrincipal,
  }) = _MiHorarioConfig;

  factory MiHorarioConfig.fromJson(Map<String, dynamic> json) =>
      _$MiHorarioConfigFromJson(json);

  /// Indica si el usuario tiene NRCs configurados
  bool get tieneNrcs => nrcs.isNotEmpty;

  /// Cantidad de NRCs configurados
  int get cantidadNrcs => nrcs.length;
}
