import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/strings.dart';
import '../../../../domain/providers/data_provider.dart';
import '../../../../domain/providers/filter_provider.dart';

/// Widget de filtros de disponibilidad
class AvailabilityFilters extends ConsumerWidget {
  const AvailabilityFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final filter = ref.watch(availabilityFilterProvider);
    final bloques = ref.watch(bloquesListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.filtros,
                style: TextStyle(
                  color: colorScheme.onSurface,
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
          Text(
            AppStrings.dia,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
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
                    selectedColor: colorScheme.primary.withValues(alpha: 0.3),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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
          Text(
            AppStrings.bloque,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: filter.bloque,
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
    final colorScheme = Theme.of(context).colorScheme;
    final hours = List.generate(16, (i) => i + 6); // 6:00 a 21:00

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
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
