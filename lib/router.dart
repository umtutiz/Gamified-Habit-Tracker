import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/activities/activities_screen.dart';
import 'features/activities/add_activity_screen.dart';
import 'features/activities/activity_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/marathon/marathon_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/activities',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggingIn =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (session == null) {
        return loggingIn ? null : '/login';
      } else {
        return loggingIn ? '/activities' : null;
      }
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text(
          'No route for ${state.uri}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Bottom-nav root (shell)
      ShellRoute(
        builder: (context, state, child) {
          return HomeShell(child: child);
        },
        routes: [
          GoRoute(
            name: 'activities',
            path: '/activities',
            builder: (context, state) => const ActivitiesScreen(),
            routes: [
              GoRoute(
                name: 'add_activity',
                path: 'new',
                builder: (context, state) => const AddActivityScreen(),
              ),
              GoRoute(
                name: 'activity_detail',
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ActivityDetailScreen(activityId: id);
                },
              ),
            ],
          ),
          GoRoute(
            name: 'marathon',
            path: '/marathon',
            builder: (context, state) => const MarathonScreen(),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Auth değişince router refresh olsun diye
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Alt menü + ortak AppBar istersen burada
class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/activities')) return 0;
    if (location.startsWith('/marathon')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _indexForLocation(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/activities');
              break;
            case 1:
              context.go('/marathon');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Kişisel',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Maraton',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}