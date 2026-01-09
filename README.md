# DispoUn

Aplicacion movil desarrollada en Flutter para consultar la disponibilidad de salones, horarios de profesores y materias de la Universidad del Norte (Uninorte).

## Descripcion

DispoUn permite a los estudiantes y docentes de Uninorte consultar de manera rapida y eficiente:

- **Disponibilidad de salones**: Filtra por hora, dia, bloque y salon para encontrar espacios disponibles
- **Horarios de profesores**: Busca profesores y visualiza su horario semanal completo
- **Informacion de materias**: Consulta materias, NRCs y horarios de conjuntos de materias
- **Estadisticas**: Visualiza estadisticas de ocupacion por bloques, dias y mas

## Capturas de Pantalla

<!-- Agregar capturas de pantalla de la app aqui -->

## Caracteristicas

### Pagina Principal (Disponibilidad)
- Consulta de disponibilidad de salones con filtros avanzados
- Filtros por: hora inicio, hora fin, dia de la semana, fecha, bloque y salon
- Vista detallada del horario semanal de cada salon
- Estadisticas generales de ocupacion

### Pagina de Profesores
- Busqueda de profesores por nombre parcial
- Ranking de profesores con mas horarios, NRCs y materias
- Vista detallada con horario semanal completo del profesor
- Estadisticas individuales (clases, materias, horas/semana, NRCs)

### Pagina de Materias
- Busqueda de materias por nombre
- Estadisticas generales de materias
- Vista de horarios por conjunto de materias (BIO, IST, etc.)
- Consulta de informacion detallada por NRC
- Visualizacion de horarios combinados de multiples materias

### Configuracion
- Gestion de archivos JSON de datos
- Carga de nuevos archivos con datos de horarios

## Requisitos

- Flutter SDK >= 3.9.0
- Dart SDK >= 3.9.0
- Android SDK (para compilacion Android)
- Xcode (para compilacion iOS, solo en macOS)

## Instalacion

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/dispoun-app.git
cd dispoun-app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Generar codigo (modelos freezed)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Ejecutar la aplicacion

```bash
flutter run
```

## Uso del Makefile

El proyecto incluye un Makefile para facilitar las tareas comunes de desarrollo:

```bash
# Ver todos los comandos disponibles
make help

# Instalar dependencias
make deps

# Ejecutar en modo debug
make run

# Compilar APK de release
make apk

# Limpiar y reconstruir
make clean build
```

Consulta la seccion [Comandos del Makefile](#comandos-del-makefile) para mas detalles.

## Estructura del Proyecto

```
lib/
├── app/                    # Configuracion de la app
│   ├── router.dart         # Configuracion de rutas (go_router)
│   └── theme.dart          # Tema visual de la app
├── core/                   # Utilidades y constantes
│   ├── constants/          # Colores, strings
│   └── utils/              # Extensiones y utilidades
├── data/                   # Capa de datos
│   ├── models/             # Modelos de datos (freezed)
│   ├── repositories/       # Repositorios
│   └── services/           # Servicios (storage, parser)
├── domain/                 # Logica de negocio
│   ├── entities/           # Entidades de dominio
│   └── providers/          # Providers de Riverpod
└── presentation/           # Capa de presentacion
    ├── pages/              # Paginas de la app
    │   ├── home/           # Disponibilidad de salones
    │   ├── materias/       # Gestion de materias
    │   ├── profesores/     # Gestion de profesores
    │   ├── search/         # Busqueda global
    │   ├── settings/       # Configuracion
    │   └── splash/         # Pantalla de carga
    └── widgets/            # Widgets reutilizables
```

## Comandos del Makefile

| Comando | Descripcion |
|---------|-------------|
| `make help` | Muestra la ayuda con todos los comandos |
| `make deps` | Instala las dependencias del proyecto |
| `make generate` | Genera codigo con build_runner (modelos freezed) |
| `make watch` | Genera codigo en modo watch (desarrollo) |
| `make run` | Ejecuta la app en modo debug |
| `make run-release` | Ejecuta la app en modo release |
| `make run-profile` | Ejecuta la app en modo profile |
| `make build` | Compila APK de debug |
| `make apk` | Compila APK de release |
| `make apk-split` | Compila APKs separados por ABI |
| `make appbundle` | Compila App Bundle para Play Store |
| `make ios` | Compila para iOS (solo macOS) |
| `make clean` | Limpia archivos de build |
| `make clean-all` | Limpia todo incluyendo codigo generado |
| `make test` | Ejecuta los tests |
| `make analyze` | Analiza el codigo con el linter |
| `make format` | Formatea el codigo |
| `make icons` | Genera iconos de la app |
| `make doctor` | Verifica la instalacion de Flutter |
| `make devices` | Lista dispositivos conectados |
| `make upgrade` | Actualiza dependencias |

## Dependencias Principales

| Paquete | Uso |
|---------|-----|
| `flutter_riverpod` | Gestion de estado reactivo |
| `go_router` | Navegacion declarativa |
| `freezed` | Modelos inmutables con generacion de codigo |
| `json_serializable` | Serializacion/deserializacion JSON |
| `path_provider` | Acceso al sistema de archivos |
| `file_picker` | Seleccion de archivos |
| `intl` | Formateo de fechas y numeros |
| `shimmer` | Efectos de carga |

## Formato de Datos

La aplicacion consume archivos JSON con la siguiente estructura por cada registro de horario:

```json
{
  "codigo_conjunto": "IST",
  "id_materia": 12345,
  "nombre_materia": "Programacion I",
  "departamento": "Ingenieria de Sistemas",
  "nivel": "Pregrado",
  "nrc": 54321,
  "grupo": 1,
  "matriculados": 25,
  "cupos": 5,
  "modalidad": "Presencial",
  "nombre_bloque": "Bloque K",
  "nombre_salon": "K-201",
  "piso": "2",
  "profesor": "Juan Perez",
  "dia": "L",
  "hora_inicio": "07:00",
  "hora_fin": "09:00",
  "fecha_inicio": "2024-01-15",
  "fecha_fin": "2024-05-15",
  "active": true
}
```

## Desarrollo

### Generar codigo despues de modificar modelos

```bash
make generate
```

### Ejecutar en modo desarrollo con hot reload

```bash
make run
```

### Compilar APK para distribucion

```bash
make apk
```

El APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

## Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## Licencia

Este proyecto es de uso academico para la comunidad de la Universidad del Norte.

## Contacto

Para reportar bugs o sugerir mejoras, crear un issue en el repositorio.
