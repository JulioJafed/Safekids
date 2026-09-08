import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedRole; // 'parent' o 'child'

  // Nuevos campos, solo para rol 'child'
  String? _selectedGender; // 'boy' o 'girl'
  DateTime? _selectedBirthDate;

  int? get _calculatedAge {
    if (_selectedBirthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedBirthDate!.year;
    if (now.month < _selectedBirthDate!.month ||
        (now.month == _selectedBirthDate!.month &&
            now.day < _selectedBirthDate!.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      locale: const Locale('es'),
      helpText: 'Fecha de nacimiento',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7B9FFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3A6B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedRole == null) {
      setState(() => _errorMessage = 'Completá todos los campos y seleccioná un rol.');
      return;
    }

    if (_selectedRole == 'child' &&
        (_selectedGender == null || _selectedBirthDate == null)) {
      setState(() => _errorMessage =
          'Seleccioná el avatar y la fecha de nacimiento del hijo/a.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ref.read(authRepositoryProvider).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole!,
          gender: _selectedRole == 'child' ? _selectedGender : null,
          birthDate: _selectedRole == 'child' ? _selectedBirthDate : null,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cuenta creada. Revisá tu email para verificar la cuenta.'),
        backgroundColor: Color(0xFF4CAF50),
      ));

      context.go('/login');
    } else if (result.needsVerification) {
      _showVerificationDialog();
    } else {
      setState(() => _errorMessage = result.errorMessage ?? 'Error al registrarse.');
    }
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2D3A6B)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Título
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3A6B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completá tus datos para comenzar',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2)),
              ),

              const SizedBox(height: 28),

              // ── SELECCIÓN DE ROL ──────────────────────────────
              const Text(
                '¿Este celular es de...?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A6B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Esto define qué puede hacer cada usuario en la app',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A94B2)),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      role: 'parent',
                      selected: _selectedRole == 'parent',
                      icon: Icons.supervisor_account_rounded,
                      label: 'Padre / Madre',
                      description: 'Controlás y monitoreás el dispositivo del hijo',
                      color: const Color(0xFF7B9FFF),
                      onTap: () => setState(() => _selectedRole = 'parent'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      role: 'child',
                      selected: _selectedRole == 'child',
                      icon: Icons.child_care_rounded,
                      label: 'Hijo / Hija',
                      description: 'Usás el dispositivo con los límites del padre',
                      color: const Color(0xFF6ECFB5),
                      onTap: () => setState(() => _selectedRole = 'child'),
                    ),
                  ),
                ],
              ),

              // Banner informativo según rol
              if (_selectedRole != null) ...[
                const SizedBox(height: 14),
                _RoleBanner(role: _selectedRole!),
              ],

              // ── AVATAR + FECHA DE NACIMIENTO (solo para hijo) ──
              if (_selectedRole == 'child') ...[
                const SizedBox(height: 20),
                const Text(
                  'Avatar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3A6B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        emoji: '👦',
                        label: 'Niño',
                        selected: _selectedGender == 'boy',
                        onTap: () => setState(() => _selectedGender = 'boy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderCard(
                        emoji: '👧',
                        label: 'Niña',
                        selected: _selectedGender == 'girl',
                        onTap: () => setState(() => _selectedGender = 'girl'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  'Fecha de nacimiento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3A6B),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: _selectedBirthDate != null
                          ? Border.all(
                              color: const Color(0xFF7B9FFF), width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: Color(0xFF7B9FFF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedBirthDate == null
                                ? 'Seleccioná la fecha'
                                : '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.month.toString().padLeft(2, '0')}/'
                                  '${_selectedBirthDate!.year}'
                                  '  •  $_calculatedAge años',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedBirthDate == null
                                  ? const Color(0xFFBFC8E2)
                                  : const Color(0xFF2D3A6B),
                              fontWeight: _selectedBirthDate == null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFB0BAD3)),
                      ],
                    ),
                  ),
                ),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
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
              ],

              const SizedBox(height: 14),
              const SizedBox(height: 28),

              // ── FORMULARIO ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B9FFF).withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _FieldLabel('Nombre completo'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _nameController,
                      hint: 'Tu nombre',
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel('Correo electrónico'),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailController,
                      hint: 'ejemplo@correo.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    _FieldLabel('Contraseña'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle:
                            const TextStyle(color: Color(0xFFBFC8E2)),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF7B9FFF),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF8A94B2),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF7B9FFF), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Botón registrarse
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedRole == null || _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B9FFF),
                          disabledBackgroundColor:
                              const Color(0xFFBFC8E2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _selectedRole == null
                                    ? 'Seleccioná un rol primero'
                                    : 'Crear cuenta como ${_selectedRole == 'parent' ? 'Padre/Madre' : 'Hijo/Hija'}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ya tengo cuenta
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tenés cuenta? ',
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Iniciá sesión',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7B9FFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ─────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String role;
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : const Color(0xFFE8ECF8),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? color : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : const Color(0xFF8A94B2),
                  size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? color : const Color(0xFF2D3A6B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A94B2),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7B9FFF).withOpacity(0.12)
              : const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF7B9FFF) : const Color(0xFFE8ECF8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF7B9FFF) : const Color(0xFF8A94B2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  final String role;
  const _RoleBanner({required this.role});

  @override
  Widget build(BuildContext context) {
    final isParent = role == 'parent';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isParent
            ? const Color(0xFF7B9FFF).withOpacity(0.08)
            : const Color(0xFF6ECFB5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isParent
              ? const Color(0xFF7B9FFF).withOpacity(0.3)
              : const Color(0xFF6ECFB5).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isParent ? Icons.info_outline_rounded : Icons.child_friendly_rounded,
            color: isParent
                ? const Color(0xFF7B9FFF)
                : const Color(0xFF6ECFB5),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isParent
                  ? 'Como Padre/Madre podés: ver reportes, bloquear apps, establecer horarios, rastrear ubicación y recibir alertas.'
                  : 'Como Hijo/Hija podés: usar el dispositivo dentro de los límites que establezca tu padre/madre.',
              style: TextStyle(
                fontSize: 12,
                color: isParent
                    ? const Color(0xFF5578CC)
                    : const Color(0xFF3A9E87),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2D3A6B),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBFC8E2)),
        prefixIcon: Icon(icon, color: const Color(0xFF7B9FFF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7B9FFF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}