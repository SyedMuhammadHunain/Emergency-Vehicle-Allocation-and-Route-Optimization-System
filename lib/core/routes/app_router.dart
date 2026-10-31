import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/citizen/screens/emergency_detail_screen.dart';
import '../../features/citizen/screens/live_tracking_screen.dart';
import '../../features/citizen/screens/notifications_screen.dart';
import '../../features/citizen/screens/report_emergency_screen.dart';
import '../../features/shell/screens/role_shell.dart';
import '../services/session_service.dart';

final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createRouter(SessionService session) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';

      // 1. If not logged in and attempting to access a protected app route, go to login
      if (!session.isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // 2. If already logged in and on login/register, go directly to role dashboard
      if (session.isLoggedIn &&
          (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/role-shell';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/role-shell',
        builder: (context, state) {
          final role = session.role ?? 'citizen';
          return RoleShell(
            key: ValueKey(role),
            initialRole: role,
          );
        },
      ),
      GoRoute(
        path: '/citizen/report',
        builder: (context, state) {
          final category = state.extra as String?;
          return ReportEmergencyScreen(
            initialCategory: category,
            isStandalone: true,
          );
        },
      ),
      GoRoute(
        path: '/citizen/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'EM-2026-0001';
          return EmergencyDetailScreen(emergencyId: id);
        },
      ),
      GoRoute(
        path: '/citizen/tracking/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'EM-2026-0001';
          return LiveTrackingScreen(emergencyId: id);
        },
      ),
      GoRoute(
        path: '/citizen/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
