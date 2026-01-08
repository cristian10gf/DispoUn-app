import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/constants/strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas en espanol
  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: DispoUnApp()));
}

/// Aplicacion principal DispoUn
class DispoUnApp extends StatelessWidget {
  const DispoUnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
