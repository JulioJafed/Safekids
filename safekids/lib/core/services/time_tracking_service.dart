import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_detection_service.dart';

class TimeTrackingService {
  static const _channel = MethodChannel('com.safekids/apps');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static TimeTrackingService? _instance;
  static TimeTrackingService get instance {
    _instance ??= TimeTrackingService._();
    return _instance!;
  }
  TimeTrackingService._();

  bool _isTracking = false;

  // Iniciar seguimiento de tiempo
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    // Escuchar eventos del nativo cada minuto
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onMinutePassed') {
        await _addOneMinute();
      }
    });

    try {
      _channel.invokeMethod('startTimeTracking');
    } catch (e) {
      // Error silencioso
    }
  }

  // Detener seguimiento
  void stopTracking() {
    _isTracking = false;
    try {
      _channel.invokeMethod('stopTimeTracking');
    } catch (e) {
      // Error silencioso
    }
  }

  // Agregar 1 minuto al contador en Firestore
  Future<void> _addOneMinute() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore
          .collection('screenTimeRules')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final used = (data['usedTodayMinutes'] ?? 0) as int;
      final limit = (data['dailyLimitMinutes'] ?? 120) as int;
      final autoBlock = data['autoBlock'] ?? true;
      final isActive = data['isActive'] ?? true;

      if (!isActive) return;

      final newUsed = used + 1;

      await _firestore
          .collection('screenTimeRules')
          .doc(uid)
          .update({
        'usedTodayMinutes': newUsed,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Si llegó al límite y tiene autoblock
      if (autoBlock && newUsed >= limit) {
        await _blockDeviceByTime(uid);
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Bloquear dispositivo por tiempo agotado
  Future<void> _blockDeviceByTime(String uid) async {
    try {
      // 1. Actualizar Firestore
      await _firestore
          .collection('childProfiles')
          .doc(uid)
          .update({
        'isDeviceLocked': true,
        'unlockCode': '',
        'lockedReason': 'time_limit',
        'lockedAt': FieldValue.serverTimestamp(),
      });

      // 2. Aplicar bloqueo INMEDIATO via canal nativo
      await AppDetectionService.setDeviceLocked(true);

      // 3. Guardar localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('device_locked_local', true);
    } catch (e) {
      // Si falla Firestore, aplicar igual localmente
      try {
        await AppDetectionService.setDeviceLocked(true);
      } catch (_) {}
    }
  }

  // Reset diario — llamar cada día a medianoche
  Future<void> resetDailyTime() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('screenTimeRules')
          .doc(uid)
          .update({
        'usedTodayMinutes': 0,
        'lastReset': FieldValue.serverTimestamp(),
      });

      // Desbloquear si estaba bloqueado por tiempo
      final profile = await _firestore
          .collection('childProfiles')
          .doc(uid)
          .get();

      if (profile.exists &&
          profile.data()?['lockedReason'] == 'time_limit') {
        await _firestore
            .collection('childProfiles')
            .doc(uid)
            .update({
          'isDeviceLocked': false,
          'unlockCode': '',
          'lockedReason': null,
        });
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Verificar si toca hacer reset diario
  Future<void> checkDailyReset() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore
          .collection('screenTimeRules')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final lastReset = doc.data()?['lastReset'] as Timestamp?;
      if (lastReset == null) {
        await resetDailyTime();
        return;
      }

      final lastResetDate = lastReset.toDate();
      final now = DateTime.now();

      // Si el último reset fue ayer o antes → resetear
      if (lastResetDate.day != now.day ||
          lastResetDate.month != now.month ||
          lastResetDate.year != now.year) {
        await resetDailyTime();
      }
    } catch (e) {
      // Error silencioso
    }
  }
}