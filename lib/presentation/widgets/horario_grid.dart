import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/horario.dart';
import 'materia_card.dart';

/// Widget que muestra un horario semanal en formato grid
class HorarioGrid extends StatelessWidget {
  final List<Horario> horarios;
  final Function(Horario)? onHorarioTap;
  final int startHour;
  final int endHour;

  const HorarioGrid({
    super.key,
    required this.horarios,
    this.onHorarioTap,
    this.startHour = 6,
    this.endHour = 21,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    // Ajustar dimensiones segun orientacion y tamano de pantalla
    final cellHeight = isLandscape ? 40.0 : 50.0;
    final timeColumnWidth = isLandscape ? 70.0 : 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - timeColumnWidth;
        final calculatedDayWidth = availableWidth / 6;
        final minWidth = screenWidth < 400 ? 60.0 : 80.0;
        final maxWidth = isLandscape ? 180.0 : 150.0;
        final effectiveDayWidth = calculatedDayWidth.clamp(minWidth, maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header con dias
                _buildHeader(effectiveDayWidth, timeColumnWidth),
                // Grid de horarios
                _buildGrid(effectiveDayWidth, timeColumnWidth, cellHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double dayWidth, double timeColumnWidth) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Celda vacia para la columna de tiempo
          SizedBox(width: timeColumnWidth, height: 40),
          // Dias de la semana
          ...AppStrings.diasOrden.map(
            (dia) => Container(
              width: dayWidth,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                AppStrings.diasCompletos[dia] ?? dia,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    double dayWidth,
    double timeColumnWidth,
    double cellHeight,
  ) {
    final rows = <Widget>[];

    for (int hour = startHour; hour < endHour; hour++) {
      rows.add(_buildRow(hour, dayWidth, timeColumnWidth, cellHeight));
    }

    return Column(children: rows);
  }

  Widget _buildRow(
    int hour,
    double dayWidth,
    double timeColumnWidth,
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
            color: AppColors.surfaceDark,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: Center(
            child: Text(
              '$timeString - $nextHourString',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Celdas por cada dia
        ...AppStrings.diasOrden.map(
          (dia) => _buildCell(dia, hour, dayWidth, cellHeight),
        ),
      ],
    );
  }

  Widget _buildCell(String dia, int hour, double dayWidth, double cellHeight) {
    // Buscar horarios que ocurran en este dia y hora
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
          left: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: horariosEnCelda.isEmpty
          ? const SizedBox.shrink()
          : _buildHorarioCell(horariosEnCelda, dayWidth),
    );
  }

  Widget _buildHorarioCell(List<Horario> horariosEnCelda, double dayWidth) {
    if (horariosEnCelda.length == 1) {
      final horario = horariosEnCelda.first;
      final color = AppColors.getColorForString(horario.nombreMateria);

      return GestureDetector(
        onTap: onHorarioTap != null ? () => onHorarioTap!(horario) : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                horario.nombreSalon,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    // Multiples horarios en la misma celda
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: horariosEnCelda.map((horario) {
        final color = AppColors.getColorForString(horario.nombreMateria);
        return GestureDetector(
          onTap: onHorarioTap != null ? () => onHorarioTap!(horario) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              horario.nombreSalon,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget que muestra horario con cards de materias debajo
class HorarioConMaterias extends StatelessWidget {
  final List<Horario> horarios;
  final Function(Horario)? onHorarioTap;
  final String? title;

  const HorarioConMaterias({
    super.key,
    required this.horarios,
    this.onHorarioTap,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupar horarios por NRC para las cards
    final horariosUnicos = <int, Horario>{};
    for (final h in horarios) {
      horariosUnicos[h.nrc] ??= h;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Grid de horario
        SizedBox(
          height: 400,
          child: HorarioGrid(horarios: horarios, onHorarioTap: onHorarioTap),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // Cards de materias
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${AppStrings.materias} (${horariosUnicos.length})',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        MateriaCardList(
          horarios: horariosUnicos.values.toList(),
          onTap: onHorarioTap,
          horizontal: true,
        ),
      ],
    );
  }
}
