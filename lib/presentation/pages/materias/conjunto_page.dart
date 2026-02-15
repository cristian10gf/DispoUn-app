import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/horario_grid.dart';
import '../../widgets/stats_card.dart';

/// Pagina para ver horarios de un codigo de conjunto (BIO, IST, etc.)
class ConjuntoPage extends ConsumerWidget {
  final String codigoConjunto;

  const ConjuntoPage({super.key, required this.codigoConjunto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final horarios = ref.watch(horariosCodigoConjuntoProvider(codigoConjunto));

    if (horarios.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(codigoConjunto),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildNoData(colorScheme),
      );
    }

    // Calcular estadisticas
    final nrcsUnicos = <int>{};
    final materiasUnicas = <String>{};
    final profesoresUnicos = <String>{};
    int cuposTotales = 0;
    final visitedNrcs = <int>{};

    for (final h in horarios) {
      nrcsUnicos.add(h.nrc);
      materiasUnicas.add(h.nombreMateria);
      profesoresUnicos.add(h.profesor);
      if (!visitedNrcs.contains(h.nrc)) {
        cuposTotales += h.matriculados + h.cupos;
        visitedNrcs.add(h.nrc);
      }
    }

    final color = AppColors.getColorForString(codigoConjunto);

    return Scaffold(
      appBar: AppBar(
        title: Text(codigoConjunto),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        codigoConjunto,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.codigoConjunto}: $codigoConjunto',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${horarios.length} clases registradas',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatsRow(
                items: [
                  StatItem(
                    label: AppStrings.materias,
                    value: '${materiasUnicas.length}',
                  ),
                  StatItem(
                    label: AppStrings.nrcs,
                    value: '${nrcsUnicos.length}',
                  ),
                  StatItem(
                    label: AppStrings.profesores,
                    value: '${profesoresUnicos.length}',
                  ),
                  StatItem(label: AppStrings.cupos, value: '$cuposTotales'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Horario semanal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.horarioSemanal,
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
                onHorarioTap: (h) => context.push('/nrc/${h.nrc}'),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Lista de materias
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${AppStrings.materias} (${materiasUnicas.length})',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            _buildMateriasList(materiasUnicas.toList(), context, colorScheme),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriasList(
    List<String> materias,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    materias.sort();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: materias.length,
      itemBuilder: (context, index) {
        final materia = materias[index];
        final color = AppColors.getColorForString(materia);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.menu_book, color: color, size: 20),
          ),
          title: Text(
            materia,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
          onTap: () => context.push('/materia/${Uri.encodeComponent(materia)}'),
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
            AppStrings.noResults,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
