import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/services/file_storage_service.dart';
import '../../../domain/providers/data_provider.dart';
import '../../../domain/providers/mi_horario_provider.dart';

/// Pagina de ajustes
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _multiSelectMode = false;

  @override
  Widget build(BuildContext context) {
    final dataState = ref.watch(dataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ajustes),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seccion de archivos JSON
            _buildSectionHeader(AppStrings.archivosJson),
            const SizedBox(height: 12),

            // Archivos activos (uno o varios combinados)
            if (dataState.activeFilePaths.isNotEmpty)
              _buildActiveFilesCard(
                dataState.activeFilePaths,
                dataState.repository?.total ?? 0,
                dataState.isMultipleFiles,
              ),

            const SizedBox(height: 16),

            // Boton para cargar archivo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: dataState.isLoading
                    ? null
                    : () => _importFile(context, ref),
                icon: dataState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  dataState.isLoading
                      ? AppStrings.loading
                      : AppStrings.cargarArchivo,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Toggle para modo seleccion multiple
            if (dataState.availableFiles.length > 1) ...[
              _buildMultiSelectToggle(),
              const SizedBox(height: 16),
            ],

            // Lista de archivos disponibles
            _buildSectionHeader(
              _multiSelectMode
                  ? AppStrings.seleccionarParaCombinar
                  : 'Archivos disponibles',
            ),
            const SizedBox(height: 12),

            if (dataState.availableFiles.isEmpty)
              _buildEmptyFilesMessage()
            else
              _buildFilesList(
                dataState.availableFiles,
                dataState.activeFilePaths,
                ref,
                context,
              ),

            const SizedBox(height: 32),

            // Seccion de Mi Horario
            _buildSectionHeader(AppStrings.miHorario),
            const SizedBox(height: 12),
            _buildMiHorarioSettings(),

            const SizedBox(height: 32),

            // Informacion de la app
            _buildSectionHeader('Acerca de'),
            const SizedBox(height: 12),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: _multiSelectMode
            ? Border.all(color: AppColors.primaryRed.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            _multiSelectMode ? Icons.layers : Icons.layers_outlined,
            color: _multiSelectMode
                ? AppColors.primaryRed
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.combinarArchivos,
                  style: TextStyle(
                    color: _multiSelectMode
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Une datos de multiples archivos',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _multiSelectMode,
            onChanged: (value) {
              setState(() {
                _multiSelectMode = value;
              });
            },
            activeColor: AppColors.primaryRed,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActiveFilesCard(
    List<String> filePaths,
    int totalHorarios,
    bool isMultiple,
  ) {
    final fileNames = filePaths.map((p) => p.split('/').last).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isMultiple ? Icons.layers : Icons.check_circle,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMultiple
                      ? AppStrings.archivosCombinados
                      : AppStrings.archivoActivo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMultiple) ...[
                  Text(
                    '${filePaths.length} archivos',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...fileNames.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  Text(
                    fileNames.first,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  isMultiple
                      ? '$totalHorarios horarios (${AppStrings.datosCombinados})'
                      : '$totalHorarios horarios cargados',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilesMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 12),
          Text(
            'No hay archivos cargados',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Carga un archivo JSON para comenzar',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(
    List<FileInfo> files,
    List<String> activePaths,
    WidgetRef ref,
    BuildContext context,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = activePaths.contains(file.path);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primaryRed.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: _multiSelectMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleFileSelection(ref, file.path),
                    activeColor: AppColors.primaryRed,
                  )
                : Icon(
                    isSelected ? Icons.check_circle : Icons.description_outlined,
                    color:
                        isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                  ),
            title: Text(
              file.name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${file.sizeFormatted} | ${_formatDate(file.modified)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            onTap: _multiSelectMode
                ? () => _toggleFileSelection(ref, file.path)
                : null,
            trailing: _multiSelectMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSelected)
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          color: AppColors.primaryRed,
                          onPressed: () => _loadFile(ref, file.path, context),
                          tooltip: 'Usar este archivo',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.error,
                        onPressed: () => _confirmDelete(context, ref, file),
                        tooltip: AppStrings.eliminarArchivo,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFileSelection(WidgetRef ref, String filePath) async {
    await ref.read(dataNotifierProvider.notifier).toggleFileSelection(filePath);
  }

  Widget _buildMiHorarioSettings() {
    final miHorarioState = ref.watch(miHorarioNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Opcion de pantalla principal
          Row(
            children: [
              Icon(
                miHorarioState.esPantallaPrincipal
                    ? Icons.home
                    : Icons.home_outlined,
                color: miHorarioState.esPantallaPrincipal
                    ? AppColors.primaryRed
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.miHorarioPrincipal,
                      style: TextStyle(
                        color: miHorarioState.esPantallaPrincipal
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      AppStrings.miHorarioPrincipalDescripcion,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: miHorarioState.esPantallaPrincipal,
                onChanged: miHorarioState.tieneNrcs
                    ? (value) {
                        ref
                            .read(miHorarioNotifierProvider.notifier)
                            .setPantallaPrincipal(value);
                      }
                    : null,
                activeColor: AppColors.primaryRed,
              ),
            ],
          ),

          // Info de NRCs configurados
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  miHorarioState.tieneNrcs
                      ? '${miHorarioState.nrcs.length} NRC(s) configurados'
                      : AppStrings.sinNrcsConfigurados,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              if (miHorarioState.tieneNrcs)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    miHorarioState.nrcs.join(', '),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryRed,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplicacion para consultar disponibilidad de salones, horarios de profesores y materias de Uninorte.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(dataNotifierProvider.notifier).importFile();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? AppStrings.archivoCargado : AppStrings.archivoInvalido,
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadFile(
    WidgetRef ref,
    String path,
    BuildContext context,
  ) async {
    await ref.read(dataNotifierProvider.notifier).loadFromFile(path);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.archivoCargado),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FileInfo file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.eliminarArchivo),
        content: Text('${AppStrings.confirmarEliminar}\n\n${file.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(dataNotifierProvider.notifier)
                  .deleteFile(file.path);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

