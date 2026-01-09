import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../domain/providers/data_provider.dart';
import '../../../../domain/providers/filter_provider.dart';

/// Widget de filtros de disponibilidad
class AvailabilityFilters extends ConsumerWidget {
  const AvailabilityFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(availabilityFilterProvider);
    final bloques = ref.watch(bloquesListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                AppStrings.filtros,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(availabilityFilterProvider.notifier).reset();
                },
                child: const Text(AppStrings.limpiarFiltros),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dia de la semana
          const Text(
            AppStrings.dia,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppStrings.diasOrden.map((dia) {
                final isSelected = filter.dia == dia;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(AppStrings.diasCompletos[dia] ?? dia),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(availabilityFilterProvider.notifier)
                            .setDia(dia);
                      }
                    },
                    selectedColor: AppColors.primaryRed.withValues(alpha: 0.3),
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Hora inicio y fin
          Row(
            children: [
              Expanded(
                child: _TimeSelector(
                  label: AppStrings.horaInicio,
                  value: filter.horaInicio,
                  onChanged: (value) {
                    ref
                        .read(availabilityFilterProvider.notifier)
                        .setHoraInicio(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeSelector(
                  label: AppStrings.horaFin,
                  value: filter.horaFin,
                  onChanged: (value) {
                    ref
                        .read(availabilityFilterProvider.notifier)
                        .setHoraFin(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bloque
          const Text(
            AppStrings.bloque,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: filter.bloque,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text(AppStrings.todosLosBloques),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.todosLosBloques),
              ),
              ...bloques.map(
                (bloque) =>
                    DropdownMenuItem(value: bloque, child: Text(bloque)),
              ),
            ],
            onChanged: (value) {
              ref.read(availabilityFilterProvider.notifier).setBloque(value);
            },
          ),
        ],
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimeSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(16, (i) => i + 6); // 6:00 a 21:00

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: hours.map((hour) {
            final timeStr = '${hour.toString().padLeft(2, '0')}:00:00';
            return DropdownMenuItem(
              value: timeStr,
              child: Text('${hour.toString().padLeft(2, '0')}:00'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}
