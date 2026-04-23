import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_detection_service.dart';

class BlockEnforcementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Iniciar listener — llamar al iniciar sesión como hijo
  void startListening() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // En el listener de appRules agregá después de updateBlockedApps:
    _firestore
        .collection('appRules')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final blocked = List<String>.from(snap.data()?['blockedApps'] ?? []);
      try {
        await AppDetectionService.updateBlockedApps(blocked);
        // Guardar localmente para modo offline
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('blocked_apps_local', blocked);
      } catch (e) {}
    });

    // En el listener de childProfiles agregá:
    _firestore
        .collection('childProfiles')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final isLocked = snap.data()?['isDeviceLocked'] ?? false;
      try {
        await AppDetectionService.setDeviceLocked(isLocked);
        // Guardar localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('device_locked_local', isLocked);
      } catch (e) {}
    });
  }

}