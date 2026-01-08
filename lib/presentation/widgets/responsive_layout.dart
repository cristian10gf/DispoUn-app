import 'package:flutter/material.dart';

/// Breakpoints para diseño responsive
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Widget helper para layouts responsive
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.mobile &&
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= Breakpoints.tablet && desktop != null) {
      return desktop!;
    }

    if (screenWidth >= Breakpoints.mobile && tablet != null) {
      return tablet!;
    }

    return mobile;
  }
}

/// Builder para layouts que dependen de la orientacion
class OrientationLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, Orientation) builder;

  const OrientationLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => builder(context, orientation),
    );
  }
}

/// Extension para obtener padding responsive
extension ResponsivePadding on BuildContext {
  EdgeInsets get horizontalPadding {
    final width = MediaQuery.of(this).size.width;
    if (width >= Breakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    if (width >= Breakpoints.mobile) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  double get gridCrossAxisCount {
    final width = MediaQuery.of(this).size.width;
    if (width >= Breakpoints.desktop) return 4;
    if (width >= Breakpoints.tablet) return 3;
    if (width >= Breakpoints.mobile) return 2;
    return 2;
  }
}

