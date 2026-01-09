import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../data/repositories/horario_repository.dart';
import '../../../../domain/providers/filter_provider.dart';

/// Tabla de salones disponibles/ocupados
class AvailabilityTable extends ConsumerWidget {
  final Function(String salon)? onSalonTap;

  const AvailabilityTable({super.key, this.onSalonTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salones = ref.watch(salonesDisponiblesProvider);
    final filtroActual = ref.watch(availabilityFilterProvider).disponibilidadFiltro;

    // Contar totales (sin filtro de disponibilidad)
    final todosLosSalones = ref.watch(salonesDisponiblesSinFiltroProvider);
    final totalDisponibles = todosLosSalones.where((s) => s.disponible).length;
    final totalOcupados = todosLosSalones.length - totalDisponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selectores de filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: '$totalDisponibles ${AppStrings.salonDisponible}s',
                color: AppColors.success,
                isSelected: filtroActual == DisponibilidadFiltro.disponibles,
                onTap: () {
                  final notifier = ref.read(availabilityFilterProvider.notifier);
                  if (filtroActual == DisponibilidadFiltro.disponibles) {
                    notifier.setDisponibilidadFiltro(DisponibilidadFiltro.todos);
                  } else {
                    notifier.setDisponibilidadFiltro(DisponibilidadFiltro.disponibles);
                  }
                },
              ),
              const SizedBox(width: 12),
              _FilterChip(
                label: '$totalOcupados ${AppStrings.salonOcupado}s',
                color: AppColors.error,
                isSelected: filtroActual == DisponibilidadFiltro.ocupados,
                onTap: () {
                  final notifier = ref.read(availabilityFilterProvider.notifier);
                  if (filtroActual == DisponibilidadFiltro.ocupados) {
                    notifier.setDisponibilidadFiltro(DisponibilidadFiltro.todos);
                  } else {
                    notifier.setDisponibilidadFiltro(DisponibilidadFiltro.ocupados);
                  }
                },
              ),
            ],
          ),
        ),

        // Lista de salones o mensaje vacio
        if (salones.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noResults,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          ...salones.map((salon) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SalonTile(
                  salon: salon,
                  onTap: onSalonTap != null
                      ? () => onSalonTap!(salon.nombreSalon)
                      : null,
                ),
              )),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Chip de filtro seleccionable
class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SalonTile extends StatelessWidget {
  final SalonDisponibilidad salon;
  final VoidCallback? onTap;

  const _SalonTile({required this.salon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = salon.disponible ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Indicador de disponibilidad
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),

              // Info del salon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.nombreSalon,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      salon.nombreBloque,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (salon.ocupadoPor != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        salon.ocupadoPor!.nombreMateria,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Estado y flecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      salon.disponible
                          ? AppStrings.salonDisponible
                          : AppStrings.salonOcupado,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

