import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/entities/materia_stats.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/horario_grid.dart';
import '../../widgets/materia_card.dart';
import '../../widgets/stats_card.dart';

/// Pagina de detalle de una materia
class MateriaDetailPage extends ConsumerWidget {
  final String materiaNombre;

  const MateriaDetailPage({super.key, required this.materiaNombre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final horarios = ref.watch(horariosMateriaProvider(materiaNombre));
    final stats = ref.watch(materiaStatsProvider(materiaNombre));

    return Scaffold(
      appBar: AppBar(
        title: Text(materiaNombre, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: horarios.isEmpty
          ? _buildNoData(colorScheme)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats de la materia
                  if (stats != null) _buildStats(stats, context, colorScheme),

                  const Divider(),

                  // Horario semanal
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.horarioMateria,
                      style: TextStyle(
                        color: colorScheme.onSurface,
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

                  // NRCs disponibles
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${AppStrings.nrcs} disponibles (${stats?.nrcs ?? 0})',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _buildNrcsList(horarios, context),

                  const SizedBox(height: 16),

                  // Profesores que imparten esta materia
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${AppStrings.profesores} (${stats?.profesores ?? 0})',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _buildProfesoresList(
                    stats?.profesoresSet ?? {},
                    context,
                    colorScheme,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStats(
    MateriaStats stats,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final color = AppColors.getColorForString(materiaNombre);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con color
          Row(
            children: [
              Container(
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stats.codigoConjunto,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      materiaNombre,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
              StatItem(label: AppStrings.nrcs, value: '${stats.nrcs}'),
              StatItem(
                label: AppStrings.profesores,
                value: '${stats.profesores}',
              ),
              StatItem(label: AppStrings.cupos, value: '${stats.cuposTotales}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNrcsList(List horarios, BuildContext context) {
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
            showProfesor: true,
            onTap: () => context.push('/nrc/${horario.nrc}'),
          ),
        );
      },
    );
  }

  Widget _buildProfesoresList(
    Set<String> profesores,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final lista = profesores.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final profesor = lista[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: colorScheme.primary, size: 20),
          ),
          title: Text(
            profesor.normalizeProfesorName(),
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
          onTap: () =>
              context.push('/profesor/${Uri.encodeComponent(profesor)}'),
        );
      },
    );
  }

  Widget _buildNoData(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            AppStrings.sinHorario,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
