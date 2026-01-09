import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../domain/providers/data_provider.dart';
import '../../../domain/providers/mi_horario_provider.dart';
import 'widgets/availability_filters.dart';
import 'widgets/availability_table.dart';
import 'widgets/mi_horario_section.dart';
import 'widgets/stats_section.dart';

/// Pagina principal - Disponibilidad de salones y Mi Horario
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Verificar si debemos iniciar en Mi Horario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialTab();
    });
  }

  void _checkInitialTab() {
    final miHorarioState = ref.read(miHorarioNotifierProvider);
    if (miHorarioState.esPantallaPrincipal && miHorarioState.tieneNrcs) {
      _tabController.animateTo(0);
    } else {
      // Default a Salones disponibles
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataState = ref.watch(dataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.disponibilidad),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_month_outlined),
              text: AppStrings.miHorario,
            ),
            Tab(
              icon: Icon(Icons.room_outlined),
              text: AppStrings.salonesDisponibles,
            ),
            Tab(
              icon: Icon(Icons.bar_chart_outlined),
              text: AppStrings.estadisticas,
            ),
          ],
        ),
      ),
      body: _buildBody(dataState),
    );
  }

  Widget _buildBody(DataState dataState) {
    if (dataState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dataState.error != null) {
      return _buildError(dataState.error!);
    }

    if (dataState.repository == null) {
      return _buildNoData();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        const MiHorarioSection(),
        _buildDisponibilidadTab(),
        const StatsSection(),
      ],
    );
  }

  Widget _buildDisponibilidadTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Filtros (colapsables)
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text(
              AppStrings.filtros,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: const Icon(Icons.filter_list, color: AppColors.primaryRed),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AvailabilityFilters(),
              ),
              SizedBox(height: 16),
            ],
          ),
          const Divider(),
          // Tabla de resultados (sin Expanded, genera los items directamente)
          AvailabilityTable(
            onSalonTap: (salon) => context.push('/salon/$salon'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(dataNotifierProvider.notifier).initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noData,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.upload_file),
              label: const Text(AppStrings.cargarArchivo),
            ),
          ],
        ),
      ),
    );
  }
}
