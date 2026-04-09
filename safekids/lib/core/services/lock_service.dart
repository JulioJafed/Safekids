import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generar código de 6 dígitos
  String _generateUnlockCode() {
    final rnd = Random();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  // PADRE — Bloquear celular del hijo
  Future<LockResult> lockDevice(String childId) async {
    try {
      final code = _generateUnlockCode();
      await _firestore.collection('childProfiles').doc(childId).update({
        'isDeviceLocked': true,
        'unlockCode': code,
        'lockedAt': FieldValue.serverTimestamp(),
        'lockedBy': _auth.currentUser?.uid,
      });
      return LockResult.success(code: code);
    } catch (e) {
      return LockResult.error('Error al bloquear: $e');
    }
  }

  // PADRE — Desbloquear celular del hijo
  Future<LockResult> unlockDevice(String childId) async {
    try {
      await _firestore.collection('childProfiles').doc(childId).update({
        'isDeviceLocked': false,
        'unlockCode': '',
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      return LockResult.success(code: '');
    } catch (e) {
      return LockResult.error('Error al desbloquear: $e');
    }
  }

  // HIJO — Verificar código de desbloqueo
  Future<bool> verifyUnlockCode({
    required String childId,
    required String code,
  }) async {
    try {
      final doc = await _firestore
          .collection('childProfiles')
          .doc(childId)
          .get();
      if (!doc.exists) return false;
      final storedCode = doc.data()?['unlockCode'] ?? '';
      if (storedCode != code) return false;

      // Desbloquear automáticamente al verificar
      await _firestore.collection('childProfiles').doc(childId).update({
        'isDeviceLocked': false,
        'unlockCode': '',
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Stream del estado de bloqueo del hijo
  Stream<Map<String, dynamic>?> watchLockStatus(String childId) {
    return _firestore
        .collection('childProfiles')
        .doc(childId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }
}

class LockResult {
  final bool isSuccess;
  final String code;
  final String? errorMessage;

  LockResult._({
    required this.isSuccess,
    this.code = '',
    this.errorMessage,
  });

  factory LockResult.success({required String code}) =>
      LockResult._(isSuccess: true, code: code);

  factory LockResult.error(String message) =>
      LockResult._(isSuccess: false, errorMessage: message);
}