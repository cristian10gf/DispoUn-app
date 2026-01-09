import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/horario.dart';
import 'materia_card.dart';

/// Límite máximo de elementos a mostrar en una celda antes de mostrar "+"
const int _maxElementsInCell = 6;

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
                _buildGrid(context, effectiveDayWidth, timeColumnWidth, cellHeight),
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
    BuildContext context,
    double dayWidth,
    double timeColumnWidth,
    double cellHeight,
  ) {
    final rows = <Widget>[];

    for (int hour = startHour; hour < endHour; hour++) {
      rows.add(_buildRow(context, hour, dayWidth, timeColumnWidth, cellHeight));
    }

    return Column(children: rows);
  }

  Widget _buildRow(
    BuildContext context,
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
          (dia) => _buildCell(context, dia, hour, dayWidth, cellHeight),
        ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, String dia, int hour, double dayWidth, double cellHeight) {
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
          : _buildHorarioCell(context, horariosEnCelda, dayWidth, dia, hour),
    );
  }

  Widget _buildHorarioCell(
    BuildContext context,
    List<Horario> horariosEnCelda,
    double dayWidth,
    String dia,
    int hour,
  ) {
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

    // Verificar si hay más de 6 elementos
    final hasOverflow = horariosEnCelda.length > _maxElementsInCell;
    final horariosToShow = hasOverflow
        ? horariosEnCelda.take(_maxElementsInCell - 1).toList()
        : horariosEnCelda;

    // Multiples horarios en la misma celda
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        ...horariosToShow.map((horario) {
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
        }),
        // Mostrar botón "+" si hay overflow
        if (hasOverflow)
          GestureDetector(
            onTap: () => _showHorariosModal(context, horariosEnCelda, dia, hour),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '+${horariosEnCelda.length - _maxElementsInCell + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showHorariosModal(
    BuildContext context,
    List<Horario> horariosEnCelda,
    String dia,
    int hour,
  ) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    final nextHourString = '${(hour + 1).toString().padLeft(2, '0')}:00';
    final diaCompleto = AppStrings.diasCompletos[dia] ?? dia;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _HorariosModal(
        horarios: horariosEnCelda,
        dia: diaCompleto,
        hora: '$timeString - $nextHourString',
        onHorarioTap: onHorarioTap,
      ),
    );
  }
}

/// Modal para mostrar todos los horarios cuando hay overflow
class _HorariosModal extends StatelessWidget {
  final List<Horario> horarios;
  final String dia;
  final String hora;
  final Function(Horario)? onHorarioTap;

  const _HorariosModal({
    required this.horarios,
    required this.dia,
    required this.hora,
    this.onHorarioTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle para arrastrar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dia,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hora,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${horarios.length} materias encontradas',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider),

            // Lista de horarios
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: horarios.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final horario = horarios[index];
                  final color = AppColors.getColorForString(horario.nombreMateria);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onHorarioTap?.call(horario);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: color,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Info principal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    horario.nombreMateria,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.meeting_room_outlined,
                                        size: 14,
                                        color: color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        horario.nombreSalon,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          horario.profesor,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'NRC: ${horario.nrc}',
                                          style: const TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${horario.horaInicio} - ${horario.horaFin}',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Flecha
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
