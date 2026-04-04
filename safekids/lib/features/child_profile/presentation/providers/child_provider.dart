import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/child_repository.dart';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepository();
});

final childProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(childRepositoryProvider).watchChildProfile();
});

final screenTimeRulesProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(childRepositoryProvider).watchScreenTimeRules();
});

final blockedAppsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(childRepositoryProvider).watchBlockedApps();
});

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(childRepositoryProvider).watchUserData();
});