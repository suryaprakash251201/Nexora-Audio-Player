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
import 'features/sharing/shares_screen.dart';
import 'features/tags/tags_screen.dart';
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
          GoRoute(path: '/shares', builder: (c, s) => const SharesScreen()),
          GoRoute(path: '/tags', builder: (c, s) => const TagsScreen()),
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
  /// Whether the mini player is currently on screen.
  /// The nav bar stays pinned to the bottom edge at all times.
  bool _miniVisible = true;

  /// Spring-driven controller for the mini-player slide & fade.
  /// Using a [SpringSimulation] gives the dock a physical
  /// feel that snaps in and settles rather than easing linearly.
  late final AnimationController _miniController;

  bool _connectivityWired = false;

  @override
  void initState() {
    super.initState();
    _miniController = AnimationController.unbounded(vsync: this);

    // Drive the spring to its resting position.
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

  void _setMiniVisible(bool v) {
    if (_miniVisible == v) return;
    setState(() => _miniVisible = v);
    // 0 = visible, 1 = hidden behind the pinned nav bar.
    // The nav bar never moves; the mini player slides away beneath it.
    _springTo(_miniController, v ? 0.0 : 1.0);
  }

  int _indexForLocation(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/library')) return 2;
    if (loc.startsWith('/playlists')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  /// Scroll-direction driven mini-player visibility:
  ///  • scrolling down  → mini slides away behind the pinned nav bar
  ///  • scrolling up    → mini returns above the nav bar
  bool _onUserScroll(UserScrollNotification notification) {
    final metrics = notification.metrics;

    // Always reveal the mini player once we are back at the very top.
    if (metrics.pixels <= metrics.minScrollExtent + 1) {
      if (!_miniVisible) _setMiniVisible(true);
      return false;
    }

    // Nothing to hand the space over to — keep the mini put.
    final hasTrack = ref.read(playerProvider).currentTrack != null;

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // Content moving up = user scrolling down the list.
        if (hasTrack && _miniVisible && metrics.pixels > 40) {
          _setMiniVisible(false);
        }
        break;
      case ScrollDirection.forward:
        // Content moving down = user scrolling back up.
        if (!_miniVisible) _setMiniVisible(true);
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

/// Bottom dock — nav bar pinned to the bottom edge, mini player above it.
///
/// Standard pattern: `[content] / [mini card] / [nav at system edge]`.
/// The nav never moves; on scroll-down the mini slides down behind the nav.
class _BottomDock extends ConsumerWidget {
  final Animation<double> miniController;
  final double bottomInset;
  final Widget navBar;
  final VoidCallback onOpenPlayer;

  static const double _miniHeight = 68;
  static const double _gap = 8;
  static const double _navContentHeight = 68;
  static const double _navTopPad = 8;
  static const double _hiddenOffset = 96;

  const _BottomDock({
    required this.miniController,
    required this.bottomInset,
    required this.navBar,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collapse the reserved space when nothing is playing so lists can
    // use the full height instead of leaving a transparent hole.
    final hasTrack = ref.watch(
      playerProvider.select((s) => s.currentTrack != null),
    );
    final double navTotal = _navContentHeight + _navTopPad;
    final double dockHeight =
        navTotal + bottomInset + (hasTrack ? _miniHeight + _gap : 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: dockHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Mini player — floats above the nav, hides behind it on scroll.
          AnimatedBuilder(
            animation: miniController,
            builder: (context, child) {
              final t = miniController.value.clamp(0.0, 1.0);
              final opacity = t < 0.25
                  ? 1.0
                  : (1.0 - (t - 0.25) / 0.75).clamp(0.0, 1.0);
              return Positioned(
                left: 0,
                right: 0,
                bottom: navTotal + bottomInset + _gap - _hiddenOffset * t,
                child: IgnorePointer(
                  ignoring: t > 0.05 || !hasTrack,
                  child: Opacity(
                    opacity: hasTrack ? opacity : 0.0,
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
            child: MiniPlayer(onTap: onOpenPlayer),
          ),
          // Nav — pinned to the very bottom, full-bleed frost.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _IosGlassNav(
              bottomInset: bottomInset,
              topPad: _navTopPad,
              child: navBar,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style frosted glass wrapper — nav bar only, pinned to bottom edge.
/// Full-bleed blur with rounded top corners; frost extends behind the
/// home indicator via [bottomInset]. Inner content stays centered
/// (maxWidth 640) so tablets don't stretch.
class _IosGlassNav extends StatelessWidget {
  final Widget child;
  final double bottomInset;
  final double topPad;
  const _IosGlassNav({
    required this.child,
    required this.bottomInset,
    this.topPad = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0C0F16).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFF0F1D3A).withValues(alpha: 0.08),
                width: 0.8,
              ),
              left: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFF0F1D3A).withValues(alpha: 0.04),
                width: 0.8,
              ),
              right: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFF0F1D3A).withValues(alpha: 0.04),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, topPad, 12, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
