import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final childScreenTimeProvider =
    StreamProvider.family<Map<String, dynamic>?, String>(
  (ref, childId) {
    return FirebaseFirestore.instance
        .collection('screenTimeRules')
        .doc(childId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  },
);

class ScreenTimeRepository {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> updateDailyLimit({
    required String childId,
    required int limitMinutes,
    required bool autoBlock,
    required bool isActive,
  }) async {
    await _firestore
        .collection('screenTimeRules')
        .doc(childId)
        .update({
      'dailyLimitMinutes': limitMinutes,
      'autoBlock': autoBlock,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });
  }

  static Future<void> resetChildTime(String childId) async {
    await _firestore
        .collection('screenTimeRules')
        .doc(childId)
        .update({
      'usedTodayMinutes': 0,
      'lastReset': FieldValue.serverTimestamp(),
    });
  }
}