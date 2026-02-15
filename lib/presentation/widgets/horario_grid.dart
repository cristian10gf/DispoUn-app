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
        final calculatedDayWidth = availableWidth / 7; // 7 dias: L-D
        final minWidth = screenWidth < 400 ? 60.0 : 80.0;
        final maxWidth = isLandscape ? 180.0 : 150.0;
        final effectiveDayWidth = calculatedDayWidth.clamp(minWidth, maxWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header con dias
                _buildHeader(context, effectiveDayWidth, timeColumnWidth),
                // Grid de horarios
                _buildGrid(
                  context,
                  effectiveDayWidth,
                  timeColumnWidth,
                  cellHeight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double dayWidth,
    double timeColumnWidth,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
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
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Text(
                AppStrings.diasCompletos[dia] ?? dia,
                style: TextStyle(
                  color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
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
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Center(
            child: Text(
              '$timeString - $nextHourString',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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

  Widget _buildCell(
    BuildContext context,
    String dia,
    int hour,
    double dayWidth,
    double cellHeight,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

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
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
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
          Builder(
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              return GestureDetector(
                onTap: () =>
                    _showHorariosModal(context, horariosEnCelda, dia, hour),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.9),
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
              );
            },
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                color: colorScheme.outline,
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
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dia,
                          style: TextStyle(
                            color: colorScheme.primary,
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
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hora,
                          style: TextStyle(
                            color: colorScheme.onSurface,
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
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: theme.dividerColor),

            // Lista de horarios
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: horarios.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final horario = horarios[index];
                  final color = AppColors.getColorForString(
                    horario.nombreMateria,
                  );

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
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: color, width: 4),
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
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
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
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: colorScheme.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          horario.profesor,
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
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
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'NRC: ${horario.nrc}',
                                          style: TextStyle(
                                            color: colorScheme.outline,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${horario.horaInicio} - ${horario.horaFin}',
                                        style: TextStyle(
                                          color: colorScheme.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Flecha
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.outline,
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
