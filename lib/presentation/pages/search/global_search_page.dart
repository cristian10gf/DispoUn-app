import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../domain/providers/data_provider.dart';

/// Tipos de resultados de busqueda
enum SearchResultType { materia, salon, profesor }

/// Modelo para un resultado de busqueda
class SearchResult {
  final String nombre;
  final SearchResultType tipo;
  final String? subtitulo;

  const SearchResult({
    required this.nombre,
    required this.tipo,
    this.subtitulo,
  });
}

/// Notifier para la query de busqueda global
class _GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Establece un nuevo valor
  void set(String value) => state = value;
}

/// Provider para la query de busqueda global
final globalSearchQueryProvider =
    NotifierProvider<_GlobalSearchQueryNotifier, String>(
      _GlobalSearchQueryNotifier.new,
    );

/// Provider para los resultados de busqueda global
final globalSearchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(globalSearchQueryProvider).toLowerCase().trim();
  final dataState = ref.watch(dataNotifierProvider);

  if (query.isEmpty || dataState.repository == null) {
    return [];
  }

  final repo = dataState.repository!;
  final results = <SearchResult>[];

  // Buscar materias
  for (final materia in repo.materias) {
    if (materia.toLowerCase().contains(query)) {
      results.add(
        SearchResult(nombre: materia, tipo: SearchResultType.materia),
      );
    }
  }

  // Buscar salones
  for (final salon in repo.salones) {
    if (salon.toLowerCase().contains(query)) {
      final bloque = repo.getBloqueForSalon(salon);
      results.add(
        SearchResult(
          nombre: salon,
          tipo: SearchResultType.salon,
          subtitulo: bloque.isNotEmpty ? bloque : null,
        ),
      );
    }
  }

  // Buscar profesores
  for (final profesor in repo.profesores) {
    if (profesor.toLowerCase().contains(query)) {
      results.add(
        SearchResult(nombre: profesor, tipo: SearchResultType.profesor),
      );
    }
  }

  // Limitar resultados para mejor rendimiento
  return results.take(50).toList();
});

/// Pagina de busqueda global
class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Enfocar el campo de busqueda al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final results = ref.watch(globalSearchResultsProvider);
    final query = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: AppStrings.buscarTodo,
            hintStyle: TextStyle(color: colorScheme.outline),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
          onChanged: (value) {
            ref.read(globalSearchQueryProvider.notifier).set(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(globalSearchQueryProvider.notifier).set('');
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? _buildEmptyState(colorScheme)
          : results.isEmpty
          ? _buildNoResults(colorScheme)
          : _buildResults(results, colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.buscarTodo,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ColorScheme colorScheme) {
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

  Widget _buildResults(List<SearchResult> results, ColorScheme colorScheme) {
    // Agrupar resultados por tipo
    final materias = results
        .where((r) => r.tipo == SearchResultType.materia)
        .toList();
    final salones = results
        .where((r) => r.tipo == SearchResultType.salon)
        .toList();
    final profesores = results
        .where((r) => r.tipo == SearchResultType.profesor)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (materias.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.materias,
            Icons.menu_book,
            materias.length,
            colorScheme,
          ),
          ...materias.map((r) => _buildResultTile(r, colorScheme)),
          const SizedBox(height: 16),
        ],
        if (salones.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.salon,
            Icons.meeting_room,
            salones.length,
            colorScheme,
          ),
          ...salones.map((r) => _buildResultTile(r, colorScheme)),
          const SizedBox(height: 16),
        ],
        if (profesores.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.profesores,
            Icons.person,
            profesores.length,
            colorScheme,
          ),
          ...profesores.map((r) => _buildResultTile(r, colorScheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    int count,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(SearchResult result, ColorScheme colorScheme) {
    final (icon, color, route) = switch (result.tipo) {
      SearchResultType.materia => (
        Icons.menu_book,
        AppColors.getColorForString(result.nombre),
        '/materia/${Uri.encodeComponent(result.nombre)}',
      ),
      SearchResultType.salon => (
        Icons.meeting_room,
        AppColors.getColorForString(result.nombre),
        '/salon/${Uri.encodeComponent(result.nombre)}',
      ),
      SearchResultType.profesor => (
        Icons.person,
        colorScheme.primary,
        '/profesor/${Uri.encodeComponent(result.nombre)}',
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          result.tipo == SearchResultType.profesor
              ? result.nombre.normalizeProfesorName()
              : result.nombre,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: result.subtitulo != null
            ? Text(
                result.subtitulo!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
        onTap: () => context.push(route),
      ),
    );
  }
}
