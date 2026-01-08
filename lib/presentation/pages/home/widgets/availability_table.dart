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

    if (salones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text(
                AppStrings.noResults,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final disponibles = salones.where((s) => s.disponible).length;
    final ocupados = salones.length - disponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildResumenChip(
                '$disponibles ${AppStrings.salonDisponible}s',
                AppColors.success,
              ),
              const SizedBox(width: 12),
              _buildResumenChip(
                '$ocupados ${AppStrings.salonOcupado}s',
                AppColors.error,
              ),
            ],
          ),
        ),

        // Lista de salones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: salones.length,
            itemBuilder: (context, index) {
              final salon = salones[index];
              return _SalonTile(
                salon: salon,
                onTap: onSalonTap != null
                    ? () => onSalonTap!(salon.nombreSalon)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResumenChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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

