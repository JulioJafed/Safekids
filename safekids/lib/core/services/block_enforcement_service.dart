import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_detection_service.dart';

class BlockEnforcementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Iniciar listener — llamar al iniciar sesión como hijo
  void startListening() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Escuchar cambios en apps bloqueadas
    _firestore
        .collection('appRules')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final blocked = List<String>.from(snap.data()?['blockedApps'] ?? []);
      try {
        await AppDetectionService.updateBlockedApps(blocked);
      } catch (e) {
        // Error silencioso
      }
    });

    // Escuchar estado de bloqueo del dispositivo
    _firestore
        .collection('childProfiles')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      if (!snap.exists) return;
      final isLocked = snap.data()?['isDeviceLocked'] ?? false;
      try {
        await AppDetectionService.setDeviceLocked(isLocked);
      } catch (e) {
        // Error silencioso
      }
    });
  }
}