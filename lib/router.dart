import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/physics.dart';
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
import 'features/settings/presentation/downloads_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/favorites/presentation/favorites_screen.dart';
import 'features/equalizer/presentation/equalizer_screen.dart';
import 'features/stats/presentation/stats_screen.dart';
import 'features/albums/presentation/album_detail_screen.dart';
import 'features/artists/presentation/artist_detail_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/player/providers/player_provider.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/sync/sync_manager.dart';
import 'domain/entities/album.dart';
import 'domain/entities/artist.dart';
import 'domain/entities/playlist.dart';
import 'ui/widgets/connectivity_banner.dart';
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
            path: '/album/:id',
            builder: (c, s) {
              final id = s.pathParameters['id']!;
              final extra = s.extra as Album?;
              return AlbumDetailScreen(albumId: id, initial: extra);
            },
          ),
          GoRoute(
            path: '/artist/:id',
            builder: (c, s) {
              final id = s.pathParameters['id']!;
              final extra = s.extra as Artist?;
              return ArtistDetailScreen(artistId: id, initial: extra);
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
          GoRoute(path: '/stats', builder: (c, s) => const StatsScreen()),
          GoRoute(
            path: '/downloads',
            builder: (c, s) => const DownloadsScreen(),
          ),
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

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  /// Whether the bottom nav bar is currently on screen.
  bool _navVisible = true;

  /// Spring-driven controllers for the nav bar slide & the mini-player
  /// reposition. Using a [SpringSimulation] gives the dock a physical
  /// feel that snaps in and settles rather than easing linearly.
  late final AnimationController _navController;
  late final AnimationController _miniController;

  bool _connectivityWired = false;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController.unbounded(vsync: this);
    _miniController = AnimationController.unbounded(vsync: this);

    // Drive both springs to their resting positions.
    _springTo(_navController, 0.0);
    _springTo(_miniController, 0.0);
  }

  /// Attach probe + reconnect exactly once (needs ref → post-frame).
  void _wireConnectivity() {
    if (_connectivityWired) return;
    _connectivityWired = true;
    final monitor = ref.read(connectivityMonitorProvider.notifier);
    monitor.attach(
      onProbe: () async {
        final r = await ref.read(apiClientProvider).ping();
        // null = no server configured → don't touch state.
        return r ?? true;
      },
      onReconnect: () async {
        // Flush offline mutations, then refresh caches so lists,
        // playlists, favorites and lyrics pick up server truth.
        try {
          await ref.read(syncManagerProvider).processSyncQueue();
        } catch (_) {}
        // Keep legacy compat provider in sync.
        try {
          ref.read(connectivityProvider.notifier).state =
              ConnectivityStatus.online;
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _navController.dispose();
    _miniController.dispose();
    super.dispose();
  }

  void _springTo(AnimationController c, double target) {
    final sim = SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 220.0, damping: 24.0),
      c.value,
      target,
      0,
    );
    c.animateWith(sim);
  }

  void _setNavVisible(bool v) {
    if (_navVisible == v) return;
    setState(() => _navVisible = v);
    // 0 = visible, 1 = hidden below the fold.
    _springTo(_navController, v ? 0.0 : 1.0);
    // Mini player slides up to fill the space the nav bar left behind.
    _springTo(_miniController, v ? 0.0 : 1.0);
  }

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
      if (!_navVisible) _setNavVisible(true);
      return false;
    }

    // Nothing to hand the space over to — keep the nav put.
    final hasTrack = ref.read(playerProvider).currentTrack != null;

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // Content moving up = user scrolling down the list.
        if (hasTrack && _navVisible && metrics.pixels > 40) {
          _setNavVisible(false);
        }
        break;
      case ScrollDirection.forward:
        // Content moving down = user scrolling back up.
        if (!_navVisible) _setNavVisible(true);
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
    final topInset = MediaQuery.viewPaddingOf(context).top;
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireConnectivity());
    // Mirror debounced state into the legacy provider for old watchers.
    ref.listen<ConnectivityState>(connectivityMonitorProvider, (prev, next) {
      try {
        ref.read(connectivityProvider.notifier).state = next.status;
      } catch (_) {}
      // Flush + refresh handled in onReconnect; the banner animates itself.
    });

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            child: widget.child,
          ),
          // Global offline / back-online banner (auto-hides).
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ConnectivityBanner(top: topInset),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomDock(
              navController: _navController,
              miniController: _miniController,
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

/// Bottom dock — floating aurora chrome, safe-area aware.
/// Mini player and nav bar share a single stack so they swap without overlap.
/// 2.0: 14px side margins, 12px bottom float, 10px inter-gap.
class _BottomDock extends StatelessWidget {
  final Animation<double> navController;
  final Animation<double> miniController;
  final double bottomInset;
  final Widget navBar;
  final VoidCallback onOpenPlayer;

  static const double _miniHeight = 70;
  static const double _gap = 8;
  static const double _hiddenOffset = 110;

  const _BottomDock({
    required this.navController,
    required this.miniController,
    required this.bottomInset,
    required this.navBar,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final navTotal = EnhancedGlassNavBar.totalHeight;
    // #4 FIX: hug the bottom edge — previously bottomInset+4 plus the
    // dock's own 12px margin left a dead band under Home/Search/Library.
    // iOS home-indicator area is already in bottomInset, so add nothing.
    final double dockBottom = bottomInset <= 0 ? 6 : bottomInset * 0.35;
    return Padding(
      padding: EdgeInsets.only(bottom: dockBottom),
      child: SizedBox(
        height: _miniHeight + navTotal + _gap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedBuilder(
              animation: miniController,
              builder: (context, child) {
                final t = miniController.value.clamp(0.0, 1.0);
                // When nav hidden, mini drops to 0; otherwise sits above nav.
                final bottom = lerpDouble(navTotal + _gap, 0, t);
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottom,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: child,
                    ),
                  ),
                );
              },
              child: MiniPlayer(onTap: onOpenPlayer),
            ),
            AnimatedBuilder(
              animation: navController,
              builder: (context, child) {
                final t = navController.value.clamp(0.0, 1.0);
                final opacity = t < 0.25
                    ? 1.0
                    : (1.0 - (t - 0.25) / 0.75).clamp(0.0, 1.0);
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: -_hiddenOffset * t,
                  child: IgnorePointer(
                    ignoring: t > 0.05,
                    child: Opacity(
                      opacity: opacity,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
              // #4: iOS frosted-glass ONLY around the nav bar.
              // Mini player above keeps its own Nexora glass untouched.
              child: _IosGlassNav(child: navBar),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style frosted glass wrapper — nav bar only.
/// Clip + backdrop blur + translucent tint + hairline border.
/// On Android the same layer reads as premium glass; on iOS it matches
/// the system tab-bar frost.
class _IosGlassNav extends StatelessWidget {
  final Widget child;
  const _IosGlassNav({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0C0F16).withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFF0F1D3A).withValues(alpha: 0.08),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Linear interpolation helper kept private to this file.
double lerpDouble(double a, double b, double t) => a + (b - a) * t;
