import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para manejo de archivos JSON en almacenamiento local
class FileStorageService {
  FileStorageService._();

  static const String _jsonFolderName = 'horarios_json';

  /// Obtiene el directorio de almacenamiento de archivos JSON
  static Future<Directory> _getJsonDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final jsonDir = Directory('${appDir.path}/$_jsonFolderName');
    if (!await jsonDir.exists()) {
      await jsonDir.create(recursive: true);
    }
    return jsonDir;
  }

  /// Lista todos los archivos JSON guardados
  static Future<List<FileInfo>> listJsonFiles() async {
    final dir = await _getJsonDirectory();
    final files = <FileInfo>[];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final stat = await entity.stat();
        files.add(
          FileInfo(
            name: entity.path.split('/').last,
            path: entity.path,
            size: stat.size,
            modified: stat.modified,
          ),
        );
      }
    }

    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  /// Lee el contenido de un archivo JSON
  static Future<String?> readJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      // Error al leer archivo
    }
    return null;
  }

  /// Guarda un archivo JSON en el almacenamiento local
  static Future<String?> saveJsonFile(String content, String fileName) async {
    try {
      final dir = await _getJsonDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Importa un archivo JSON usando el selector de archivos
  static Future<ImportResult?> importJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final pickedFile = result.files.first;
      String? content;
      String fileName;

      if (pickedFile.bytes != null) {
        // Web o cuando el archivo se lee en memoria
        content = String.fromCharCodes(pickedFile.bytes!);
        fileName = pickedFile.name;
      } else if (pickedFile.path != null) {
        // Mobile/Desktop con acceso al path
        final file = File(pickedFile.path!);
        content = await file.readAsString();
        fileName = pickedFile.name;
      } else {
        return null;
      }

      // Guardar en el directorio de la app
      final savedPath = await saveJsonFile(content, fileName);
      if (savedPath == null) {
        return null;
      }

      return ImportResult(
        filePath: savedPath,
        fileName: fileName,
        content: content,
      );
    } catch (e) {
      return null;
    }
  }

  /// Elimina un archivo JSON
  static Future<bool> deleteJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      // Error al eliminar
    }
    return false;
  }

  /// Copia el archivo de assets al almacenamiento local si no existe
  static Future<String?> copyAssetToStorage(
    String assetContent,
    String fileName,
  ) async {
    final dir = await _getJsonDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    if (!await file.exists()) {
      await file.writeAsString(assetContent);
    }

    return filePath;
  }

  /// Obtiene el path del archivo activo guardado en preferencias
  static Future<String?> getActiveFilePath() async {
    final files = await listJsonFiles();
    if (files.isNotEmpty) {
      return files.first.path;
    }
    return null;
  }
}

/// Informacion de un archivo JSON
class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modified;

  const FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Resultado de importar un archivo
class ImportResult {
  final String filePath;
  final String fileName;
  final String content;

  const ImportResult({
    required this.filePath,
    required this.fileName,
    required this.content,
  });
}
