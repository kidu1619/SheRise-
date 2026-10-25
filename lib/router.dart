import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/cases_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/profile_screen.dart';
import 'screens/quick_exit_screen.dart';
import 'screens/safety_screens.dart';
import 'screens/safevoice_screens.dart';
import 'screens/support_screen.dart';
import 'i18n.dart';
import 'theme.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/recover', builder: (_, __) => const RecoverScreen()),
    GoRoute(path: '/quick-exit', builder: (_, __) => const QuickExitScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'safety',
                builder: (_, __) => const SafetyCenterScreen(),
                routes: [
                  GoRoute(
                      path: 'share',
                      builder: (_, __) => const ReviewSharingScreen()),
                  GoRoute(
                      path: 'plan',
                      builder: (_, __) => const SafetyPlanScreen()),
                ],
              ),
              GoRoute(
                path: 'cases',
                builder: (_, __) => const CasesScreen(),
                routes: [
                  GoRoute(
                    path: ':code',
                    builder: (_, state) =>
                        CaseDetailScreen(code: state.pathParameters['code']!),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/report',
            builder: (_, __) => const SafeVoiceStartScreen(),
            routes: [
              GoRoute(
                  path: 'incident',
                  builder: (_, __) => const IncidentScreen()),
              GoRoute(
                  path: 'details', builder: (_, __) => const DetailsScreen()),
              GoRoute(
                  path: 'privacy', builder: (_, __) => const PrivacyScreen()),
              GoRoute(
                path: 'receipt',
                builder: (_, state) {
                  final e = state.extra;
                  if (e is Map) {
                    return ReceiptScreen(
                      code: e['code'] as String?,
                      failedUploads: (e['failed'] as int?) ?? 0,
                    );
                  }
                  return ReceiptScreen(code: e is String ? e : null);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE9E3F5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Scaffold(
            backgroundColor: C.bg,
            body: shell,
            bottomNavigationBar: ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (_, lang, __) => NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) => shell.goBranch(i,
                    initialLocation: i == shell.currentIndex),
                destinations: [
                  NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: trFor(lang, 'Home')),
                  NavigationDestination(
                      icon: const Icon(Icons.explore_outlined),
                      selectedIcon: const Icon(Icons.explore),
                      label: trFor(lang, 'Explore')),
                  NavigationDestination(
                      icon: const Icon(Icons.shield_outlined),
                      selectedIcon: const Icon(Icons.shield),
                      label: trFor(lang, 'Report')),
                  NavigationDestination(
                      icon: const Icon(Icons.favorite_border),
                      selectedIcon: const Icon(Icons.favorite),
                      label: trFor(lang, 'Support')),
                  NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: trFor(lang, 'Profile')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
