import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // Stream del perfil del hijo en tiempo real
  Stream<Map<String, dynamic>?> watchChildProfile() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('childProfiles')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // Stream de las reglas de tiempo del hijo
  Stream<Map<String, dynamic>?> watchScreenTimeRules() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('screenTimeRules')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // Stream de las apps bloqueadas
  Stream<List<String>> watchBlockedApps() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('appRules')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data()!;
      return List<String>.from(data['blockedApps'] ?? []);
    });
  }

  // Stream del usuario base
  Stream<Map<String, dynamic>?> watchUserData() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // Actualizar estado online del hijo
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      await _firestore.collection('childProfiles').doc(uid).update({
        'deviceStatus': isOnline ? 'online' : 'offline',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Si no existe el documento aún, ignorar
    }
  }
}