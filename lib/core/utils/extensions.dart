import '../constants/strings.dart';

/// Extensiones para String
extension StringExtensions on String {
  /// Convierte la primera letra a mayuscula
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Convierte cada palabra a mayuscula inicial
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Normaliza el nombre de un profesor (formato: "APELLIDO - NOMBRE")
  String normalizeProfesorName() {
    final parts = split(' - ');
    if (parts.length >= 2) {
      return '${parts[1].toTitleCase()} ${parts[0].toTitleCase()}';
    }
    return toTitleCase();
  }

  /// Obtiene el nombre completo del dia a partir de su codigo
  String toDiaCompleto() {
    return AppStrings.diasCompletos[this] ?? this;
  }

  /// Verifica si contiene otra cadena ignorando mayusculas/minusculas
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }
}

/// Extensiones para List
extension ListExtensions<T> on List<T> {
  /// Agrupa elementos por una clave
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      (map[key] ??= []).add(element);
    }
    return map;
  }

  /// Cuenta elementos por una clave
  Map<K, int> countBy<K>(K Function(T) keyFunction) {
    final map = <K, int>{};
    for (final element in this) {
      final key = keyFunction(element);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Obtiene los primeros N elementos o todos si hay menos
  List<T> takeFirst(int n) {
    return take(n).toList();
  }
}

/// Extensiones para Map
extension MapExtensions<K, V> on Map<K, V> {
  /// Ordena el mapa por valor (descendente)
  Map<K, V> sortByValueDescending(Comparable Function(V) getValue) {
    final entries = this.entries.toList()
      ..sort((a, b) => getValue(b.value).compareTo(getValue(a.value)));
    return Map.fromEntries(entries);
  }

  /// Ordena el mapa por valor (ascendente)
  Map<K, V> sortByValueAscending(Comparable Function(V) getValue) {
    final entries = this.entries.toList()
      ..sort((a, b) => getValue(a.value).compareTo(getValue(b.value)));
    return Map.fromEntries(entries);
  }
}

/// Extensiones para num
extension NumExtensions on num {
  /// Formatea el numero con decimales especificados
  String toFormattedString({int decimals = 1}) {
    if (this == toInt()) {
      return toInt().toString();
    }
    return toStringAsFixed(decimals);
  }
}
