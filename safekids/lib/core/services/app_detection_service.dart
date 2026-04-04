import 'package:flutter/services.dart';

class AppDetectionService {
  static const _channel = MethodChannel('com.safekids/apps');

  // Obtener apps instaladas en el dispositivo
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getInstalledApps');
      return result
          .map((app) => InstalledApp.fromMap(Map<String, dynamic>.from(app)))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Error obteniendo apps: ${e.message}');
    }
  }

  // Obtener estadísticas de uso
  static Future<List<AppUsageStat>> getAppUsageStats() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getAppUsageStats');
      return result
          .map((s) => AppUsageStat.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        throw PermissionException();
      }
      throw Exception('Error obteniendo estadísticas: ${e.message}');
    }
  }

  // Verificar si tiene permiso
  static Future<bool> hasUsagePermission() async {
    try {
      return await _channel.invokeMethod('hasUsagePermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  // Abrir configuración de permisos
  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      throw Exception('Error abriendo configuración: ${e.message}');
    }
  }
}

// Modelos
class InstalledApp {
  final String name;
  final String packageName;
  final String category;

  InstalledApp({
    required this.name,
    required this.packageName,
    required this.category,
  });

  factory InstalledApp.fromMap(Map<String, dynamic> map) {
    return InstalledApp(
      name: map['name'] ?? '',
      packageName: map['packageName'] ?? '',
      category: map['category'] ?? 'Otros',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'packageName': packageName,
        'category': category,
        'isBlocked': false,
      };
}

class AppUsageStat {
  final String packageName;
  final String name;
  final int minutesUsed;

  AppUsageStat({
    required this.packageName,
    required this.name,
    required this.minutesUsed,
  });

  factory AppUsageStat.fromMap(Map<String, dynamic> map) {
    return AppUsageStat(
      packageName: map['packageName'] ?? '',
      name: map['name'] ?? '',
      minutesUsed: (map['minutesUsed'] ?? 0).toInt(),
    );
  }
}

class PermissionException implements Exception {
  final String message = 'Se necesita permiso de acceso al uso de apps';
}