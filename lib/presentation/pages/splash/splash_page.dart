import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../domain/providers/data_provider.dart';

/// Página de splash con logo y loader animado
/// El tiempo de visualización depende de cuánto tarden los datos en cargar
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasNavigated = false;
  bool _minimumTimeElapsed = false;

  /// Tiempo mínimo de visualización del splash (para que las animaciones se vean)
  static const _minimumSplashDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Iniciar timer para tiempo mínimo de splash
    Future.delayed(_minimumSplashDuration, () {
      if (mounted) {
        setState(() => _minimumTimeElapsed = true);
        _tryNavigate();
      }
    });
  }

  /// Intenta navegar a home si los datos están listos y el tiempo mínimo ha pasado
  void _tryNavigate() {
    if (_hasNavigated) return;

    final dataState = ref.read(dataNotifierProvider);

    // Navegar solo si:
    // 1. El tiempo mínimo ha pasado
    // 2. Los datos terminaron de cargar (exitoso o con error)
    if (_minimumTimeElapsed && !dataState.isLoading) {
      _hasNavigated = true;
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Observar el estado de carga de datos
    final dataState = ref.watch(dataNotifierProvider);

    // Intentar navegar cada vez que el estado cambie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate();
    });

    // Determinar el texto de estado
    String statusText = 'Cargando datos...';
    if (dataState.error != null) {
      statusText = 'Iniciando...';
    } else if (!dataState.isLoading && dataState.repository != null) {
      statusText = '¡Listo!';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Loader personalizado con colores de la app
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(opacity: _fadeAnimation.value, child: child);
              },
              child: const _CustomLoader(),
            ),

            const SizedBox(height: 24),

            // Texto de carga dinámico
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(opacity: _fadeAnimation.value, child: child);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loader personalizado con los colores de la app
class _CustomLoader extends StatefulWidget {
  const _CustomLoader();

  @override
  State<_CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<_CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoaderPainter(
              progress: _controller.value,
              primaryColor: AppColors.primaryRed,
              secondaryColor: AppColors.primaryRedLight,
              accentColor: AppColors.accentCoral,
            ),
          );
        },
      ),
    );
  }
}

/// Painter para el loader personalizado
class _LoaderPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  _LoaderPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Fondo del círculo
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Arco animado principal
    final primaryPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [primaryColor, secondaryColor, accentColor, primaryColor],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 1.5 + 0.5 * math.sin(progress * math.pi * 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * math.pi * 2,
      sweepAngle,
      false,
      primaryPaint,
    );

    // Puntos decorativos
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      final angle = progress * math.pi * 2 + i * (math.pi * 2 / 3);
      final dotRadius = 3.0 - i * 0.5;
      final dotCenter = Offset(
        center.dx + (radius + 8) * math.cos(angle),
        center.dy + (radius + 8) * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
