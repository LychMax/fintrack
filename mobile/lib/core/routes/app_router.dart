import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../shared/widgets/scaffold_with_nav_bar.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: true,

  redirect: (context, state) {
    final authState = ProviderScope.containerOf(context).read(authProvider);

    final isLoggedIn = authState.isAuthenticated;
    final location = state.location;

    final isGoingToLogin = location == '/login';
    final isGoingToRegister = location == '/register';

    if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister) {
      return '/login';
    }

    if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
      return '/';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
          const SizedBox(height: 24),
          const Text(
            'Страница не найдена',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
            child: const Text('На главную'),
          ),
        ],
      ),
    ),
  ),
);