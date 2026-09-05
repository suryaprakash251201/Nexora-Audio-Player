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
import 'features/home/providers/home_provider.dart';
import 'core/audio/audio_handler.dart';
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
  /// Whether the whole bottom dock (mini + nav) is currently on screen.
  /// Scroll down → dock slides away together. Scroll up / top → returns.
  bool _dockVisible = true;

  /// Spring-driven controller for the dock slide & fade.
  /// 0 = visible, 1 = hidden below the screen edge.
  /// Using a [SpringSimulation] gives the dock a physical
  /// feel that snaps in and settles rather than easing linearly.
  late final AnimationController _dockController;

  bool _connectivityWired = false;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _dockController = AnimationController.unbounded(vsync: this);

    // Drive the spring to its resting position.
    _springTo(_dockController, 0.0);
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
      onOffline: () async {
        // No internet: stop playback right away (keeps queue, track and
        // position so the song can auto-resume when the internet returns).
        try {
          await ref.read(audioHandlerProvider).pauseForNetworkLoss();
        } catch (_) {}
      },
      onReconnect: () async {
        // Flush offline mutations, then refresh caches so lists,
        // playlists, favorites and lyrics pick up server truth.
        try {
          await ref.read(syncManagerProvider).processSyncQueue();
        } catch (_) {}
        // Auto-fetch fresh server data everywhere.
        _refreshAfterReconnect();
        // Internet is back: auto-resume the song that was interrupted
        // (re-fetches the queue / stream URLs and plays from the saved
        // position).
        try {
          await ref.read(audioHandlerProvider).resumeAfterNetworkRestore();
        } catch (_) {}
        // Keep legacy compat provider in sync.
        try {
          ref.read(connectivityProvider.notifier).state =
              ConnectivityStatus.online;
        } catch (_) {}
      },
    );
  }

  /// Re-fetch all home-screen server data after the connection returns.
  void _refreshAfterReconnect() {
    try {
      ref.invalidate(recentSongsProvider);
      ref.invalidate(homePlaylistsProvider);
      ref.invalidate(recentlyPlayedProvider);
      ref.invalidate(favoritesProvider);
      ref.invalidate(featuredAlbumsProvider);
      ref.invalidate(featuredArtistsProvider);
    } catch (_) {}
  }

  @override
  void dispose() {
    _dockController.dispose();
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

  void _setDockVisible(bool v) {
    if (_dockVisible == v) return;
    setState(() => _dockVisible = v);
    // 0 = visible, 1 = hidden below the screen edge.
    // Mini + nav move together as one floating dock — the mini never
    // slides behind / into the nav bar.
    _springTo(_dockController, v ? 0.0 : 1.0);
  }

  int _indexForLocation(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/library')) return 2;
    if (loc.startsWith('/playlists')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  /// Scroll-direction driven dock visibility:
  ///  • scrolling down  → whole dock (mini + nav) slides away together
  ///  • scrolling up    → whole dock returns together
  /// The mini never moves relative to the nav, so it can't overlap it.
  bool _onUserScroll(UserScrollNotification notification) {
    final metrics = notification.metrics;

    // Always reveal the dock once we are back at the very top.
    if (metrics.pixels <= metrics.minScrollExtent + 1) {
      if (!_dockVisible) _setDockVisible(true);
      return false;
    }

    switch (notification.direction) {
      case ScrollDirection.reverse:
        // Content moving up = user scrolling down the list.
        if (_dockVisible && metrics.pixels > 60) {
          _setDockVisible(false);
        }
        break;
      case ScrollDirection.forward:
        // Content moving down = user scrolling back up.
        if (!_dockVisible) _setDockVisible(true);
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  void _onSelect(int i) {
    // Always bring the dock back when switching tabs.
    if (!_dockVisible) _setDockVisible(true);
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
    // New route (tab switch / push) → reveal dock so it never stays
    // hidden on a fresh list.
    if (_lastLocation != location) {
      _lastLocation = location;
      if (!_dockVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _setDockVisible(true);
        });
      }
    }
    // Mirror debounced state into the legacy provider for old watchers.
    ref.listen<ConnectivityState>(connectivityMonitorProvider, (prev, next) {
      try {
        ref.read(connectivityProvider.notifier).state = next.status;
      } catch (_) {}
      // Flush + refresh handled in onReconnect; the banner animates itself.
    });

    return Scaffold(
      extendBody: true,
      // The dock must stay pinned to the physical bottom edge. If the
      // Scaffold resized for the keyboard (search input), the nav bar
      // would float above it leaving a visible gap below.
      resizeToAvoidBottomInset: false,
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
              dockController: _dockController,
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

/// Bottom dock — floating rounded mini + floating rounded nav.
///
/// Pattern: `[content] / [floating mini card] / [floating rounded nav]`.
/// No full-bleed background — only two rounded glass pills are visible.
/// On scroll-down the whole dock slides down off-screen together;
/// on scroll-up it returns together. Mini never moves relative to nav,
/// so it can't slide into / behind the nav bar.
class _BottomDock extends ConsumerWidget {
  final Animation<double> dockController;
  final double bottomInset;
  final Widget navBar;
  final VoidCallback onOpenPlayer;

  static const double _miniHeight = 68;
  static const double _gap = 8;
  static const double _navHeight = 68;
  static const double _sideMargin = 12;
  static const double _bottomMargin = 12;

  const _BottomDock({
    required this.dockController,
    required this.bottomInset,
    required this.navBar,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrack = ref.watch(
      playerProvider.select((s) => s.currentTrack != null),
    );
    // Estimated dock height for the hide translation distance.
    final double dockHeight =
        _navHeight +
        (hasTrack ? _miniHeight + _gap : 0) +
        bottomInset +
        _bottomMargin +
        24;

    return AnimatedBuilder(
      animation: dockController,
      builder: (context, child) {
        final t = dockController.value.clamp(0.0, 1.0);
        final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, dockHeight * t),
          child: Opacity(
            opacity: opacity,
            child: IgnorePointer(ignoring: t > 0.15, child: child),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _sideMargin,
          0,
          _sideMargin,
          bottomInset + _bottomMargin,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasTrack) ...[
                    MiniPlayer(onTap: onOpenPlayer),
                    const SizedBox(height: _gap),
                  ],
                  // Floating rounded nav — the only nav background.
                  navBar,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
