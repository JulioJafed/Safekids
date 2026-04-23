import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/app_detection_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _hasUsagePermission = false;
  bool _syncDone = false;
  String _syncStatus = '';
  int _appsFound = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      color: const Color(0xFF7B9FFF),
      title: 'Bienvenido a SafeKids',
      description: 'SafeKids protege a tus hijos en el mundo digital. Para funcionar correctamente necesitamos tu autorización.',
    ),
    _OnboardingPage(
      icon: Icons.family_restroom_rounded,
      color: const Color(0xFF6ECFB5),
      title: 'Control parental inteligente',
      description: 'Los padres pueden monitorear el uso del celular, bloquear apps y establecer límites de tiempo desde su propio dispositivo.',
    ),

    _OnboardingPage(
      icon: Icons.privacy_tip_rounded,
      color: const Color(0xFFFFB347),
      title: 'Tu privacidad es importante',
      description: 'Solo recopilamos información sobre el uso de apps y tiempo en pantalla. No accedemos a mensajes, fotos ni datos personales.',
    ),
    _OnboardingPage(
      icon: Icons.policy_rounded,
      color: const Color(0xFFFF8FAB),
      title: 'Términos y condiciones',
      description: 'Al usar SafeKids aceptás que la app monitoree el uso del dispositivo con fines de control parental. Esta información solo es accesible para el padre/madre vinculado.',
      isTerms: true,
    ),
    
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFF7B9FFF),
      title: 'Permiso de uso de apps',
      description: 'Necesitamos que actives el permiso de acceso al uso para poder ver qué apps usás y cuánto tiempo. Sin este permiso la app no puede funcionar.',
      isPermission: true,
    ),
       
        _OnboardingPage(
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF2D3A6B),
        title: 'Protección del dispositivo',
        description:
            'Para evitar que SafeKids sea desinstalado o desactivado sin autorización del padre/madre, necesitamos permisos de administrador.',
        isAdmin: true,
      ),

    _OnboardingPage(
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFF6ECFB5),
      title: 'Permiso de accesibilidad',
      description:
          'Necesitamos el servicio de accesibilidad para poder bloquear apps automáticamente cuando el padre lo indique.',
      isAccessibility: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _checkAccessibility();
    _checkAdmin();
  }

  bool _hasAccessibilityPermission = false;

  Future<void> _checkAccessibility() async {
    final has = await AppDetectionService.hasAccessibilityPermission();
    if (mounted) setState(() => _hasAccessibilityPermission = has);
  }

  Future<void> _openAccessibilitySettings() async {
    await AppDetectionService.openAccessibilitySettings();
    await Future.delayed(const Duration(seconds: 2));
    await _checkAccessibility();
  }

  Future<void> _checkPermission() async {
    final has = await AppDetectionService.hasUsagePermission();
    if (mounted) setState(() => _hasUsagePermission = has);
  }

  Future<void> _openSettings() async {
    setState(() => _isLoading = true);
    await AppDetectionService.openUsageSettings();
    // Esperar que el usuario vuelva de configuración
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermission();
    setState(() => _isLoading = false);

    // Si activó el permiso → sincronizar automáticamente
    if (_hasUsagePermission && !_syncDone) {
      await _syncApps();
    }
  }

  Future<void> _syncApps() async {
    setState(() {
      _syncStatus = 'Detectando apps instaladas...';
      _isLoading = true;
    });

    try {
      final apps = await AppDetectionService.getInstalledApps();

      // Guardar localmente — se subirá a Firebase después del login
      final prefs = await SharedPreferences.getInstance();
      final appsJson = apps.map((a) => '${a.packageName}|${a.name}|${a.category}').toList();
      await prefs.setStringList('pending_apps_sync', appsJson);
      await prefs.setInt('pending_apps_count', apps.length);

      setState(() {
        _syncDone = true;
        _appsFound = apps.length;
        _syncStatus = '✓ $_appsFound apps detectadas correctamente';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _syncStatus = 'Error al detectar apps: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
    bool _hasAdminPermission = false;

    Future<void> _checkAdmin() async {
      final has = await AppDetectionService.isDeviceAdminActive();
      if (mounted) setState(() => _hasAdminPermission = has);
    }

    Future<void> _activateAdmin() async {
      await AppDetectionService.activateDeviceAdmin();
      await Future.delayed(const Duration(seconds: 2));
      await _checkAdmin();
    }



  bool get _canProceed {
    final page = _pages[_currentPage];
    if (page.isTerms && !_acceptedTerms) return false;
    if (page.isPermission && !_hasUsagePermission) return false;
    if (page.isAccessibility && !_hasAccessibilityPermission) return false;
    if (page.isAdmin && !_hasAdminPermission) return false;
    
    return true;
  }

  
  

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // Indicadores
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(_pages.length, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? _pages[_currentPage].color
                            : const Color(0xFFE8ECF8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _canProceed
                              ? (_isLastPage ? _completeOnboarding : _nextPage)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        disabledBackgroundColor: const Color(0xFFBFC8E2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              _isLastPage ? 'Comenzar' : 'Siguiente',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  if (_pages[_currentPage].isPermission &&
                      !_hasUsagePermission) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _showExitDialog(),
                      child: const Text(
                        'No acepto — salir de la app',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF8A94B2)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: page.color, size: 60),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3A6B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF8A94B2),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Términos
          if (page.isTerms) _buildTermsWidget(page),

          // Permiso
          if (page.isPermission) _buildPermissionWidget(),
          
          // Accesibilidad
          if (page.isAccessibility) _buildAccessibilityWidget(),

          if (page.isAdmin) _buildAdminWidget(),
        ],
      ),
    );
  }

  Widget _buildAdminWidget() {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _hasAdminPermission
          ? const Color(0xFF6ECFB5).withOpacity(0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _hasAdminPermission
            ? const Color(0xFF6ECFB5)
            : const Color(0xFFE8ECF8),
        width: _hasAdminPermission ? 1.5 : 1,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hasAdminPermission
                    ? const Color(0xFF6ECFB5).withOpacity(0.2)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _hasAdminPermission
                    ? Icons.check_circle_rounded
                    : Icons.admin_panel_settings_rounded,
                color: _hasAdminPermission
                    ? const Color(0xFF6ECFB5)
                    : const Color(0xFF2D3A6B),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasAdminPermission
                        ? '¡Protección activada!'
                        : 'Administrador del dispositivo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasAdminPermission
                          ? const Color(0xFF3A9E87)
                          : const Color(0xFF2D3A6B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _hasAdminPermission
                        ? 'SafeKids está protegido'
                        : 'Evita que el hijo desinstale la app',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A94B2)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!_hasAdminPermission) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _activateAdmin,
              icon: const Icon(Icons.security_rounded, size: 18),
              label: const Text('Activar protección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3A6B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildAccessibilityWidget() {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _hasAccessibilityPermission
          ? const Color(0xFF6ECFB5).withOpacity(0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _hasAccessibilityPermission
            ? const Color(0xFF6ECFB5)
            : const Color(0xFFE8ECF8),
        width: _hasAccessibilityPermission ? 1.5 : 1,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hasAccessibilityPermission
                    ? const Color(0xFF6ECFB5).withOpacity(0.2)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _hasAccessibilityPermission
                    ? Icons.check_circle_rounded
                    : Icons.accessibility_new_rounded,
                color: _hasAccessibilityPermission
                    ? const Color(0xFF6ECFB5)
                    : const Color(0xFF7B9FFF),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasAccessibilityPermission
                        ? '¡Servicio activado!'
                        : 'Servicio de accesibilidad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hasAccessibilityPermission
                          ? const Color(0xFF3A9E87)
                          : const Color(0xFF2D3A6B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _hasAccessibilityPermission
                        ? 'SafeKids puede bloquear apps'
                        : 'Requerido para bloquear apps',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A94B2)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!_hasAccessibilityPermission) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAccessibilitySettings,
              icon: const Icon(Icons.settings_accessibility_rounded,
                  size: 18),
              label: const Text('Activar servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6ECFB5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('¿Cómo activarlo?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B))),
                SizedBox(height: 8),
                _Step(num: '1', text: 'Tocá "Activar servicio"'),
                _Step(num: '2', text: 'Buscá "SafeKids" en la lista'),
                _Step(num: '3', text: 'Activá "SafeKids Control Parental"'),
                _Step(num: '4', text: 'Volvé a la app'),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
  

  Widget _buildTermsWidget(_OnboardingPage page) {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _acceptedTerms ? page.color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _acceptedTerms ? page.color : const Color(0xFFE8ECF8),
            width: _acceptedTerms ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _acceptedTerms ? page.color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _acceptedTerms ? page.color : const Color(0xFFBFC8E2),
                  width: 1.5,
                ),
              ),
              child: _acceptedTerms
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Acepto los términos y condiciones y la política de privacidad de SafeKids',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF2D3A6B), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWidget() {
    return Column(
      children: [
        // Card de estado del permiso
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hasUsagePermission
                ? const Color(0xFF6ECFB5).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasUsagePermission
                  ? const Color(0xFF6ECFB5)
                  : const Color(0xFFE8ECF8),
              width: _hasUsagePermission ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hasUsagePermission
                          ? const Color(0xFF6ECFB5).withOpacity(0.2)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _hasUsagePermission
                          ? Icons.check_circle_rounded
                          : Icons.bar_chart_rounded,
                      color: _hasUsagePermission
                          ? const Color(0xFF6ECFB5)
                          : const Color(0xFF7B9FFF),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasUsagePermission
                              ? '¡Permiso activado!'
                              : 'Acceso al uso de apps',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _hasUsagePermission
                                ? const Color(0xFF3A9E87)
                                : const Color(0xFF2D3A6B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _hasUsagePermission
                              ? 'SafeKids puede monitorear el uso'
                              : 'Requerido para el control parental',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8A94B2)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Botón activar permiso
              if (!_hasUsagePermission) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openSettings,
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: const Text('Activar en configuración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B9FFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],

              // Estado de sincronización
              if (_syncStatus.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _syncDone
                        ? const Color(0xFF6ECFB5).withOpacity(0.1)
                        : const Color(0xFF7B9FFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _syncDone
                            ? Icons.check_circle_rounded
                            : Icons.sync_rounded,
                        color: _syncDone
                            ? const Color(0xFF6ECFB5)
                            : const Color(0xFF7B9FFF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _syncStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _syncDone
                                ? const Color(0xFF3A9E87)
                                : const Color(0xFF5578CC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Resumen si ya sincronizó
              if (_syncDone) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B9FFF).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apps_rounded,
                          color: Color(0xFF7B9FFF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$_appsFound apps detectadas y enviadas al padre',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5578CC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Instrucciones si no tiene permiso
        if (!_hasUsagePermission) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('¿Cómo activar el permiso?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3A6B))),
                SizedBox(height: 10),
                _Step(num: '1', text: 'Tocá "Activar en configuración"'),
                _Step(num: '2', text: 'Buscá "SafeKids" en la lista'),
                _Step(num: '3', text: 'Activá el acceso al uso'),
                _Step(num: '4', text: 'Volvé a la app — se sincroniza solo'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Salir de SafeKids?',
            style: TextStyle(
                color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: const Text(
          'Sin el permiso de uso, SafeKids no puede funcionar. ¿Estás seguro que querés salir?',
          style:
              TextStyle(color: Color(0xFF8A94B2), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver',
                style: TextStyle(color: Color(0xFF7B9FFF))),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Widgets auxiliares
class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isTerms;
  final bool isPermission;
  final bool isAccessibility;
  final bool isAdmin;


  _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.isTerms = false,
    this.isPermission = false,
    this.isAccessibility = false,
    this.isAdmin = false,
  });
  
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FFF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B9FFF))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF8A94B2))),
          ),
        ],
      ),
    );
  }
}