import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../domain/providers/stats_provider.dart';
import '../../../widgets/stats_card.dart';

/// Seccion de estadisticas generales
class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(generalStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.estadisticas,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Stats principales
          StatsGrid(
            crossAxisCount: 3,
            stats: [
              StatCard(
                label: AppStrings.clases,
                value: stats.totalClases.toString(),
                icon: Icons.class_outlined,
              ),
              StatCard(
                label: AppStrings.nrcs,
                value: stats.totalNrcs.toString(),
                icon: Icons.numbers,
              ),
              StatCard(
                label: AppStrings.profesores,
                value: stats.totalProfesores.toString(),
                icon: Icons.person_outline,
              ),
              StatCard(
                label: AppStrings.materias,
                value: stats.totalMaterias.toString(),
                icon: Icons.menu_book_outlined,
              ),
              StatCard(
                label: 'Salones',
                value: stats.totalSalones.toString(),
                icon: Icons.room_outlined,
              ),
              StatCard(
                label: 'Bloques',
                value: stats.totalBloques.toString(),
                icon: Icons.apartment_outlined,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Clases por bloque
          StatsBarChart(
            title: AppStrings.porBloque,
            data: stats.clasesPorBloque,
            barColor: AppColors.primaryRed,
          ),

          const SizedBox(height: 16),

          // Clases por dia
          StatsBarChart(
            title: AppStrings.porDia,
            data: _formatDiasData(stats.clasesPorDia),
            barColor: AppColors.accentCoral,
          ),
        ],
      ),
    );
  }

  Map<String, int> _formatDiasData(Map<String, int> data) {
    final formatted = <String, int>{};
    for (final dia in AppStrings.diasOrden) {
      final nombre = AppStrings.diasCompletos[dia] ?? dia;
      formatted[nombre] = data[dia] ?? 0;
    }
    return formatted;
  }
}

