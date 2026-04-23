  import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_detection_service.dart';
import 'time_tracking_service.dart';
import 'block_enforcement_service.dart';

class PersistentService {
  static final PersistentService instance = PersistentService._();
  PersistentService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Inicializar al arrancar la app
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';

    if (role == 'child') {
      await _initializeChildServices();
    }
  }

  // Guardar sesión localmente
  Future<void> saveSession({
    required String uid,
    required String role,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
    await prefs.setBool('is_logged_in', true);
  }

  // Limpiar sesión
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);
  }

  // Verificar si hay sesión guardada
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<String> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? '';
  }

  // Inicializar servicios del hijo
  Future<void> _initializeChildServices() async {
    // Iniciar tracking de tiempo
    await TimeTrackingService.instance.checkDailyReset();
    TimeTrackingService.instance.startTracking();

    // Iniciar listener de bloqueos
    BlockEnforcementService().startListening();

    // Aplicar reglas guardadas localmente (para modo sin internet)
    await _applyLocalRules();
  }

  // Guardar reglas localmente para modo offline
  Future<void> saveRulesLocally({
    required List<String> blockedApps,
    required bool isDeviceLocked,
    required int dailyLimitMinutes,
    required bool autoBlock,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_apps_local', blockedApps);
    await prefs.setBool('device_locked_local', isDeviceLocked);
    await prefs.setInt('daily_limit_local', dailyLimitMinutes);
    await prefs.setBool('auto_block_local', autoBlock);
  }

  // Aplicar reglas guardadas localmente
  Future<void> _applyLocalRules() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedApps = prefs.getStringList('blocked_apps_local') ?? [];
    final isLocked = prefs.getBool('device_locked_local') ?? false;

    try {
      await AppDetectionService.updateBlockedApps(blockedApps);
      await AppDetectionService.setDeviceLocked(isLocked);
    } catch (e) {
      // Error silencioso
    }
  }

  // Verificar alertas pendientes de desactivación
  Future<bool> checkPendingDisableAlert() async {
    try {
      final result = await AppDetectionService.checkPendingAlert();
      return result;
    } catch (e) {
      return false;
    }
  }
}