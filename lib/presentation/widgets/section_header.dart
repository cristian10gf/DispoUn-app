import 'package:flutter/material.dart';

/// Header de seccion reutilizable
class SectionHeader extends StatelessWidget {
  /// Texto del titulo
  final String title;

  /// Accion opcional a la derecha
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall;

    if (trailing != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: textStyle),
          trailing!,
        ],
      );
    }

    return Text(title, style: textStyle);
  }
}
