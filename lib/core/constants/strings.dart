/// Strings de la aplicacion en espanol
class AppStrings {
  AppStrings._();

  // General
  static const String appName = 'DispoUn';
  static const String appTitle = 'Disponibilidad Uninorte';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String retry = 'Reintentar';
  static const String cancel = 'Cancelar';
  static const String accept = 'Aceptar';
  static const String save = 'Guardar';
  static const String search = 'Buscar';
  static const String noResults = 'Sin resultados';
  static const String noData = 'No hay datos disponibles';

  // Navegacion
  static const String materias = 'Materias';
  static const String disponibilidad = 'Disponibilidad';
  static const String profesores = 'Profesores';
  static const String ajustes = 'Ajustes';

  // Dias de la semana
  static const String lunes = 'Lunes';
  static const String martes = 'Martes';
  static const String miercoles = 'Miercoles';
  static const String jueves = 'Jueves';
  static const String viernes = 'Viernes';
  static const String sabado = 'Sabado';
  static const String domingo = 'Domingo';

  static const Map<String, String> diasCompletos = {
    'L': lunes,
    'M': martes,
    'X': miercoles, // X representa miercoles en los datos
    'J': jueves,
    'V': viernes,
    'S': sabado,
    'D': domingo,
  };

  static const List<String> diasOrden = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  // Filtros de disponibilidad
  static const String filtros = 'Filtros';
  static const String horaInicio = 'Hora inicio';
  static const String horaFin = 'Hora fin';
  static const String dia = 'Dia';
  static const String fecha = 'Fecha';
  static const String bloque = 'Bloque';
  static const String salon = 'Salon';
  static const String todosLosBloques = 'Todos los bloques';
  static const String todosLosSalones = 'Todos los salones';
  static const String incluirNoDisponibles = 'Incluir no disponibles';
  static const String aplicarFiltros = 'Aplicar filtros';
  static const String limpiarFiltros = 'Limpiar filtros';

  // Estadisticas
  static const String estadisticas = 'Estadisticas';
  static const String clases = 'Clases';
  static const String horasSemana = 'Horas/Semana';
  static const String nrcs = 'NRCs';
  static const String cupos = 'Cupos';
  static const String matriculados = 'Matriculados';
  static const String grupo = 'Grupo';
  static const String clasesUnicas = 'Clases unicas';
  static const String porBloque = 'Por bloque';
  static const String porDia = 'Por dia';

  // Profesores
  static const String buscarProfesor = 'Buscar profesor...';
  static const String profesor = 'Profesor';
  static const String topProfesores = 'Profesores destacados';
  static const String seleccionarProfesor = 'Seleccionar profesor';
  static const String horarioProfesor = 'Horario del profesor';
  static const String sinProfesor = 'Sin profesor asignado';

  // Materias
  static const String buscarMateria = 'Buscar materia...';
  static const String materia = 'Materia';
  static const String topMaterias = 'Materias destacadas';
  static const String seleccionarMateria = 'Seleccionar materia';
  static const String horarioMateria = 'Horario de la materia';
  static const String codigoConjunto = 'Codigo conjunto';
  static const String departamento = 'Departamento';
  static const String nivel = 'Nivel';
  static const String modalidad = 'Modalidad';
  static const String horarioConjunto = 'Horario conjunto';
  static const String verPorConjunto = 'Ver por codigo de conjunto';
  static const String consultarNrc = 'Consultar NRC';

  // Salones
  static const String salonesDisponibles = 'Salones disponibles';
  static const String salonOcupado = 'Ocupado';
  static const String salonDisponible = 'Disponible';
  static const String horarioSalon = 'Horario del salon';
  static const String piso = 'Piso';

  // Ajustes
  static const String archivosJson = 'Archivos JSON';
  static const String archivoActivo = 'Archivo activo';
  static const String cargarArchivo = 'Cargar archivo';
  static const String seleccionarArchivo = 'Seleccionar archivo JSON';
  static const String archivoInvalido = 'El archivo no tiene un formato valido';
  static const String archivoCargado = 'Archivo cargado correctamente';
  static const String eliminarArchivo = 'Eliminar archivo';
  static const String confirmarEliminar =
      'Esta seguro de eliminar este archivo?';

  // Horario
  static const String horario = 'Horario';
  static const String horarioSemanal = 'Horario semanal';
  static const String sinHorario = 'Sin horario disponible';

  // NRC
  static const String nrc = 'NRC';
  static const String detalleNrc = 'Detalle del NRC';
  static const String ingresarNrc = 'Ingrese el NRC';
  static const String nrcNoEncontrado = 'NRC no encontrado';
}
