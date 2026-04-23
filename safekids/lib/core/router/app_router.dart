import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safekids/core/services/persistent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/parent_dashboard_screen.dart';
import '../../features/auth/presentation/screens/child_home_screen.dart';
import '../../features/child_profile/presentation/screens/link_device_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard/parent',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/child',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/link-device',
        builder: (context, state) => const LinkDeviceScreen(),
      ),
    ],
  );
});

// Splash screen que decide a dónde ir
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
  await Future.delayed(const Duration(milliseconds: 800));
  if (!mounted) return;

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_completed') ?? false;

  if (!onboardingDone) {
    context.go('/onboarding');
    return;
  }

  // Verificar si hay sesión activa de Firebase
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Sesión activa — ir directo al dashboard
    final role = await PersistentService.instance.getSavedRole();
    if (role == 'parent') {
      context.go('/dashboard/parent');
    } else if (role == 'child') {
      context.go('/dashboard/child');
    } else {
      context.go('/login');
    }
  } else {
    context.go('/login');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF7B9FFF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B9FFF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('SafeKids',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A6B))),
            const SizedBox(height: 8),
            const Text('Cargando...',
                style: TextStyle(fontSize: 14, color: Color(0xFF8A94B2))),
          ],
        ),
      ),
    );
  }
}