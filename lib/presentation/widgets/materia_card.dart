import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/horario.dart';

/// Card que muestra informacion de una materia/horario
class MateriaCard extends StatelessWidget {
  final Horario horario;
  final VoidCallback? onTap;
  final bool showSalon;
  final bool showProfesor;
  final bool compact;

  const MateriaCard({
    super.key,
    required this.horario,
    this.onTap,
    this.showSalon = true,
    this.showProfesor = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getColorForString(horario.nombreMateria);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nombre de la materia
            Text(
              horario.nombreMateria,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 4 : 8),

            // NRC y codigo
            Row(
              children: [
                _buildChip('NRC ${horario.nrc}', color),
                const SizedBox(width: 6),
                _buildChip(horario.codigoConjunto, AppColors.textTertiary),
              ],
            ),

            if (showProfesor && !compact) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      horario.profesor.normalizeProfesorName(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (showSalon && !compact) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${horario.nombreSalon} - ${horario.nombreBloque}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            // Cupos
            SizedBox(height: compact ? 4 : 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCuposColor(horario.cupos).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${horario.matriculados + horario.cupos} ${AppStrings.cupos}',
                style: TextStyle(
                  color: _getCuposColor(horario.cupos),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCuposColor(int cupos) {
    if (cupos > 20) return AppColors.success;
    if (cupos > 5) return AppColors.warning;
    return AppColors.error;
  }
}

/// Card compacta para mostrar en el horario grid
class MateriaCardCompact extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const MateriaCardCompact({
    super.key,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Lista de cards de materias
class MateriaCardList extends StatelessWidget {
  final List<Horario> horarios;
  final Function(Horario)? onTap;
  final bool horizontal;

  const MateriaCardList({
    super.key,
    required this.horarios,
    this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: horarios.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final horario = horarios[index];
            return SizedBox(
              width: 200,
              child: MateriaCard(
                horario: horario,
                onTap: onTap != null ? () => onTap!(horario) : null,
              ),
            );
          },
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: horarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final horario = horarios[index];
        return MateriaCard(
          horario: horario,
          onTap: onTap != null ? () => onTap!(horario) : null,
        );
      },
    );
  }
}

