import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/home/salon_detail_page.dart';
import '../presentation/pages/profesores/profesores_page.dart';
import '../presentation/pages/profesores/profesor_detail_page.dart';
import '../presentation/pages/materias/materias_page.dart';
import '../presentation/pages/materias/materia_detail_page.dart';
import '../presentation/pages/materias/nrc_detail_page.dart';
import '../presentation/pages/materias/conjunto_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/widgets/custom_bottom_nav.dart';

/// Clave global para el navegador
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Configuracion del router de la app
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // Shell route para el bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        // Tab Materias
        GoRoute(
          path: '/materias',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MateriasPage()),
        ),
        // Tab Home (Disponibilidad)
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage()),
        ),
        // Tab Profesores
        GoRoute(
          path: '/profesores',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfesoresPage()),
        ),
      ],
    ),

    // Rutas de detalle (fuera del shell)
    GoRoute(
      path: '/salon/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final nombre = Uri.decodeComponent(state.pathParameters['nombre']!);
        return SalonDetailPage(salonNombre: nombre);
      },
    ),
    GoRoute(
      path: '/profesor/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final nombre = Uri.decodeComponent(state.pathParameters['nombre']!);
        return ProfesorDetailPage(profesorNombre: nombre);
      },
    ),
    GoRoute(
      path: '/materia/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final nombre = Uri.decodeComponent(state.pathParameters['nombre']!);
        return MateriaDetailPage(materiaNombre: nombre);
      },
    ),
    GoRoute(
      path: '/nrc/:nrc',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final nrc = int.parse(state.pathParameters['nrc']!);
        return NrcDetailPage(nrc: nrc);
      },
    ),
    GoRoute(
      path: '/conjunto/:codigo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final codigo = Uri.decodeComponent(state.pathParameters['codigo']!);
        return ConjuntoPage(codigoConjunto: codigo);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

/// Scaffold principal con bottom navigation
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/materias')) return 0;
    if (location.startsWith('/home')) return 1;
    if (location.startsWith('/profesores')) return 2;
    return 1; // Default home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/materias');
        break;
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/profesores');
        break;
    }
  }
}
