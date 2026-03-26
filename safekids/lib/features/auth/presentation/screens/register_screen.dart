import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedRole; // 'parent' o 'child'

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
                        onPressed: _selectedRole == null
                            ? null
                            : () {
                                if (_selectedRole == 'parent') {
                                  context.go('/dashboard/parent');
                                } else {
                                  context.go('/dashboard/child');
                                }
                              },
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
                        child: Text(
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