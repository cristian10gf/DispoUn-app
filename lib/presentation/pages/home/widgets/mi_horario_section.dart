import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../data/models/horario.dart';
import '../../../../domain/providers/mi_horario_provider.dart';
import '../../../../domain/providers/next_class_provider.dart';
import '../../../widgets/horario_grid.dart';
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

  /// Construye el widget exportable completo para captura
  /// Debe estar envuelto en Material y Directionality para renderizar correctamente
  Widget _buildExportableWidget(
    List<Horario> horarios,
    List<NrcInfo> nrcInfos,
  ) {
    // Calcular el ancho total del grid: tiempo (80) + 6 días * 110 = 740
    // Agregar padding (16) = 756
    // La leyenda usa cards de 158px cada una, queremos que quepan 4 por fila
    // 4 * 158 + 3 * 8 (spacing) = 656, menor que el grid, así que usamos el ancho del grid
    const totalWidth = 756.0;

    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.white,
          child: UnconstrainedBox(
            constrainedAxis: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: _ExportableHorarioContent(
                horarios: horarios,
                nrcInfos: nrcInfos,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Captura el horario completo como imagen
  Future<Uint8List?> _captureFullHorario() async {
    final horarios = ref.read(miHorarioHorariosProvider);
    final miHorarioState = ref.read(miHorarioNotifierProvider);

    // Obtener info de cada NRC
    final nrcInfos = <NrcInfo>[];
    for (final nrc in miHorarioState.nrcs) {
      final info = ref.read(nrcInfoProvider(nrc));
      if (info != null) {
        nrcInfos.add(info);
      }
    }

    // Usar captureFromLongWidget para capturar widgets largos completos
    // Este método está diseñado específicamente para widgets que exceden la pantalla
    // Importante: el widget debe usar Column (no ListView) y no usar Expanded/Flexible
    return await _screenshotController.captureFromLongWidget(
      _buildExportableWidget(horarios, nrcInfos),
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 100),
    );
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);

    try {
      final image = await _captureFullHorario();

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
      final image = await _captureFullHorario();

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

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Mi horario - DispoUn'),
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
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openNrcDialog() async {
    await NrcInputDialog.show(context);
  }

  Widget _buildMateriaLegend(List<NrcInfo> nrcInfos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: nrcInfos.map((info) {
          final color = AppColors.getColorForString(info.nombreMateria);
          return Container(
            width: 160,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.nombreMateria,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NRC ${info.nrc}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info.codigoConjunto,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.profesor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getCuposColor(info.cuposDisponibles),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${info.cuposDisponibles} Cupos disponibles',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getCuposColor(int cupos) {
    if (cupos <= 0) return Colors.red.withValues(alpha: 0.3);
    if (cupos <= 5) return Colors.orange.withValues(alpha: 0.3);
    if (cupos <= 15) return Colors.yellow.withValues(alpha: 0.3);
    return Colors.green.withValues(alpha: 0.3);
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
              // Banner de proxima clase
              _buildNextClassBanner(context, ref),

              // Header con acciones
              _buildHeader(nrcInfos.length),

              // Grid de horario usando HorarioGrid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child:
                    HorarioGrid(
                          horarios: horarios,
                          onHorarioTap: (horario) {
                            context.push('/nrc/${horario.nrc}');
                          },
                        )
                        .animate()
                        .slideX(begin: 0.05, end: 0, duration: 300.ms)
                        .fadeIn(duration: 300.ms),
              ),

              // Leyenda de materias
              if (nrcInfos.isNotEmpty)
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${AppStrings.materias} (${nrcInfos.length})',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMateriaLegend(nrcInfos),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms)
                    .slideY(
                      begin: 0.03,
                      end: 0,
                      delay: 150.ms,
                      duration: 300.ms,
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.edit_outlined),
            label: const Text(AppStrings.editarNrcs),
          ),
        ),

        // Indicador de carga
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildNextClassBanner(BuildContext context, WidgetRef ref) {
    final nextClass = ref.watch(nextClassProvider);
    if (nextClass == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isNow = nextClass.timeUntil == Duration.zero;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isNow ? Icons.school : Icons.schedule,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNow ? 'En clase ahora' : 'Proxima clase',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextClass.nombreMateria,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Salon ${nextClass.horario.nombreSalon}'
                  ' - ${nextClass.horaFormateada}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              nextClass.timeUntilFormatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tooltip: AppStrings.compartirHorario,
          ),
          // Boton descargar
          IconButton(
            onPressed: _saveToGallery,
            icon: const Icon(Icons.download_outlined),
            color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.sinNrcsConfigurados,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.sinNrcsDescripcion,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
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

/// Widget de contenido exportable para captura completa (sin scroll)
class _ExportableHorarioContent extends StatelessWidget {
  final List<Horario> horarios;
  final List<NrcInfo> nrcInfos;

  // Dias a mostrar (sin domingo)
  static const List<String> _diasMostrar = ['L', 'M', 'X', 'J', 'V', 'S'];
  static const int _startHour = 6;
  static const int _endHour = 20;

  const _ExportableHorarioContent({
    required this.horarios,
    required this.nrcInfos,
  });

  @override
  Widget build(BuildContext context) {
    const cellHeight = 28.0;
    const timeColumnWidth = 80.0;
    const dayColumnWidth = 110.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Mi Horario - DispoUn',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Grid de horario (sin scroll)
          _buildHeader(timeColumnWidth, dayColumnWidth),
          for (int hour = _startHour; hour < _endHour; hour++)
            _buildRow(hour, timeColumnWidth, dayColumnWidth, cellHeight),
          const SizedBox(height: 16),
          // Leyenda de materias
          _buildMateriaLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader(double timeColumnWidth, double dayColumnWidth) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: timeColumnWidth, height: 24),
          for (final dia in _diasMostrar)
            Container(
              width: dayColumnWidth,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Text(
                _getDiaCompleto(dia),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDiaCompleto(String dia) {
    const dias = {
      'L': 'LUNES',
      'M': 'MARTES',
      'X': 'MIÉRCOLES',
      'J': 'JUEVES',
      'V': 'VIERNES',
      'S': 'SÁBADO',
      'D': 'DOMINGO',
    };
    return dias[dia] ?? dia;
  }

  Widget _buildRow(
    int hour,
    double timeColumnWidth,
    double dayColumnWidth,
    double cellHeight,
  ) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    final nextHourString = '${(hour + 1).toString().padLeft(2, '0')}:00';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: timeColumnWidth,
          height: cellHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
              right: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              '$timeString - $nextHourString',
              style: const TextStyle(color: Colors.black54, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        for (final dia in _diasMostrar)
          _buildCell(dia, hour, dayColumnWidth, cellHeight),
      ],
    );
  }

  Widget _buildCell(String dia, int hour, double dayWidth, double cellHeight) {
    final horariosEnCelda = horarios.where((h) {
      if (h.dia != dia) return false;
      final horaInicio = _parseTimeToMinutes(h.horaInicio);
      final horaFin = _parseTimeToMinutes(h.horaFin);
      final cellStart = hour * 60;
      final cellEnd = (hour + 1) * 60;
      return horaInicio < cellEnd && horaFin > cellStart;
    }).toList();

    return Container(
      width: dayWidth,
      height: cellHeight,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey, width: 0.5),
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: horariosEnCelda.isEmpty
          ? const SizedBox.shrink()
          : _buildHorarioCell(horariosEnCelda),
    );
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  Widget _buildHorarioCell(List<Horario> horariosEnCelda) {
    if (horariosEnCelda.length == 1) {
      final horario = horariosEnCelda.first;
      final color = AppColors.getColorForString(horario.nombreMateria);

      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Text(
            horario.nombreSalon,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 1,
      runSpacing: 1,
      children: horariosEnCelda.map((horario) {
        final color = AppColors.getColorForString(horario.nombreMateria);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            horario.nombreSalon,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMateriaLegend() {
    if (nrcInfos.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nrcInfos.map((info) {
        final color = AppColors.getColorForString(info.nombreMateria);
        return Container(
          width: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.nombreMateria,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'NRC ${info.nrc}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info.codigoConjunto,
                style: const TextStyle(color: Colors.black54, fontSize: 8),
              ),
              const SizedBox(height: 2),
              Text(
                info.profesor,
                style: const TextStyle(color: Colors.black54, fontSize: 8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCuposColor(info.cuposDisponibles),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${info.cuposDisponibles} Cupos',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCuposColor(int cupos) {
    if (cupos <= 0) return Colors.red.withValues(alpha: 0.3);
    if (cupos <= 5) return Colors.orange.withValues(alpha: 0.3);
    if (cupos <= 15) return Colors.yellow.withValues(alpha: 0.3);
    return Colors.green.withValues(alpha: 0.3);
  }
}
