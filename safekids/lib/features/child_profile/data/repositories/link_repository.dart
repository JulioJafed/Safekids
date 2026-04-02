import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LinkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GENERAR código único para el hijo
  Future<String> generateLinkCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    // Generar código aleatorio
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final raw = List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
    final code = '${raw.substring(0, 4)}-${raw.substring(4)}';

    // Eliminar códigos anteriores del hijo
    final oldCodes = await _firestore
        .collection('linkCodes')
        .where('childId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in oldCodes.docs) {
      await doc.reference.delete();
    }

    // Guardar nuevo código en Firestore
    await _firestore.collection('linkCodes').doc(code).set({
      'code': code,
      'childId': uid,
      'parentId': null,
      'status': 'pending',
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  // VERIFICAR si el código sigue vigente (stream en tiempo real)
  Stream<bool> watchLinkStatus() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('linkCodes')
        .where('childId', isEqualTo: uid)
        .where('status', isEqualTo: 'linked')
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  // VINCULAR desde el padre — ingresa el código
  Future<LinkResult> linkWithCode(String code) async {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) return LinkResult.error('No autenticado');

    try {
      final docRef = _firestore.collection('linkCodes').doc(code.toUpperCase());
      final doc = await docRef.get();

      if (!doc.exists) {
        return LinkResult.error('Código incorrecto. Verificá que esté bien escrito.');
      }

      final data = doc.data()!;

      // Verificar expiración
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        return LinkResult.error('El código expiró. Pedile al hijo que genere uno nuevo.');
      }

      // Verificar que no esté ya usado
      if (data['status'] == 'linked') {
        return LinkResult.error('Este código ya fue usado.');
      }

      final childId = data['childId'] as String;

      // Verificar que no sea el mismo usuario
      if (childId == parentId) {
        return LinkResult.error('No podés vincularte con vos mismo.');
      }

      // Obtener datos del hijo
      final childDoc = await _firestore.collection('users').doc(childId).get();
      final childName = childDoc.data()?['name'] ?? 'Hijo/a';

      // Transacción — actualizar todo de forma atómica
      await _firestore.runTransaction((transaction) async {
        // Marcar código como usado
        transaction.update(docRef, {
          'parentId': parentId,
          'status': 'linked',
          'linkedAt': FieldValue.serverTimestamp(),
        });

        // Actualizar usuario hijo — agregar parentId
        transaction.update(
          _firestore.collection('users').doc(childId),
          {'linkedParentId': parentId},
        );

        // Actualizar childProfile
        transaction.set(
          _firestore.collection('childProfiles').doc(childId),
          {
            'childId': childId,
            'parentId': parentId,
            'name': childName,
            'deviceStatus': 'online',
            'isDeviceLocked': false,
            'lastSeen': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Agregar hijo a lista del padre
        transaction.set(
          _firestore.collection('parentProfiles').doc(parentId),
          {
            'linkedChildren': FieldValue.arrayUnion([childId]),
          },
          SetOptions(merge: true),
        );
      });

      return LinkResult.success(childName: childName, childId: childId);
    } catch (e) {
      return LinkResult.error('Error al vincular: $e');
    }
  }

  // OBTENER hijos vinculados al padre
  Stream<List<Map<String, dynamic>>> watchLinkedChildren() {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) return Stream.value([]);

    return _firestore
        .collection('childProfiles')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // DESVINCULAR hijo
  Future<void> unlinkChild(String childId) async {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) return;

    await _firestore.runTransaction((transaction) async {
      transaction.update(
        _firestore.collection('users').doc(childId),
        {'linkedParentId': null},
      );
      transaction.update(
        _firestore.collection('childProfiles').doc(childId),
        {'parentId': null, 'deviceStatus': 'offline'},
      );
      transaction.update(
        _firestore.collection('parentProfiles').doc(parentId),
        {'linkedChildren': FieldValue.arrayRemove([childId])},
      );
    });
  }
}

// Modelo resultado
class LinkResult {
  final bool isSuccess;
  final String? errorMessage;
  final String childName;
  final String childId;

  LinkResult._({
    required this.isSuccess,
    this.errorMessage,
    this.childName = '',
    this.childId = '',
  });

  factory LinkResult.success({
    required String childName,
    required String childId,
  }) => LinkResult._(isSuccess: true, childName: childName, childId: childId);

  factory LinkResult.error(String message) =>
      LinkResult._(isSuccess: false, errorMessage: message);
}