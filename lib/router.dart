import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/server_config_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/playlists/presentation/playlists_screen.dart';
import 'features/playlists/presentation/playlist_detail_screen.dart';
import 'features/library/presentation/folder_browser_screen.dart';
import 'features/player/presentation/full_player_screen.dart';
import 'features/player/presentation/mini_player.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/favorites/presentation/favorites_screen.dart';
import 'features/equalizer/presentation/equalizer_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/player/providers/player_provider.dart';
import 'domain/entities/playlist.dart';
import 'ui/widgets/enhanced_player_widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth.value != null;
      final isLoading = auth.isLoading;
      if (isLoading) return null;
      final loc = state.matchedLocation;
      final isLogin = loc == '/login';
      final isServerSetup = loc == '/server-setup';
      if (!isLoggedIn && !isLogin && !isServerSetup) return '/login';
      if (isLoggedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: (ctx, a, sa, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/server-setup',
        pageBuilder: (c, s) => CustomTransitionPage(
          child: const ServerConfigScreen(),
          transitionsBuilder: (ctx, a, sa, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: LibraryScreen()),
          ),
          GoRoute(
            path: '/playlists',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: PlaylistsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/playlists/:id',
            builder: (c, s) {
              final id = s.pathParameters['id']!;
              final extra = s.extra as Playlist?;
              return PlaylistDetailScreen(playlistId: id, initial: extra);
            },
          ),
          GoRoute(
            path: '/folder',
            builder: (c, s) {
              final rootId =
                  s.uri.queryParameters['root'] ??
                  'root_c617a9424d30516f12d802a3';
              final path = s.uri.queryParameters['path'] ?? '';
              return FolderBrowserScreen(rootId: rootId, path: path);
            },
          ),
          GoRoute(
            path: '/favorites',
            builder: (c, s) => const FavoritesScreen(),
          ),
          GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
          GoRoute(
            path: '/equalizer',
            builder: (c, s) => const EqualizerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (c, s) => CustomTransitionPage(
          child: const FullPlayerScreen(),
          transitionsBuilder: (ctx, a, sa, child) {
            return SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});

// Backwards compatibility for existing main.dart that imports `router`
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
  ],
);

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Whether the bottom nav bar is currently on screen.
  bool _navVisible = true;

  int _indexForLocation(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/library')) return 2;
    if (loc.startsWith('/playlists')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  /// Scroll-direction driven nav visibility:
  ///  • scrolling down  → nav slides away, mini player drops into its place
  ///  • scrolling up    → nav returns, mini player lifts above it
  bool _onUserScroll(UserScrollNotification notification) {
    final metrics = notification.metrics;

    // Always reveal the bar once we are back at the very top.
    if (metrics.pixels <= metrics.minScrollExtent + 1) {
      if (!_navVisible) setState(() => _navVisible = true);
      return false;
    }

    // Nothing to hand the space over to — keep the nav put.
    final hasTrack = ref.read(playerProvider).currentTrack != null;

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // Content moving up = user scrolling down the list.
        if (hasTrack && _navVisible && metrics.pixels > 40) {
          setState(() => _navVisible = false);
        }
        break;
      case ScrollDirection.forward:
        // Content moving down = user scrolling back up.
        if (!_navVisible) setState(() => _navVisible = true);
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  void _onSelect(int i) {
    switch (i) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/library');
        break;
      case 3:
        context.go('/playlists');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _indexForLocation(location);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            child: widget.child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomDock(
              navVisible: _navVisible,
              bottomInset: bottomInset,
              navBar: EnhancedGlassNavBar(
                selectedIndex: idx,
                onSelect: _onSelect,
              ),
              onOpenPlayer: () => context.push('/player'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom overlay that cross-fades/repositions the mini player and the nav bar
/// so they swap places as the user scrolls. Both are centered and share the
/// same horizontal constraints; the bar sits slightly lower near the edge.
class _BottomDock extends StatelessWidget {
  final bool navVisible;
  final double bottomInset;
  final Widget navBar;
  final VoidCallback onOpenPlayer;

  // Mini player visual height (card + progress)
  static const double _miniHeight = 72;
  static const double _gap = 8;

  const _BottomDock({
    required this.navVisible,
    required this.bottomInset,
    required this.navBar,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final navTotal = EnhancedGlassNavBar.totalHeight;
    // Small extra inset so the dock breathes but stays low.
    final double dockBottom = bottomInset > 0 ? bottomInset + 2 : 4;
    return Padding(
      padding: EdgeInsets.only(bottom: dockBottom),
      child: SizedBox(
        height: _miniHeight + navTotal + _gap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Mini player: centered, same width logic as nav bar (14px margins
            // inside the card). Sits above nav when visible, drops into nav's
            // slot when nav is hidden.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: navVisible ? navTotal + _gap : 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: MiniPlayer(onTap: onOpenPlayer),
                ),
              ),
            ),
            // Nav bar: centered, slides below the fold when hidden.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: navVisible ? 0 : -navTotal - 12,
              child: IgnorePointer(
                ignoring: !navVisible,
                child: AnimatedOpacity(
                  opacity: navVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: navBar,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
