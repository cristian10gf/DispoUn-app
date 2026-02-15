import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../data/services/file_storage_service.dart';
import '../../../domain/providers/data_provider.dart';
import '../../../domain/providers/mi_horario_provider.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../domain/providers/theme_provider.dart';

/// Pagina de ajustes
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _multiSelectMode = false;
  bool _isLoadingMultiSelect = true;

  @override
  void initState() {
    super.initState();
    _loadMultiSelectMode();
  }

  Future<void> _loadMultiSelectMode() async {
    final savedMode = await FileStorageService.loadMultiSelectMode();
    if (mounted) {
      setState(() {
        _multiSelectMode = savedMode;
        _isLoadingMultiSelect = false;
      });
    }
  }

  Future<void> _saveMultiSelectMode(bool value) async {
    await FileStorageService.saveMultiSelectMode(value);
    setState(() {
      _multiSelectMode = value;
    });
  }

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
            // Seccion de apariencia
            Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Apariencia'),
                    const SizedBox(height: 12),
                    _buildThemeSelector(context),
                  ],
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.03, end: 0, duration: 300.ms),
            const SizedBox(height: 32),

            // Seccion de archivos JSON
            Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppStrings.archivosJson),
                    const SizedBox(height: 12),
                    if (dataState.activeFilePaths.isNotEmpty)
                      _buildActiveFilesCard(
                        context,
                        dataState.activeFilePaths,
                        dataState.repository?.total ?? 0,
                        dataState.isMultipleFiles,
                      ),
                    const SizedBox(height: 16),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                    if (dataState.availableFiles.length > 1) ...[
                      _buildMultiSelectToggle(context),
                      const SizedBox(height: 16),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildSectionHeader(
                        context,
                        _multiSelectMode
                            ? AppStrings.seleccionarParaCombinar
                            : 'Archivos disponibles',
                        key: ValueKey(_multiSelectMode),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: dataState.availableFiles.isEmpty
                          ? _buildEmptyFilesMessage(context)
                          : _buildFilesList(
                              dataState.availableFiles,
                              dataState.activeFilePaths,
                              ref,
                              context,
                            ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.03, end: 0, delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 32),

            // Seccion de Mi Horario
            Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, AppStrings.miHorario),
                    const SizedBox(height: 12),
                    _buildMiHorarioSettings(context),
                  ],
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.03, end: 0, delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 32),

            // Seccion de notificaciones (solo si tiene NRCs)
            if (ref.watch(miHorarioNotifierProvider).tieneNrcs)
              Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Notificaciones'),
                      const SizedBox(height: 12),
                      _buildNotificationSettings(context),
                      const SizedBox(height: 32),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 400.ms)
                  .slideY(begin: 0.03, end: 0),

            // Informacion de la app
            Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Acerca de'),
                    const SizedBox(height: 12),
                    _buildAboutCard(context),
                  ],
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms)
                .slideY(begin: 0.03, end: 0, delay: 300.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = ref.watch(themeNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Modo de tema',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildThemeOption(
                context,
                icon: Icons.light_mode_outlined,
                label: 'Claro',
                mode: AppThemeMode.light,
                isSelected: currentMode == AppThemeMode.light,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                context,
                icon: Icons.dark_mode_outlined,
                label: 'Oscuro',
                mode: AppThemeMode.dark,
                isSelected: currentMode == AppThemeMode.dark,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                context,
                icon: Icons.settings_suggest_outlined,
                label: 'Sistema',
                mode: AppThemeMode.system,
                isSelected: currentMode == AppThemeMode.system,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppThemeMode mode,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _multiSelectMode
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _multiSelectMode
              ? colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _multiSelectMode ? Icons.layers : Icons.layers_outlined,
            color: _multiSelectMode
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
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
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Une datos de multiples archivos',
                  style: TextStyle(color: colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _multiSelectMode,
            onChanged: _isLoadingMultiSelect
                ? null
                : (value) {
                    _saveMultiSelectMode(value);
                  },
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Key? key}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      key: key,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActiveFilesCard(
    BuildContext context,
    List<String> filePaths,
    int totalHorarios,
    bool isMultiple,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final fileNames = filePaths.map((p) => p.split('/').last).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isMultiple ? Icons.layers : Icons.check_circle,
              color: colorScheme.primary,
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
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMultiple) ...[
                  Text(
                    '${filePaths.length} archivos',
                    style: TextStyle(
                      color: colorScheme.onSurface,
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
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 14,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  isMultiple
                      ? '$totalHorarios horarios (${AppStrings.datosCombinados})'
                      : '$totalHorarios horarios cargados',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildEmptyFilesMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay archivos cargados',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Carga un archivo JSON para comenzar',
            style: TextStyle(color: colorScheme.outline, fontSize: 12),
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

        final colorScheme = Theme.of(context).colorScheme;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
          child: ListTile(
            leading: _multiSelectMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleFileSelection(ref, file.path),
                    activeColor: colorScheme.primary,
                  )
                : Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.description_outlined,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
            title: Text(
              file.name,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${file.sizeFormatted} | ${_formatDate(file.modified)}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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
                          color: colorScheme.primary,
                          onPressed: () => _loadFile(ref, file.path, context),
                          tooltip: 'Usar este archivo',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: colorScheme.error,
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

  Widget _buildMiHorarioSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final miHorarioState = ref.watch(miHorarioNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
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
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.miHorarioPrincipalDescripcion,
                      style: TextStyle(
                        color: colorScheme.outline,
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
                activeThumbColor: colorScheme.primary,
              ),
            ],
          ),

          // Info de NRCs configurados
          Divider(height: 24, color: theme.dividerColor),
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  miHorarioState.tieneNrcs
                      ? '${miHorarioState.nrcs.length} NRC(s) configurados'
                      : AppStrings.sinNrcsConfigurados,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildNotificationSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifSettings = ref.watch(notificationSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Toggle de notificaciones
          Row(
            children: [
              Icon(
                notifSettings.enabled
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: notifSettings.enabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recordatorios de clase',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recibe un aviso antes de cada clase',
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: notifSettings.enabled,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .setEnabled(value);
                },
              ),
            ],
          ),

          // Selector de tiempo de anticipacion
          if (notifSettings.enabled) ...[
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avisar con anticipacion:',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notificationMinuteOptions.map((minutes) {
                final isSelected = notifSettings.minutesBefore == minutes;
                final label = minutes >= 60
                    ? '${minutes ~/ 60} hora'
                    : '$minutes min';

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .setMinutesBefore(minutes);
                    }
                  },
                  selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Aplicacion para consultar disponibilidad de salones, horarios de profesores y materias de Uninorte.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
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
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? AppStrings.archivoCargado : AppStrings.archivoInvalido,
          ),
          backgroundColor: success ? AppColors.success : colorScheme.error,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
