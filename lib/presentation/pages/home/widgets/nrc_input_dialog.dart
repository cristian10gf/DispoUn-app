import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../domain/providers/mi_horario_provider.dart';

/// Dialogo para agregar y gestionar NRCs
class NrcInputDialog extends ConsumerStatefulWidget {
  const NrcInputDialog({super.key});

  /// Muestra el dialogo y retorna true si se realizaron cambios
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const NrcInputDialog(),
    );
  }

  @override
  ConsumerState<NrcInputDialog> createState() => _NrcInputDialogState();
}

class _NrcInputDialogState extends ConsumerState<NrcInputDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _resultMessage;
  bool _isError = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addNrcs() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Parsear NRCs (separados por coma, espacio o salto de linea)
    final nrcStrings = text.split(RegExp(r'[,\s\n]+'));
    final nrcs = <int>[];

    for (final str in nrcStrings) {
      final trimmed = str.trim();
      if (trimmed.isEmpty) continue;
      final nrc = int.tryParse(trimmed);
      if (nrc != null) {
        nrcs.add(nrc);
      }
    }

    if (nrcs.isEmpty) {
      setState(() {
        _resultMessage = 'No se encontraron NRCs validos';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final notifier = ref.read(miHorarioNotifierProvider.notifier);
    final result = await notifier.addMultipleNrcs(nrcs);

    setState(() {
      _isLoading = false;
    });

    if (result.todosBien) {
      HapticFeedback.mediumImpact();
      setState(() {
        _resultMessage = '${result.agregados.length} NRC(s) agregado(s)';
        _isError = false;
      });
      _controller.clear();
    } else {
      final messages = <String>[];
      if (result.agregados.isNotEmpty) {
        messages.add('Agregados: ${result.agregados.join(", ")}');
      }
      if (result.noEncontrados.isNotEmpty) {
        messages.add('No encontrados: ${result.noEncontrados.join(", ")}');
      }
      if (result.yaExistentes.isNotEmpty) {
        messages.add('Ya existentes: ${result.yaExistentes.join(", ")}');
      }
      setState(() {
        _resultMessage = messages.join('\n');
        _isError = result.noEncontrados.isNotEmpty;
      });
      if (result.algunoAgregado) {
        HapticFeedback.mediumImpact();
        _controller.clear();
      }
    }
  }

  Future<void> _removeNrc(int nrc) async {
    await ref.read(miHorarioNotifierProvider.notifier).removeNrc(nrc);
  }

  Future<void> _clearAllNrcs() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          AppStrings.eliminarTodosNrcs,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          AppStrings.confirmarEliminarNrcs,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(miHorarioNotifierProvider.notifier).clearNrcs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final miHorarioState = ref.watch(miHorarioNotifierProvider);
    final nrcs = miHorarioState.nrcs;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titulo
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_calendar_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.editarNrcs,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (nrcs.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        color: colorScheme.error,
                        onPressed: _clearAllNrcs,
                        tooltip: AppStrings.eliminarTodosNrcs,
                      ),
                  ],
                ),
              ),

              Divider(color: Theme.of(context).dividerColor),

              // Input de NRCs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: AppStrings.ingresarNrcs,
                        hintStyle: TextStyle(color: colorScheme.outline),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: colorScheme.primary,
                                onPressed: _addNrcs,
                              ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,\s]')),
                      ],
                      onSubmitted: (_) => _addNrcs(),
                    ),
                    if (_resultMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _resultMessage!,
                          style: TextStyle(
                            color: _isError
                                ? colorScheme.error
                                : AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Lista de NRCs actuales
              Expanded(
                child: nrcs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: nrcs.length,
                        itemBuilder: (context, index) {
                          final nrc = nrcs[index];
                          return _NrcListItem(
                            nrc: nrc,
                            onRemove: () => _removeNrc(nrc),
                          );
                        },
                      ),
              ),

              // Boton cerrar
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Listo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.playlist_add_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aun no has agregado NRCs',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa los NRCs de tus materias arriba',
            style: TextStyle(color: colorScheme.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Item de la lista de NRCs
class _NrcListItem extends ConsumerWidget {
  final int nrc;
  final VoidCallback onRemove;

  const _NrcListItem({required this.nrc, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final info = ref.watch(nrcInfoProvider(nrc));

    if (info == null) {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'NRC $nrc',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          'NRC no encontrado',
          style: TextStyle(color: colorScheme.error),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: colorScheme.error,
          onPressed: onRemove,
        ),
      );
    }

    final color = AppColors.getColorForString(info.nombreMateria);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'NRC $nrc',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          info.nombreMateria,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          info.profesor,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: colorScheme.error,
          onPressed: onRemove,
        ),
      ),
    );
  }
}
