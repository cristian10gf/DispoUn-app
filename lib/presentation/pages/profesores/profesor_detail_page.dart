import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/entities/profesor_stats.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/horario_grid.dart';
import '../../widgets/materia_card.dart';
import '../../widgets/stats_card.dart';

/// Pagina de detalle de un profesor
class ProfesorDetailPage extends ConsumerWidget {
  final String profesorNombre;

  const ProfesorDetailPage({super.key, required this.profesorNombre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horarios = ref.watch(horariosProfesorProvider(profesorNombre));
    final stats = ref.watch(profesorStatsProvider(profesorNombre));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profesorNombre.normalizeProfesorName(),
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: horarios.isEmpty
          ? _buildNoData()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats del profesor
                  if (stats != null) _buildStats(stats),

                  const Divider(),

                  // Horario semanal
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.horarioProfesor,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 500,
                    child: HorarioGrid(
                      horarios: horarios,
                      onHorarioTap: (horario) {
                        context.push('/nrc/${horario.nrc}');
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Cards de materias
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${AppStrings.materias} (${stats?.materias ?? 0})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _buildMateriasList(horarios, context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStats(ProfesorStats stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono y nombre
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profesorNombre.normalizeProfesorName(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.profesor,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats en fila
          StatsRow(
            items: [
              StatItem(label: AppStrings.clases, value: '${stats.clases}'),
              StatItem(label: AppStrings.materias, value: '${stats.materias}'),
              StatItem(
                label: AppStrings.horasSemana,
                value: stats.horasSemana.toFormattedString(),
              ),
              StatItem(label: AppStrings.nrcs, value: '${stats.nrcs}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMateriasList(List horarios, BuildContext context) {
    // Obtener horarios unicos por NRC
    final horariosUnicos = <int, dynamic>{};
    for (final h in horarios) {
      horariosUnicos[h.nrc] ??= h;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: horariosUnicos.length,
      itemBuilder: (context, index) {
        final horario = horariosUnicos.values.elementAt(index);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MateriaCard(
            horario: horario,
            showProfesor: false,
            onTap: () => context.push('/nrc/${horario.nrc}'),
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
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            AppStrings.sinHorario,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
