import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final parentChildrenIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('parentProfiles')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String>[];
    return List<String>.from(snap.data()?['linkedChildren'] ?? []);
  });
});

final selectedChildIdProvider = StateProvider<String?>((ref) => null);

final childInstalledAppsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
  return FirebaseFirestore.instance
      .collection('installedApps')
      .doc(childId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <Map<String, dynamic>>[];
    return List<Map<String, dynamic>>.from(snap.data()?['apps'] ?? []);
  });
});

final childBlockedAppsProvider =
    StreamProvider.family<List<String>, String>((ref, childId) {
  return FirebaseFirestore.instance
      .collection('appRules')
      .doc(childId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return <String>[];
    return List<String>.from(snap.data()?['blockedApps'] ?? []);
  });
});

final childProfileDataProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, childId) {
  return FirebaseFirestore.instance
      .collection('childProfiles')
      .doc(childId)
      .snapshots()
      .map((snap) => snap.exists ? snap.data() : null);
});