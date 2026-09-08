import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safekids/core/services/persistent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? gender, // 'boy' o 'girl' — solo aplica si role == 'child'
  DateTime? birthDate, // solo aplica si role == 'child'
}) async {
  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Actualizar nombre en Firebase Auth
    await user.updateDisplayName(name);

    // Guardar en colección users
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'role': role,
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'linkedParentId': null,
      'photoUrl': null,
    });

    // Si es padre → crear documento en childProfiles vacío
    // (los hijos se agregarán después al vincularse)
    if (role == 'parent') {
      await _firestore.collection('parentProfiles').doc(user.uid).set({
        'parentId': user.uid,
        'name': name,
        'email': email,
        'linkedChildren': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Si es hijo → crear documento base en childProfiles
        if (role == 'child') {
      final calculatedAge = birthDate != null ? _calculateAge(birthDate) : 0;

      await _firestore.collection('childProfiles').doc(user.uid).set({
        'childId': user.uid,
        'name': name,
        'email': email,
        'parentId': null,
        'gender': gender ?? 'girl',
        'emoji': gender == 'boy' ? '👦' : '👧',
        'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
        'age': calculatedAge,
        'deviceStatus': 'offline',
        'isDeviceLocked': false,
        'lastActivityAt': null,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crear reglas de tiempo por defecto
      await _firestore.collection('screenTimeRules').doc(user.uid).set({
        'childId': user.uid,
        'dailyLimitMinutes': 120,
        'autoBlock': true,
        'isActive': true,
        'usedTodayMinutes': 0,
        'lastReset': FieldValue.serverTimestamp(),
      });

      // Crear reglas de apps por defecto
      await _firestore.collection('appRules').doc(user.uid).set({
        'childId': user.uid,
        'blockedApps': [],
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': null,
      });
    }

    // Enviar correo de verificación
    await user.sendEmailVerification();

    // Subir apps pendientes si las hay
      await _uploadPendingApps(user.uid);

      return AuthResult.success(role: role);
  } on FirebaseAuthException catch (e) {
    return AuthResult.error(_handleAuthError(e.code));
  } catch (e) {
    print('❌ Error registro: $e');
    return AuthResult.error('Error inesperado: $e');
  }
}

    // Calcula la edad exacta a partir de la fecha de nacimiento
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
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
      String role = 'parent'; // Default
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
         final rawRole = doc.data()?['role'] ?? 'parent';
          role = (rawRole == 'parent' || rawRole == 'child')
              ? rawRole
              : 'parent';
        }
      } catch (firestoreError) {
        print('⚠️ Error accediendo Firestore: $firestoreError');
        // Continuar con rol default si hay error en Firestore
      }

      // Actualizar emailVerified en Firestore (sin bloquear si falla)
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });
      } catch (updateError) {
        print('⚠️ Error actualizando emailVerified: $updateError');
      }

      // Guardar sesión localmente
      await PersistentService.instance.saveSession(
        uid: user.uid,
        role: role,
        email: user.email ?? '',
      );

      return AuthResult.success(role: role);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_handleAuthError(e.code));
    } catch (e) {
      print('❌ Error login: $e');
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

// SUBIR APPS PENDIENTES después del login
  Future<void> _uploadPendingApps(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appsJson = prefs.getStringList('pending_apps_sync');
      if (appsJson == null || appsJson.isEmpty) return;

      final apps = appsJson.map((entry) {
        final parts = entry.split('|');
        if (parts.length < 3) return null;
        return {
          'packageName': parts[0],
          'name': parts[1],
          'category': parts[2],
          'isBlocked': false,
        };
      }).whereType<Map<String, dynamic>>().toList();

      if (apps.isEmpty) return;

      await _firestore.collection('installedApps').doc(uid).set({
        'childId': uid,
        'apps': apps,
        'lastSync': FieldValue.serverTimestamp(),
        'totalApps': apps.length,
      });

      // Limpiar datos locales
      await prefs.remove('pending_apps_sync');
      await prefs.remove('pending_apps_count');
    } catch (e) {
      print('⚠️ Error subiendo apps: $e');
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