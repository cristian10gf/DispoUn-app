import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/horario.dart';
import '../../domain/providers/mi_horario_provider.dart';

/// Widget de grid de horario exportable como imagen
/// Diseñado para replicar el formato de la imagen de referencia
class MiHorarioExportableGrid extends StatelessWidget {
  final List<Horario> horarios;
  final List<NrcInfo> nrcInfos;
  final ScreenshotController screenshotController;
  final Function(Horario)? onHorarioTap;
  final int startHour;
  final int endHour;

  const MiHorarioExportableGrid({
    super.key,
    required this.horarios,
    required this.nrcInfos,
    required this.screenshotController,
    this.onHorarioTap,
    this.startHour = 6,
    this.endHour = 20,
  });

  /// Captura el widget como imagen
  Future<Uint8List?> captureAsImage() async {
    return await screenshotController.capture(
      pixelRatio: 2.0,
      delay: const Duration(milliseconds: 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: _ExportableContent(
        horarios: horarios,
        nrcInfos: nrcInfos,
        onHorarioTap: onHorarioTap,
        startHour: startHour,
        endHour: endHour,
      ),
    );
  }
}

/// Contenido exportable del horario
class _ExportableContent extends StatelessWidget {
  final List<Horario> horarios;
  final List<NrcInfo> nrcInfos;
  final Function(Horario)? onHorarioTap;
  final int startHour;
  final int endHour;

  // Dias a mostrar (sin domingo)
  static const List<String> _diasMostrar = ['L', 'M', 'X', 'J', 'V', 'S'];

  const _ExportableContent({
    required this.horarios,
    required this.nrcInfos,
    this.onHorarioTap,
    this.startHour = 6,
    this.endHour = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grid de horario
          _buildScheduleGrid(),
          const SizedBox(height: 16),
          // Leyenda de materias
          _buildMateriaLegend(),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid() {
    const cellHeight = 28.0;
    const timeColumnWidth = 80.0;
    const dayColumnWidth = 110.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con dias
          _buildHeader(timeColumnWidth, dayColumnWidth),
          // Filas de horario
          for (int hour = startHour; hour < endHour; hour++)
            _buildRow(hour, timeColumnWidth, dayColumnWidth, cellHeight),
        ],
      ),
    );
  }

  Widget _buildHeader(double timeColumnWidth, double dayColumnWidth) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          // Celda vacia para la columna de tiempo
          SizedBox(width: timeColumnWidth, height: 24),
          // Dias
          for (final dia in _diasMostrar)
            Container(
              width: dayColumnWidth,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Text(
                AppStrings.diasCompletos[dia]?.toUpperCase() ?? dia,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    int hour,
    double timeColumnWidth,
    double dayColumnWidth,
    double cellHeight,
  ) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    final nextHourString = '${(hour + 1).toString().padLeft(2, '0')}:00';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna de tiempo
        Container(
          width: timeColumnWidth,
          height: cellHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
              right: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              '$timeString - $nextHourString',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Celdas por cada dia
        for (final dia in _diasMostrar)
          _buildCell(dia, hour, dayColumnWidth, cellHeight),
      ],
    );
  }

  Widget _buildCell(String dia, int hour, double dayWidth, double cellHeight) {
    // Buscar horarios en este dia y hora
    final horariosEnCelda = horarios.where((h) {
      if (h.dia != dia) return false;

      final horaInicio = TimeUtils.parseTimeToMinutes(h.horaInicio);
      final horaFin = TimeUtils.parseTimeToMinutes(h.horaFin);
      final cellStart = hour * 60;
      final cellEnd = (hour + 1) * 60;

      return horaInicio < cellEnd && horaFin > cellStart;
    }).toList();

    return Container(
      width: dayWidth,
      height: cellHeight,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey, width: 0.5),
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: horariosEnCelda.isEmpty
          ? const SizedBox.shrink()
          : _buildHorarioCell(horariosEnCelda),
    );
  }

  Widget _buildHorarioCell(List<Horario> horariosEnCelda) {
    if (horariosEnCelda.length == 1) {
      final horario = horariosEnCelda.first;
      final color = AppColors.getColorForString(horario.nombreMateria);

      return GestureDetector(
        onTap: onHorarioTap != null ? () => onHorarioTap!(horario) : null,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              horario.nombreSalon,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // Multiples horarios
    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: horariosEnCelda.map((horario) {
        final color = AppColors.getColorForString(horario.nombreMateria);
        return GestureDetector(
          onTap: onHorarioTap != null ? () => onHorarioTap!(horario) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              horario.nombreSalon,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMateriaLegend() {
    if (nrcInfos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: nrcInfos.map((info) => _MateriaCard(info: info)).toList(),
      ),
    );
  }
}

/// Card de materia para la leyenda
class _MateriaCard extends StatelessWidget {
  final NrcInfo info;

  const _MateriaCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getColorForString(info.nombreMateria);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre de la materia
          Text(
            info.nombreMateria,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // NRC
          Text(
            'NRC ${info.nrc}',
            style: TextStyle(
              color: color.withValues(alpha: 1),
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          // Codigo
          Text(
            info.codigoConjunto,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 2),
          // Profesor
          Text(
            info.profesor,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Cupos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getCuposColor(info.cuposDisponibles),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${info.cuposDisponibles} Cupos',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCuposColor(int cupos) {
    if (cupos <= 0) return Colors.red.withValues(alpha: 0.3);
    if (cupos <= 5) return Colors.orange.withValues(alpha: 0.3);
    if (cupos <= 15) return Colors.yellow.withValues(alpha: 0.3);
    return Colors.green.withValues(alpha: 0.3);
  }
}

/// Widget completo de Mi Horario con grid y leyenda (version interactiva)
class MiHorarioInteractiveView extends StatelessWidget {
  final List<Horario> horarios;
  final List<NrcInfo> nrcInfos;
  final ScreenshotController screenshotController;
  final Function(Horario)? onHorarioTap;

  const MiHorarioInteractiveView({
    super.key,
    required this.horarios,
    required this.nrcInfos,
    required this.screenshotController,
    this.onHorarioTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid exportable (envuelto en Screenshot)
          MiHorarioExportableGrid(
            horarios: horarios,
            nrcInfos: nrcInfos,
            screenshotController: screenshotController,
            onHorarioTap: onHorarioTap,
          ),
        ],
      ),
    );
  }
}
