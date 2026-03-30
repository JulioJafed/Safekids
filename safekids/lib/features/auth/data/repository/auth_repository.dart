import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // REGISTRO
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Actualizar nombre en Firebase Auth
      await user.updateDisplayName(name);

      // Guardar en Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': role,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'linkedParentId': null,
      });

      // Enviar correo de verificación
      await user.sendEmailVerification();

      return AuthResult.success(role: role);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e.code));
    } catch (e) {
      return AuthResult.error('Error inesperado. Intentá de nuevo.');
    }
  }

  // LOGIN
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Verificar si confirmó el correo
      if (!user.emailVerified) {
        return AuthResult.error(
          'Verificá tu correo antes de ingresar. Revisá tu bandeja de entrada.',
          needsVerification: true,
          uid: user.uid,
        );
      }

      // Obtener rol desde Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'parent';

      // Actualizar emailVerified en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });

      return AuthResult.success(role: role);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e.code));
    } catch (e) {
      return AuthResult.error('Error inesperado. Intentá de nuevo.');
    }
  }

  // REENVIAR VERIFICACIÓN
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // OLVIDÉ MI CONTRASEÑA
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(role: '');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e.code));
    }
  }

  // CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ERRORES en español
  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error al iniciar sesión. Intentá de nuevo.';
    }
  }
}

// Modelo de resultado
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String role;
  final bool needsVerification;
  final String? uid;

  AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    required this.role,
    this.needsVerification = false,
    this.uid,
  });

  factory AuthResult.success({required String role}) =>
      AuthResult._(isSuccess: true, role: role);

  factory AuthResult.error(
    String message, {
    bool needsVerification = false,
    String? uid,
  }) =>
      AuthResult._(
        isSuccess: false,
        errorMessage: message,
        role: '',
        needsVerification: needsVerification,
        uid: uid,
      );
}