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
        body: _buildNoData(),
      );
    }

    final primerHorario = horarios.first;
    final color = AppColors.getColorForString(primerHorario.nombreMateria);

    // Calcular horas totales
    double horasTotales = 0;
    for (final h in horarios) {
      horasTotales += TimeUtils.calculateDurationHours(h.horaInicio, h.horaFin);
    }

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
                  // Codigo de conjunto
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
                  const SizedBox(height: 12),

                  // Nombre de la materia
                  Text(
                    primerHorario.nombreMateria,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Departamento
                  Row(
                    children: [
                      const Icon(
                        Icons.business,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          primerHorario.departamento,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(
                            '/profesor/${Uri.encodeComponent(primerHorario.profesor)}',
                          ),
                          child: Text(
                            primerHorario.profesor.normalizeProfesorName(),
                            style: const TextStyle(
                              color: AppColors.primaryRed,
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
                      ),
                      const Divider(),
                      _buildInfoRow(AppStrings.nivel, primerHorario.nivel),
                      const Divider(),
                      _buildInfoRow(
                        AppStrings.matriculados,
                        '${primerHorario.matriculados}',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Cupos restantes',
                        '${primerHorario.cupos}',
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Lista de sesiones
            _buildSesionesList(horarios, context),

            const SizedBox(height: 16),

            // Grid de horario
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.horarioSemanal,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionesList(List horarios, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: horarios.length,
      itemBuilder: (context, index) {
        final h = horarios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  h.dia.toString().toDiaCompleto().substring(0, 3),
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              '${TimeUtils.formatTime(h.horaInicio)} - ${TimeUtils.formatTime(h.horaFin)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${h.nombreSalon} - ${h.nombreBloque}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
            onTap: () =>
                context.push('/salon/${Uri.encodeComponent(h.nombreSalon)}'),
          ),
        );
      },
    );
  }

  Widget _buildNoData() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            AppStrings.nrcNoEncontrado,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

