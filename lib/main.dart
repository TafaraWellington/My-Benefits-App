import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

import 'features/search/screens/search_screen.dart';
import 'features/sassa/screens/sassa_screen.dart';
import 'features/raf/screens/raf_screen.dart';
import 'features/documents/screens/document_vault_screen.dart';
import 'features/nsfas/screens/nsfas_screen.dart';

import 'features/home/screens/home_screen.dart';
import 'features/home/screens/security_settings_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'core/services/background_service.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService.init();
  await SupabaseService.init();

  runApp(const ProviderScope(child: SABenefitsApp()));
}

class SABenefitsApp extends StatelessWidget {
  const SABenefitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SA Benefits',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Global Key for Navigation
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

class SupabaseAuthRepository extends ChangeNotifier {
  SupabaseAuthRepository() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

final authRepositoryProvider = Provider((ref) => SupabaseAuthRepository());

// Router Configuration
final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final supabase = Supabase.instance.client;
    final loggedIn = supabase.auth.currentSession != null;
    final loggingIn = state.uri.path == '/login';

    // Protected routes that require authentication
    final protectedRoutes = ['/documents', '/security', '/profile'];
    final isAccessingProtected = protectedRoutes.contains(state.uri.path);

    if (!loggedIn && isAccessingProtected) return '/login';
    if (loggedIn && loggingIn) return '/';
    return null;
  },
  refreshListenable: SupabaseAuthRepository(),
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => RootNavigationScreen(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/sassa',
          builder: (context, state) => const SassaScreen(),
        ),
        GoRoute(path: '/raf', builder: (context, state) => const RafScreen()),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentVaultScreen(),
        ),
        GoRoute(
          path: '/nsfas',
          builder: (context, state) => const NsfasScreen(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecuritySettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

class RootNavigationScreen extends StatelessWidget {
  final Widget child;
  const RootNavigationScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location == '/search' || location == '/sassa' || location == '/raf' || location == '/nsfas') return 1;
    if (location == '/documents') return 2;
    if (location == '/notifications') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/documents');
        break;
      case 3:
        // context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.accent.withOpacity(0.1), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Benefits',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
