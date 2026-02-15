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
import '../presentation/pages/search/global_search_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/widgets/custom_bottom_nav.dart';

/// Clave global para el navegador
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Configuracion del router de la app
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash screen
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
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
    // Nota: GoRouter decodifica automaticamente los pathParameters,
    // por lo que no necesitamos usar Uri.decodeComponent
    GoRoute(
      path: '/salon/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final nombre = state.pathParameters['nombre']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: SalonDetailPage(salonNombre: nombre),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/profesor/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final nombre = state.pathParameters['nombre']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProfesorDetailPage(profesorNombre: nombre),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/materia/:nombre',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final nombre = state.pathParameters['nombre']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: MateriaDetailPage(materiaNombre: nombre),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/nrc/:nrc',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final nrc = int.parse(state.pathParameters['nrc']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: NrcDetailPage(nrc: nrc),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/conjunto/:codigo',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final codigo = state.pathParameters['codigo']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ConjuntoPage(codigoConjunto: codigo),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GlobalSearchPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
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
