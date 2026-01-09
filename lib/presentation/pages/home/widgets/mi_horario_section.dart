import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../domain/providers/mi_horario_provider.dart';
import '../../../widgets/mi_horario_exportable_grid.dart';
import 'nrc_input_dialog.dart';

/// Seccion de Mi Horario que muestra el horario personal del usuario
class MiHorarioSection extends ConsumerStatefulWidget {
  const MiHorarioSection({super.key});

  @override
  ConsumerState<MiHorarioSection> createState() => _MiHorarioSectionState();
}

class _MiHorarioSectionState extends ConsumerState<MiHorarioSection> {
  final _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);

    try {
      final image = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      if (image == null) {
        _showMessage(AppStrings.errorGuardarHorario, isError: true);
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        image,
        quality: 100,
        name: 'mi_horario_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _showMessage(AppStrings.horarioGuardado);
      } else {
        _showMessage(AppStrings.errorGuardarHorario, isError: true);
      }
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _shareHorario() async {
    setState(() => _isSaving = true);

    try {
      final image = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      if (image == null) {
        _showMessage(AppStrings.errorGuardarHorario, isError: true);
        return;
      }

      // Guardar temporalmente para compartir
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mi_horario_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mi horario - DispoUn',
      );
    } catch (e) {
      _showMessage('Error al compartir: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openNrcDialog() async {
    await NrcInputDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final miHorarioState = ref.watch(miHorarioNotifierProvider);
    final horarios = ref.watch(miHorarioHorariosProvider);

    // Obtener info de cada NRC
    final nrcInfos = <NrcInfo>[];
    for (final nrc in miHorarioState.nrcs) {
      final info = ref.watch(nrcInfoProvider(nrc));
      if (info != null) {
        nrcInfos.add(info);
      }
    }

    if (!miHorarioState.tieneNrcs) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con acciones
              _buildHeader(nrcInfos.length),

              // Grid de horario
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: MiHorarioExportableGrid(
                  horarios: horarios,
                  nrcInfos: nrcInfos,
                  screenshotController: _screenshotController,
                  onHorarioTap: (horario) {
                    context.push('/nrc/${horario.nrc}');
                  },
                ),
              ),
            ],
          ),
        ),

        // FAB para editar NRCs
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _openNrcDialog,
            backgroundColor: AppColors.primaryRed,
            icon: const Icon(Icons.edit_outlined),
            label: const Text(AppStrings.editarNrcs),
          ),
        ),

        // Indicador de carga
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(int cantidadMaterias) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cantidadMaterias ${cantidadMaterias == 1 ? "materia" : "materias"}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Boton compartir
          IconButton(
            onPressed: _shareHorario,
            icon: const Icon(Icons.share_outlined),
            color: AppColors.textSecondary,
            tooltip: AppStrings.compartirHorario,
          ),
          // Boton descargar
          IconButton(
            onPressed: _saveToGallery,
            icon: const Icon(Icons.download_outlined),
            color: AppColors.primaryRed,
            tooltip: AppStrings.descargarHorario,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.sinNrcsConfigurados,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.sinNrcsDescripcion,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openNrcDialog,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.agregarNrcs),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
