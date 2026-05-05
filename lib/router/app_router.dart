import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/kambing/kambing_list_screen.dart';
import '../screens/kambing/kambing_detail_screen.dart';
import '../screens/kambing/kambing_form_screen.dart';
import '../screens/kambing/scan_qr_screen.dart';
import '../screens/perkembangan/perkembangan_screen.dart';
import '../screens/perkembangan/perkembangan_form_screen.dart';
import '../screens/monitoring/monitoring_screen.dart';
import '../screens/user/user_list_screen.dart';
import '../screens/user/user_form_screen.dart';
import '../screens/role/role_list_screen.dart';
import '../screens/role/role_form_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/info/info_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final isAuth = state.matchedLocation.startsWith('/auth');
        final isSplash = state.matchedLocation == '/splash';

        if (isSplash) return null;
        if (!loggedIn && !isAuth) return '/auth/login';
        if (loggedIn && isAuth) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

        // Auth routes
        GoRoute(
          path: '/auth',
          redirect: (_, __) => '/auth/login',
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),

        // Main shell with bottom navigation
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/kambing',
              builder: (_, __) => const KambingListScreen(),
              routes: [
                GoRoute(
                  path: 'tambah',
                  builder: (_, __) => const KambingFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => KambingDetailScreen(
                    id: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final extra = state.extra as Map?;
                        return KambingFormScreen(kambing: extra?['kambing']);
                      },
                    ),
                    GoRoute(
                      path: 'perkembangan',
                      builder: (_, state) => PerkembanganScreen(
                        kambingId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    GoRoute(
                      path: 'perkembangan/tambah',
                      builder: (_, state) => PerkembanganFormScreen(
                        kambingId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/scan',
              builder: (_, __) => const ScanQrScreen(),
            ),
            GoRoute(
              path: '/monitoring',
              builder: (_, __) => const MonitoringScreen(),
            ),
            GoRoute(
              path: '/user',
              builder: (_, __) => const UserListScreen(),
              routes: [
                GoRoute(
                  path: 'tambah',
                  builder: (_, __) => const UserFormScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) {
                    final extra = state.extra as Map?;
                    return UserFormScreen(user: extra?['user']);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/role',
              builder: (_, __) => const RoleListScreen(),
              routes: [
                GoRoute(
                  path: 'tambah',
                  builder: (_, __) => const RoleFormScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) {
                    final extra = state.extra as Map?;
                    return RoleFormScreen(role: extra?['role']);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/info',
              builder: (_, __) => const InfoScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
