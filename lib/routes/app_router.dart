import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_farming/auth/screens/login_screen.dart';
import 'package:smart_farming/auth/screens/signup_screen.dart';
import 'package:smart_farming/features/analysis/screens/analysis_screen.dart';
import 'package:smart_farming/features/driver/screen/driver_screen.dart';
import 'package:smart_farming/features/expenses/screens/expenses_screen.dart';
import 'package:smart_farming/features/home/home_screen.dart';
import 'package:smart_farming/features/onboarding.dart';
import 'package:smart_farming/features/owners/screens/owners_screen.dart';
import 'package:smart_farming/features/widgets/bottom_nav_bar.dart';
import 'package:smart_farming/services/auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final _authService = AuthService();

/// Makes GoRouter run `redirect` again every time the user signs in or out.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Screens a signed-out user is allowed to see.
const _publicPages = ['/onboarding', '/login', '/signup'];

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  debugLogDiagnostics: false,

  // Re-check the redirect below whenever login state changes
  refreshListenable: _AuthRefresh(_authService.authStateChanges),

  redirect: (context, state) {
    final loggedIn = _authService.currentUser != null;
    final onPublicPage = _publicPages.contains(state.matchedLocation);

    // Signed out and trying to open an app screen -> send to onboarding
    if (!loggedIn && !onPublicPage) return '/onboarding';

    // Already signed in but on onboarding / login / signup - go to home
    if (loggedIn && onPublicPage) return '/home';

    return null; // no redirect, stay where you are
  },

  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/onboarding'),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Stateful Nested Bottom Navigation Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        );
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1: Owners
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/owners',
              name: 'owners',
              builder: (context, state) => const OwnersScreen(),
            ),
          ],
        ),

        // Tab 2: Driver
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/driver',
              name: 'driver',
              builder: (context, state) => const DriverScreen(),
            ),
          ],
        ),

        // Tab 3: Expenses
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              name: 'expenses',
              builder: (context, state) => const ExpensesScreen(),
            ),
          ],
        ),

        // Tab 4: Analysis
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analysis',
              name: 'analysis',
              builder: (context, state) => const AnalysisScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
