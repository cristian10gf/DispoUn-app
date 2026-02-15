import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../domain/providers/data_provider.dart';
import '../../../domain/providers/filter_provider.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/search_input.dart';
import '../../widgets/stats_card.dart';

/// Pagina de materias
class MateriasPage extends ConsumerWidget {
  const MateriasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.materias),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: dataState.repository == null
          ? _buildNoData(context, Theme.of(context).colorScheme)
          : _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchQuery = ref.watch(materiaSearchQueryProvider);
    final materiasFiltradas = ref.watch(materiasFilteredProvider);
    final topMaterias = ref.watch(topMateriasProvider);
    final materias = ref.watch(materiasListProvider);
    final codigosConjunto = ref.watch(codigosConjuntoProvider);
    final stats = ref.watch(generalStatsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: DebouncedSearchInput(
              hintText: AppStrings.buscarMateria,
              onChanged: (value) {
                ref.read(materiaSearchQueryProvider.notifier).set(value);
              },
            ),
          ),

          // Resultados de busqueda o contenido normal
          if (searchQuery.isNotEmpty) ...[
            _buildSearchResults(context, materiasFiltradas, colorScheme),
          ] else ...[
            // Estadisticas generales de materias
            Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StatsRow(
                    items: [
                      StatItem(
                        label: AppStrings.materias,
                        value: '${stats.totalMaterias}',
                      ),
                      StatItem(
                        label: AppStrings.nrcs,
                        value: '${stats.totalNrcs}',
                      ),
                      StatItem(
                        label: AppStrings.profesores,
                        value: '${stats.totalProfesores}',
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.03, end: 0, duration: 300.ms),

            const SizedBox(height: 24),

            // Top materias
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.topMaterias,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTopMaterias(context, topMaterias, colorScheme),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Selector de materia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.seleccionarMateria,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMateriaSelector(context, materias),

            const SizedBox(height: 24),

            // Ver por codigo de conjunto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.verPorConjunto,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCodigosConjuntoGrid(context, codigosConjunto),

            const SizedBox(height: 24),

            // Consultar NRC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildNrcConsultaCard(context, colorScheme),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<String> materias,
    ColorScheme colorScheme,
  ) {
    if (materias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                AppStrings.noResults,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

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
            child: Icon(Icons.menu_book, color: color),
          ),
          title: Text(materia, style: TextStyle(color: colorScheme.onSurface)),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
          onTap: () => context.push('/materia/${Uri.encodeComponent(materia)}'),
        );
      },
    );
  }

  Widget _buildTopMaterias(
    BuildContext context,
    List topMaterias,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: topMaterias.length.clamp(0, 10),
      itemBuilder: (context, index) {
        final stats = topMaterias[index];
        final color = AppColors.getColorForString(stats.nombre);
        return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.push(
                  '/materia/${Uri.encodeComponent(stats.nombre)}',
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Color indicator
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    stats.codigoConjunto,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats.nombre,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats.nrcs} NRCs | ${stats.profesores} profesores | ${stats.cuposTotales} cupos',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.outline),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (50 * index.clamp(0, 10)).ms, duration: 300.ms)
            .slideX(begin: 0.05, end: 0, delay: (50 * index.clamp(0, 10)).ms);
      },
    );
  }

  Widget _buildMateriaSelector(BuildContext context, List<String> materias) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          hintText: AppStrings.seleccionarMateria,
          prefixIcon: Icon(Icons.menu_book_outlined),
        ),
        isExpanded: true,
        items: materias.map((materia) {
          return DropdownMenuItem(
            value: materia,
            child: Text(materia, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.push('/materia/${Uri.encodeComponent(value)}');
          }
        },
      ),
    );
  }

  Widget _buildCodigosConjuntoGrid(BuildContext context, List<String> codigos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: codigos.map((codigo) {
          final color = AppColors.getColorForString(codigo);
          return ActionChip(
            label: Text(codigo),
            backgroundColor: color.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
            onPressed: () =>
                context.push('/conjunto/${Uri.encodeComponent(codigo)}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNrcConsultaCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: InkWell(
        onTap: () => _showNrcDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.numbers, color: colorScheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.consultarNrc,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Busca informacion de una clase por su numero de NRC',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  void _showNrcDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.consultarNrc),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: AppStrings.ingresarNrc,
            prefixIcon: Icon(Icons.numbers),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final nrc = int.tryParse(controller.text);
              if (nrc != null) {
                Navigator.pop(context);
                context.push('/nrc/$nrc');
              }
            },
            child: const Text(AppStrings.search),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noData,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.upload_file),
            label: const Text(AppStrings.cargarArchivo),
          ),
        ],
      ),
    );
  }
}
