import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/app_detection_service.dart';

class AppSyncRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Sincronizar apps instaladas del hijo con Firestore
  Future<SyncResult> syncInstalledApps() async {
    final uid = _uid;
    if (uid == null) return SyncResult.error('No autenticado');

    try {
      final apps = await AppDetectionService.getInstalledApps();

      // Guardar en Firestore
      await _firestore.collection('installedApps').doc(uid).set({
        'childId': uid,
        'apps': apps.map((a) => a.toMap()).toList(),
        'lastSync': FieldValue.serverTimestamp(),
        'totalApps': apps.length,
      });

      return SyncResult.success(appsCount: apps.length);
    } catch (e) {
      return SyncResult.error('Error al sincronizar: $e');
    }
  }

  // Sincronizar estadísticas de uso
  Future<void> syncUsageStats() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final hasPermission = await AppDetectionService.hasUsagePermission();
      if (!hasPermission) return;

      final stats = await AppDetectionService.getAppUsageStats();

      final batch = _firestore.batch();

      // Actualizar minutos usados hoy en screenTimeRules
      final totalMinutes = stats.fold<int>(
          0, (sum, stat) => sum + stat.minutesUsed);

      batch.update(
        _firestore.collection('screenTimeRules').doc(uid),
        {
          'usedTodayMinutes': totalMinutes,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      );

      // Guardar estadísticas por app
      batch.set(
        _firestore.collection('appUsageStats').doc(uid),
        {
          'childId': uid,
          'stats': stats.map((s) => {
                'packageName': s.packageName,
                'name': s.name,
                'minutesUsed': s.minutesUsed,
              }).toList(),
          'date': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (e) {
      // Error silencioso en sync de estadísticas
    }
  }

  // El padre lee las apps del hijo desde Firestore
  Stream<List<Map<String, dynamic>>> watchChildApps(String childId) {
    return _firestore
        .collection('installedApps')
        .doc(childId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return <Map<String, dynamic>>[];
      final data = snap.data()!;
      return List<Map<String, dynamic>>.from(data['apps'] ?? []);
    });
  }

  // El padre actualiza apps bloqueadas
  Future<void> updateBlockedApps({
    required String childId,
    required List<String> blockedPackages,
  }) async {
    final parentId = _uid;
    if (parentId == null) return;

    await _firestore.collection('appRules').doc(childId).set({
      'childId': childId,
      'blockedApps': blockedPackages,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': parentId,
    }, SetOptions(merge: true));
  }
}

class SyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final int appsCount;

  SyncResult._({
    required this.isSuccess,
    this.errorMessage,
    this.appsCount = 0,
  });

  factory SyncResult.success({required int appsCount}) =>
      SyncResult._(isSuccess: true, appsCount: appsCount);

  factory SyncResult.error(String message) =>
      SyncResult._(isSuccess: false, errorMessage: message);
}
