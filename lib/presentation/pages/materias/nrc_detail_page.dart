import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/time_utils.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/horario_grid.dart';
import '../../widgets/stats_card.dart';

/// Pagina de detalle de un NRC
class NrcDetailPage extends ConsumerWidget {
  final int nrc;

  const NrcDetailPage({super.key, required this.nrc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final horarios = ref.watch(horariosNrcProvider(nrc));

    if (horarios.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('NRC $nrc'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildNoData(colorScheme),
      );
    }

    final primerHorario = horarios.first;
    final color = AppColors.getColorForString(primerHorario.nombreMateria);

    // Calcular horas totales
    double horasTotales = 0;
    for (final h in horarios) {
      horasTotales += TimeUtils.calculateDurationHours(h.horaInicio, h.horaFin);
    }

    // Verificar si todos los horarios son virtuales
    final esVirtual = horarios.every((h) => h.esVirtual);

    return Scaffold(
      appBar: AppBar(
        title: Text('NRC $nrc'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informacion principal
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Codigo de conjunto y badge virtual
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          primerHorario.codigoConjunto,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de Virtual/Presencial
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: esVirtual
                              ? Colors.purple.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              esVirtual ? Icons.cloud : Icons.location_on,
                              size: 12,
                              color: esVirtual ? Colors.purple : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              esVirtual
                                  ? AppStrings.virtual
                                  : AppStrings.presencial,
                              style: TextStyle(
                                color: esVirtual ? Colors.purple : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nombre de la materia
                  Text(
                    primerHorario.nombreMateria,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Departamento
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          primerHorario.departamento,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Profesor
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(
                            '/profesor/${Uri.encodeComponent(primerHorario.profesor)}',
                          ),
                          child: Text(
                            primerHorario.profesor.normalizeProfesorName(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats del NRC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsRow(
                items: [
                  StatItem(label: AppStrings.nrc, value: '$nrc'),
                  StatItem(
                    label: AppStrings.grupo,
                    value: '${primerHorario.grupo}',
                  ),
                  StatItem(
                    label: AppStrings.cupos,
                    value:
                        '${primerHorario.matriculados + primerHorario.cupos}',
                  ),
                  StatItem(
                    label: AppStrings.horasSemana,
                    value: horasTotales.toFormattedString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informacion adicional
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        AppStrings.modalidad,
                        primerHorario.modalidad,
                        colorScheme,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        AppStrings.nivel,
                        primerHorario.nivel,
                        colorScheme,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        AppStrings.matriculados,
                        '${primerHorario.matriculados}',
                        colorScheme,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Cupos restantes',
                        '${primerHorario.cupos}',
                        colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Horarios de este NRC
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${AppStrings.horario} (${horarios.length} sesiones)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Lista de sesiones
            _buildSesionesList(horarios, context, colorScheme),

            const SizedBox(height: 16),

            // Grid de horario
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.horarioSemanal,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(
              height: 400,
              child: HorarioGrid(
                horarios: horarios,
                onHorarioTap: (h) => context.push(
                  '/salon/${Uri.encodeComponent(h.nombreSalon)}',
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionesList(
    List horarios,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final h = horarios[index];
        final sesionVirtual = h.esVirtual;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sesionVirtual
                    ? Colors.purple.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: sesionVirtual
                    ? const Icon(Icons.cloud, color: Colors.purple, size: 24)
                    : Text(
                        h.dia.toString().toDiaCompleto().substring(0, 3),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            title: Text(
              '${TimeUtils.formatTime(h.horaInicio)} - ${TimeUtils.formatTime(h.horaFin)}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    sesionVirtual
                        ? '${h.dia.toString().toDiaCompleto()} - ${AppStrings.virtual}'
                        : '${h.nombreSalon} - ${h.nombreBloque}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (sesionVirtual)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      AppStrings.virtual,
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: sesionVirtual
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fechas de inicio y fin
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDateString(h.fechaInicio),
                            style: TextStyle(
                              color: colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                          if (h.fechaInicio != h.fechaFin)
                            Text(
                              _formatDateString(h.fechaFin),
                              style: TextStyle(
                                color: colorScheme.outline,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: colorScheme.outline),
                    ],
                  ),
            onTap: sesionVirtual
                ? null
                : () => context.push(
                    '/salon/${Uri.encodeComponent(h.nombreSalon)}',
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNoData(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            AppStrings.nrcNoEncontrado,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha desde String a formato corto (dd/MM)
  String _formatDateString(String dateString) {
    try {
      // Intentar parsear diferentes formatos de fecha
      DateTime? date;

      // Formato ISO (YYYY-MM-DD)
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length >= 3) {
          date = DateTime.tryParse(dateString);
          if (date == null) {
            // Intentar formato YYYY-MM-DD
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final day = int.tryParse(parts[2]);
            if (year != null && month != null && day != null) {
              date = DateTime(year, month, day);
            }
          }
        }
      } else if (dateString.contains('/')) {
        // Formato DD/MM/YYYY o MM/DD/YYYY
        final parts = dateString.split('/');
        if (parts.length >= 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            date = DateTime(year, month, day);
          }
        }
      }

      if (date != null) {
        // Formato corto: solo día y mes (dd/MM)
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Si falla el parseo, devolver la fecha original truncada
    }

    // Si no se puede parsear, devolver los primeros caracteres
    return dateString.length > 10 ? dateString.substring(0, 10) : dateString;
  }
}
