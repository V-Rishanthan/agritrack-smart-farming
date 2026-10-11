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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  debugLogDiagnostics: false,
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
