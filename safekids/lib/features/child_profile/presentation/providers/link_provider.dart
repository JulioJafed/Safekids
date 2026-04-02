import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/link_repository.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository();
});

final linkedChildrenProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(linkRepositoryProvider).watchLinkedChildren();
});

final linkStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(linkRepositoryProvider).watchLinkStatus();
});