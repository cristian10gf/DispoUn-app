import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Card para mostrar una estadistica individual
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor ?? AppColors.primaryRed),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

/// Grid de estadisticas
class StatsGrid extends StatelessWidget {
  final List<StatCard> stats;
  final int crossAxisCount;
  final double spacing;

  const StatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }
}

/// Card horizontal con varias estadisticas
class StatsRow extends StatelessWidget {
  final List<StatItem> items;

  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => _buildStatItem(item)).toList(),
      ),
    );
  }

  Widget _buildStatItem(StatItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

/// Item individual de estadistica
class StatItem {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});
}

/// Card de estadisticas con grafico de barras horizontal
class StatsBarChart extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Color barColor;
  final int maxItems;

  const StatsBarChart({
    super.key,
    required this.title,
    required this.data,
    this.barColor = AppColors.primaryRed,
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayEntries = sortedEntries.take(maxItems).toList();
    final maxValue = displayEntries.first.value.toDouble();

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...displayEntries.map((entry) => _buildBar(entry, maxValue)),
        ],
      ),
    );
  }

  Widget _buildBar(MapEntry<String, int> entry, double maxValue) {
    final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                entry.value.toString(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

