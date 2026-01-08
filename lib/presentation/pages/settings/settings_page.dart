import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/services/file_storage_service.dart';
import '../../../domain/providers/data_provider.dart';

/// Pagina de ajustes
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // Archivo activo
            if (dataState.activeFilePath != null)
              _buildActiveFileCard(
                dataState.activeFilePath!,
                dataState.repository?.total ?? 0,
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

            // Lista de archivos disponibles
            _buildSectionHeader('Archivos disponibles'),
            const SizedBox(height: 12),

            if (dataState.availableFiles.isEmpty)
              _buildEmptyFilesMessage()
            else
              _buildFilesList(
                dataState.availableFiles,
                dataState.activeFilePath,
                ref,
                context,
              ),

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

  Widget _buildActiveFileCard(String filePath, int totalHorarios) {
    final fileName = filePath.split('/').last;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.archivoActivo,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalHorarios horarios cargados',
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
    String? activePath,
    WidgetRef ref,
    BuildContext context,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isActive = file.path == activePath;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isActive ? AppColors.primaryRed.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: Icon(
              isActive ? Icons.check_circle : Icons.description_outlined,
              color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
            ),
            title: Text(
              file.name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${file.sizeFormatted} | ${_formatDate(file.modified)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isActive)
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

