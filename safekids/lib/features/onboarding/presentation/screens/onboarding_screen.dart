import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_detection_service.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _acceptedTerms = false;
  bool _isRequestingPermission = false;
  bool _hasUsagePermission = false;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.shield_rounded,
      color: const Color(0xFF7B9FFF),
      title: 'Bienvenido a SafeKids',
      description:
          'SafeKids protege a tus hijos en el mundo digital. Para funcionar correctamente necesitamos tu autorización.',
    ),
    _OnboardingPage(
      icon: Icons.family_restroom_rounded,
      color: const Color(0xFF6ECFB5),
      title: 'Control parental inteligente',
      description:
          'Los padres pueden monitorear el uso del celular, bloquear apps y establecer límites de tiempo desde su propio dispositivo.',
    ),
    _OnboardingPage(
      icon: Icons.privacy_tip_rounded,
      color: const Color(0xFFFFB347),
      title: 'Tu privacidad es importante',
      description:
          'Solo recopilamos información sobre el uso de apps y tiempo en pantalla. No accedemos a mensajes, fotos ni datos personales.',
    ),
    _OnboardingPage(
      icon: Icons.policy_rounded,
      color: const Color(0xFFFF8FAB),
      title: 'Términos y condiciones',
      description:
          'Al usar SafeKids aceptás que la app monitoree el uso del dispositivo con fines de control parental. Esta información solo es accesible para el padre/madre vinculado.',
      isTerms: true,
    ),
    _OnboardingPage(
      icon: Icons.bar_chart_rounded,
      color: const Color(0xFF7B9FFF),
      title: 'Permiso de uso de apps',
      description:
          'Necesitamos que actives el permiso de "Acceso al uso" para poder ver qué apps usás y cuánto tiempo. Sin este permiso la app no puede funcionar.',
      isPermission: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await AppDetectionService.hasUsagePermission();
    setState(() => _hasUsagePermission = has);
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequestingPermission = true);
    await AppDetectionService.openUsageSettings();
    await Future.delayed(const Duration(seconds: 3));
    await _checkPermission();
    setState(() => _isRequestingPermission = false);
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

  bool get _canProceed {
    final page = _pages[_currentPage];
    if (page.isTerms && !_acceptedTerms) return false;
    if (page.isPermission && !_hasUsagePermission) return false;
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
            // Indicadores de página
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

            // Páginas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _buildPage(_pages[i]),
              ),
            ),

            // Botones
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _canProceed
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
                      child: Text(
                        _isLastPage ? 'Comenzar' : 'Siguiente',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  // Botón salir si no acepta permisos
                  if (_pages[_currentPage].isPermission &&
                      !_hasUsagePermission) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _showExitDialog(),
                      child: const Text(
                        'No acepto — salir de la app',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF8A94B2)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono animado
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

          const SizedBox(height: 40),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
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

          // Checkbox términos
          if (page.isTerms) ...[
            GestureDetector(
              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _acceptedTerms
                      ? page.color.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _acceptedTerms
                        ? page.color
                        : const Color(0xFFE8ECF8),
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
                        color: _acceptedTerms
                            ? page.color
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _acceptedTerms
                              ? page.color
                              : const Color(0xFFBFC8E2),
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
                            fontSize: 13,
                            color: Color(0xFF2D3A6B),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Botón permiso
          if (page.isPermission) ...[
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
                                  fontSize: 12,
                                  color: Color(0xFF8A94B2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_hasUsagePermission) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRequestingPermission
                            ? null
                            : _requestPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B9FFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isRequestingPermission
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Activar en configuración'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Salir de SafeKids?',
            style: TextStyle(
                color: Color(0xFF2D3A6B), fontWeight: FontWeight.w600)),
        content: const Text(
          'Sin el permiso de uso de apps, SafeKids no puede funcionar correctamente. ¿Estás seguro que querés salir?',
          style: TextStyle(
              color: Color(0xFF8A94B2), fontSize: 13, height: 1.5),
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

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool isTerms;
  final bool isPermission;

  _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.isTerms = false,
    this.isPermission = false,
  });
}