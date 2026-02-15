import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/horario_grid.dart';
import '../../widgets/stats_card.dart';

/// Pagina de detalle de un salon
class SalonDetailPage extends ConsumerWidget {
  final String salonNombre;

  const SalonDetailPage({super.key, required this.salonNombre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horarios = ref.watch(horariosSalonProvider(salonNombre));
    final stats = ref.watch(salonStatsProvider(salonNombre));

    return Scaffold(
      appBar: AppBar(
        title: Text(salonNombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: horarios.isEmpty
          ? _buildNoData(context)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats del salon
                  if (stats != null) _buildStats(context, stats),

                  const Divider(),

                  // Horario semanal
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.horarioSemanal,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
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

                  // Lista de materias que usan este salon
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${AppStrings.materias} en este salon',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _buildMateriasList(context, horarios),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, dynamic> stats) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                stats['bloque'] ?? '',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatsRow(
            items: [
              StatItem(label: AppStrings.clases, value: '${stats['clases']}'),
              StatItem(label: AppStrings.nrcs, value: '${stats['nrcs']}'),
              StatItem(
                label: AppStrings.materias,
                value: '${stats['materias']}',
              ),
              StatItem(
                label: AppStrings.horasSemana,
                value: (stats['horasSemana'] as double).toFormattedString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMateriasList(BuildContext context, List horarios) {
    // Agrupar por materia
    final materias = <String, int>{};
    for (final h in horarios) {
      materias[h.nombreMateria] = (materias[h.nombreMateria] ?? 0) + 1;
    }

    final sorted = materias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.getColorForString(entry.key),
            radius: 16,
            child: Text(
              '${entry.value}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            entry.key,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.outline,
          ),
          onTap: () =>
              context.push('/materia/${Uri.encodeComponent(entry.key)}'),
        );
      },
    );
  }

  Widget _buildNoData(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: colorScheme.outline),
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
