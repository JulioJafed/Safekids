import 'package:flutter/services.dart';

class AppDetectionService {
  static const _channel = MethodChannel('com.safekids/apps');

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

  static Future<List<AppUsageStat>> getAppUsageStats() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getAppUsageStats');
      return result
          .map((s) => AppUsageStat.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') throw PermissionException();
      throw Exception('Error obteniendo estadísticas: ${e.message}');
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final result = await _channel.invokeMethod('hasUsagePermission');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }
  
  // Agregá estos métodos al final de la clase AppDetectionService
  static Future<void> updateBlockedApps(List<String> blockedApps) async {
    try {
      await _channel.invokeMethod('updateBlockedApps', {
        'blockedApps': blockedApps,
      });
    } on PlatformException catch (e) {
      throw Exception('Error actualizando apps bloqueadas: ${e.message}');
    }
  }

  static Future<void> setDeviceLocked(bool locked) async {
    try {
      await _channel.invokeMethod('setDeviceLocked', {
        'locked': locked,
      });
    } on PlatformException catch (e) {
      throw Exception('Error actualizando bloqueo: ${e.message}');
    }
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod('hasAccessibilityPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }


  static Future<bool> checkPendingAlert() async {
    try {
      return await _channel.invokeMethod('checkPendingAlerts') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> activateDeviceAdmin() async {
    try {
      await _channel.invokeMethod('activateDeviceAdmin');
    } on PlatformException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

  static Future<bool> isDeviceAdminActive() async {
    try {
      return await _channel.invokeMethod('isDeviceAdminActive') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> startFirestoreService() async {
  try {
    await _channel.invokeMethod('startFirestoreService');
  } on PlatformException {
    // Error silencioso
  }
  }

    static Future<void> saveChildUid(String uid) async {
  try {
    await _channel.invokeMethod('saveChildUid', {'uid': uid});
  } on PlatformException catch (e) {
    throw Exception('Error: ${e.message}');
  }
  }

  // Marca que el padre autorizó la desactivación de Device Admin por
  // [ttlMinutes] minutos. Debe llamarse justo después de verificar el
  // código con UninstallProtectionService.verifyCode().
  static Future<void> setUninstallAuthorized({int ttlMinutes = 5}) async {
    try {
      await _channel.invokeMethod('setUninstallAuthorized', {
        'ttlMinutes': ttlMinutes,
      });
    } on PlatformException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }

    static Future<bool> hasNetworkConnection() async {
    try {
      return await _channel.invokeMethod('hasNetworkConnection') ?? false;
    } on PlatformException {
      return false;
    }
  }

  // Permiso "Mostrar sobre otras apps" — necesario para que la pantalla
  // de bloqueo (overlay) se pueda dibujar encima de cualquier app.
  static Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod('hasOverlayPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } on PlatformException catch (e) {
      throw Exception('Error: ${e.message}');
    }
  }


}

class InstalledApp {
  final String name;
  final String packageName;
  final String category;

  InstalledApp({
    required this.name,
    required this.packageName,
    required this.category,
  });

  factory InstalledApp.fromMap(Map<String, dynamic> map) => InstalledApp(
        name: map['name'] ?? '',
        packageName: map['packageName'] ?? '',
        category: map['category'] ?? 'Otros',
      );

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

  factory AppUsageStat.fromMap(Map<String, dynamic> map) => AppUsageStat(
        packageName: map['packageName'] ?? '',
        name: map['name'] ?? '',
        minutesUsed: (map['minutesUsed'] ?? 0).toInt(),
      );
}

class PermissionException implements Exception {
  final String message = 'Se necesita permiso de acceso al uso de apps';
}
