import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safekids/core/services/app_detection_service.dart';
import '../providers/auth_provider.dart';
import '../../../../core/services/block_enforcement_service.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Completá todos los campos.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    final result = await ref.read(authRepositoryProvider).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
        if (result.role == 'parent') {
          context.go('/dashboard/parent');
        } else {
           // Iniciar servicio nativo de escucha
          AppDetectionService.startFirestoreService();
          // Guardar UID para el servicio nativo
          await AppDetectionService.saveChildUid(
            FirebaseAuth.instance.currentUser!.uid
          );
          // Iniciar el servicio de bloqueo para el hijo
          BlockEnforcementService().startListening();
          context.go('/dashboard/child');
        }
    } else if (result.needsVerification) {
      _showVerificationDialog();
    } else {
      setState(() => _errorMessage = result.errorMessage ?? '');
    }
  }

  void _showForgotPassword() {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recuperar contraseña',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3A6B))),
            const SizedBox(height: 8),
            const Text('Te enviaremos un correo para restablecer tu contraseña.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2), height: 1.5)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Tu correo electrónico',
                hintStyle: const TextStyle(color: Color(0xFFBFC8E2)),
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF7B9FFF), size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F7FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7B9FFF), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim().isEmpty) return;
                  final result = await ref.read(authRepositoryProvider)
                      .resetPassword(emailController.text.trim());
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result.isSuccess
                        ? '✓ Correo enviado. Revisá tu bandeja.'
                        : result.errorMessage ?? 'Error'),
                    backgroundColor: result.isSuccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B6B),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B9FFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Enviar correo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verificá tu correo',
            style: TextStyle(color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: const Text(
          'Te enviamos un correo de verificación. Revisá tu bandeja de entrada y hacé clic en el enlace.',
          style: TextStyle(color: Color(0xFF8A94B2), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF8A94B2))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).resendVerificationEmail();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✓ Correo reenviado'),
                backgroundColor: Color(0xFF4CAF50),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B9FFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reenviar correo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B9FFF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF7B9FFF).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.shield_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('SafeKids', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2D3A6B), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              const Text('Protegé a tus hijos en el mundo digital', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF7B9FFF).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Iniciar sesión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF2D3A6B))),
                    const SizedBox(height: 6),
                    const Text('Ingresá tus datos para continuar', style: TextStyle(fontSize: 13, color: Color(0xFF8A94B2))),
                    const SizedBox(height: 28),

                    // Error message
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage, style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Correo electrónico', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D3A6B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'ejemplo@correo.com',
                        hintStyle: const TextStyle(color: Color(0xFFBFC8E2)),
                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF7B9FFF), size: 20),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7B9FFF), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Contraseña', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D3A6B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xFFBFC8E2)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF7B9FFF), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF8A94B2), size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7B9FFF), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPassword,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13, color: Color(0xFF7B9FFF), fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B9FFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tenés cuenta? ', style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('Registrate', style: TextStyle(fontSize: 14, color: Color(0xFF7B9FFF), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}