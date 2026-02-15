import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/providers/data_provider.dart';
import '../../../domain/providers/filter_provider.dart';
import '../../../domain/providers/stats_provider.dart';
import '../../widgets/search_input.dart';

/// Pagina de profesores
class ProfesoresPage extends ConsumerWidget {
  const ProfesoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profesores),
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
    final searchQuery = ref.watch(profesorSearchQueryProvider);
    final profesoresFiltrados = ref.watch(profesoresFilteredProvider);
    final topProfesores = ref.watch(topProfesoresProvider);
    final profesores = ref.watch(profesoresListProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: DebouncedSearchInput(
              hintText: AppStrings.buscarProfesor,
              onChanged: (value) {
                ref.read(profesorSearchQueryProvider.notifier).set(value);
              },
            ),
          ),

          // Resultados de busqueda o top profesores
          if (searchQuery.isNotEmpty) ...[
            _buildSearchResults(context, profesoresFiltrados, colorScheme),
          ] else ...[
            // Top profesores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.topProfesores,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTopProfesores(context, topProfesores, colorScheme),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Selector de profesor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.seleccionarProfesor,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildProfesorSelector(context, ref, profesores),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<String> profesores,
    ColorScheme colorScheme,
  ) {
    if (profesores.isEmpty) {
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
      itemCount: profesores.length,
      itemBuilder: (context, index) {
        final profesor = profesores[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
          title: Text(
            profesor.normalizeProfesorName(),
            style: TextStyle(color: colorScheme.onSurface),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
          onTap: () =>
              context.push('/profesor/${Uri.encodeComponent(profesor)}'),
        );
      },
    );
  }

  Widget _buildTopProfesores(
    BuildContext context,
    List topProfesores,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: topProfesores.length.clamp(0, 10),
      itemBuilder: (context, index) {
        final stats = topProfesores[index];
        return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.push(
                  '/profesor/${Uri.encodeComponent(stats.nombre)}',
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Posicion
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getPositionColor(index, colorScheme),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.nombre.toString().normalizeProfesorName(),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats.clases} clases | ${stats.nrcs} NRCs | ${stats.materias} materias',
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

  Widget _buildProfesorSelector(
    BuildContext context,
    WidgetRef ref,
    List<String> profesores,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          hintText: AppStrings.seleccionarProfesor,
          prefixIcon: Icon(Icons.person_search),
        ),
        isExpanded: true,
        items: profesores.map((profesor) {
          return DropdownMenuItem(
            value: profesor,
            child: Text(
              profesor.normalizeProfesorName(),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.push('/profesor/${Uri.encodeComponent(value)}');
          }
        },
      ),
    );
  }

  Color _getPositionColor(int index, ColorScheme colorScheme) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Oro
      case 1:
        return const Color(0xFFC0C0C0); // Plata
      case 2:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return colorScheme.surfaceContainerHighest;
    }
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
