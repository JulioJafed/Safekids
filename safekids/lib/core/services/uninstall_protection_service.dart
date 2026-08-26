import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_detection_service.dart';

/// Protección anti-desinstalación: coordina el flujo de código de
/// autorización entre el dispositivo del padre y el del hijo usando la
/// colección `uninstallRequests/{childId}`.
///
/// Flujo:
/// 1. HIJO pide desinstalar -> requestUninstall() (requiere internet)
/// 2. PADRE ve la alerta en tiempo real -> generateCode() o denyRequest()
/// 3. HIJO ingresa el código -> verifyCode() -> si es correcto, se marca
///    autorizado en el dispositivo nativo (Device Admin ya puede
///    desactivarse sin que la app vuelva a bloquear el celular).
class UninstallProtectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection('uninstallRequests');

  String _generateCode() {
    final rnd = Random();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  /// HIJO — Inicia la solicitud. Si no hay internet, no se puede continuar
  /// de ninguna forma (esto es intencional: sin conexión, no hay manera de
  /// verificar con el padre, así que se bloquea el flujo por completo).
  Future<UninstallResult> requestUninstall(String childId) async {
    final hasNetwork = await AppDetectionService.hasNetworkConnection();
    if (!hasNetwork) {
      return UninstallResult.error(
        'Necesitás conexión a internet para solicitar la desinstalación. '
        'Sin internet no es posible continuar.',
      );
    }

    try {
      await _collection.doc(childId).set({
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'authCode': '',
        'authorizedAt': null,
      });
      return UninstallResult.success();
    } catch (e) {
      return UninstallResult.error('Error al enviar la solicitud: $e');
    }
  }

  /// PADRE — Genera un código de 6 dígitos válido por [ttlMinutes] minutos.
  Future<UninstallResult> generateCode(
    String childId, {
    int ttlMinutes = 5,
  }) async {
    try {
      final code = _generateCode();
      final expiresAt = DateTime.now().add(Duration(minutes: ttlMinutes));
      await _collection.doc(childId).set({
        'status': 'code_issued',
        'authCode': code,
        'codeExpiresAt': Timestamp.fromDate(expiresAt),
        'issuedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return UninstallResult.success(code: code);
    } catch (e) {
      return UninstallResult.error('Error al generar el código: $e');
    }
  }

  /// PADRE — Rechaza la solicitud. Bloquea el dispositivo del hijo de
  /// inmediato (sin esperar a que termine de desactivar Device Admin) y
  /// deja todo listo para que, si el hijo vuelve a intentarlo, se repita
  /// el ciclo completo desde cero.
  Future<UninstallResult> denyRequest(String childId) async {
    try {
      await _collection.doc(childId).set({
        'status': 'denied',
        'authCode': '',
        'deniedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Bloquear el dispositivo ya mismo, como refuerzo inmediato
      await _firestore.collection('childProfiles').doc(childId).update({
        'isDeviceLocked': true,
        'lockedReason': 'uninstall_denied',
      });

      return UninstallResult.success();
    } catch (e) {
      return UninstallResult.error('Error al denegar: $e');
    }
  }

  /// HIJO — Verifica el código ingresado. Si es correcto y no expiró,
  /// autoriza al sistema nativo a permitir la desactivación de Device
  /// Admin sin que SafeKids vuelva a bloquear el dispositivo.
  Future<UninstallResult> verifyCode({
    required String childId,
    required String code,
  }) async {
    try {
      final doc = await _collection.doc(childId).get();
      if (!doc.exists) {
        return UninstallResult.error('No hay ninguna solicitud activa.');
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['authCode'] ?? '';
      final expiresAt = (data['codeExpiresAt'] as Timestamp?)?.toDate();

      if (storedCode.isEmpty || storedCode != code) {
        return UninstallResult.error('Código incorrecto.');
      }

      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        return UninstallResult.error(
          'El código expiró. Pedile a tu padre/madre que genere uno nuevo.',
        );
      }

      // Código válido: autorizar en el dispositivo nativo
      await AppDetectionService.setUninstallAuthorized(ttlMinutes: 5);

      await _collection.doc(childId).set({
        'status': 'authorized',
        'authorizedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return UninstallResult.success();
    } catch (e) {
      return UninstallResult.error('Error al verificar el código: $e');
    }
  }

  /// PADRE — Escucha en tiempo real si el hijo intentó desinstalar o
  /// desactivar la protección.
  Stream<Map<String, dynamic>?> watchUninstallRequests(String childId) {
    return _collection.doc(childId).snapshots().map(
          (snap) => snap.exists ? snap.data() as Map<String, dynamic> : null,
        );
  }
}

class UninstallResult {
  final bool isSuccess;
  final String code;
  final String? errorMessage;

  UninstallResult._({
    required this.isSuccess,
    this.code = '',
    this.errorMessage,
  });

  factory UninstallResult.success({String code = ''}) =>
      UninstallResult._(isSuccess: true, code: code);

  factory UninstallResult.error(String message) =>
      UninstallResult._(isSuccess: false, errorMessage: message);
}