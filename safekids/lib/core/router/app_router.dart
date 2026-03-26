import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/parent_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
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
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFFF0F4FF),
          body: Center(
            child: Text('👦 Dashboard Hijo\n(próximo paso)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, color: Color(0xFF2D3A6B))),
          ),
        ),
      ),
    ],
  );
});