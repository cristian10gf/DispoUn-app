import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
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
          ? _buildNoData(context)
          : _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
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
                ref.read(profesorSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Resultados de busqueda o top profesores
          if (searchQuery.isNotEmpty) ...[
            _buildSearchResults(context, profesoresFiltrados),
          ] else ...[
            // Top profesores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.topProfesores,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTopProfesores(context, topProfesores),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Selector de profesor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.seleccionarProfesor,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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

  Widget _buildSearchResults(BuildContext context, List<String> profesores) {
    if (profesores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
              SizedBox(height: 16),
              Text(
                AppStrings.noResults,
                style: TextStyle(color: AppColors.textSecondary),
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
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: AppColors.primaryRed),
          ),
          title: Text(
            profesor.normalizeProfesorName(),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
          onTap: () =>
              context.push('/profesor/${Uri.encodeComponent(profesor)}'),
        );
      },
    );
  }

  Widget _buildTopProfesores(BuildContext context, List topProfesores) {
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
            onTap: () =>
                context.push('/profesor/${Uri.encodeComponent(stats.nombre)}'),
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
                      color: _getPositionColor(index),
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
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.clases} clases | ${stats.nrcs} NRCs | ${stats.materias} materias',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
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

  Color _getPositionColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Oro
      case 1:
        return const Color(0xFFC0C0C0); // Plata
      case 2:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return AppColors.surfaceVariant;
    }
  }

  Widget _buildNoData(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.noData,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
