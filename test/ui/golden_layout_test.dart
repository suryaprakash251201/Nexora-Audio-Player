import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_flutter/ui/nexora/nexora_artwork.dart';
import 'package:nexora_flutter/ui/nexora/nexora_page_header.dart';
import 'package:nexora_flutter/ui/nexora/nexora_primitives.dart';
import 'package:nexora_flutter/ui/nexora/nexora_rows.dart';
import 'package:nexora_flutter/ui/theme.dart';
import 'package:nexora_flutter/ui/widgets/error_view.dart';

/// Responsive layout verification for the two reference viewports:
///  - 360×640 (small / SE-class)
///  - 412×915 (Pixel-class)
///
/// Pumped in both dark and light modes. These are deterministic
/// widget-layout tests (no network, no goldens checked in): they assert
/// the canonical components render without overflow at each size/mode
/// and share one empty-state implementation.
void main() {
  // Reference viewports: (label, logical size).
  const viewports = {'360x640': Size(360, 640), '412x915': Size(412, 915)};
  const modes = {'dark': AppThemeMode.dark, 'light': AppThemeMode.light};

  tearDown(() {
    // Global palette back to default; viewport size is reset per-test
    // via addTearDown(tester.view.reset…) inside each case.
    AppColors.mode = AppThemeMode.dark;
  });

  Widget wrap(Widget child, AppThemeMode mode) {
    AppColors.mode = mode;
    return MaterialApp(
      theme: AppTheme.themeFor(mode),
      home: Scaffold(backgroundColor: AppColors.background, body: child),
    );
  }

  void setViewport(WidgetTester tester, Size logical) {
    tester.view.physicalSize = Size(logical.width, logical.height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  for (final vp in viewports.entries) {
    for (final m in modes.entries) {
      final label = '${vp.key} ${m.key}';

      testWidgets('$label – page header renders without overflow', (
        tester,
      ) async {
        setViewport(tester, vp.value);
        await tester.pumpWidget(
          wrap(
            const SafeArea(
              child: Column(
                children: [
                  NexoraPageHeader(
                    title: 'Library',
                    subtitle: 'Your collection, organized.',
                  ),
                ],
              ),
            ),
            m.value,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Library'), findsOneWidget);
        expect(find.text('Your collection, organized.'), findsOneWidget);
        // 32px extrabold title rhythm.
        final title = tester.widget<Text>(find.text('Library'));
        expect(title.style?.fontSize, 32);
        expect(title.style?.fontWeight, FontWeight.w800);
      });

      testWidgets('$label – track row renders without overflow', (
        tester,
      ) async {
        setViewport(tester, vp.value);
        await tester.pumpWidget(
          wrap(
            SafeArea(
              child: ListView(
                children: const [
                  NexoraTrackRow(
                    artworkUrl: null,
                    title: 'Midnight Aurora',
                    subtitle: 'Nexora Ensemble • Dreamscape',
                    duration: '4:12',
                    indexLabel: '01',
                  ),
                  NexoraTrackRow(
                    artworkUrl: null,
                    title: 'Glasswing',
                    subtitle: 'Unknown • Unknown Album',
                    duration: '3:05',
                    indexLabel: '02',
                    isCurrent: true,
                    isPlaying: true,
                    isFavorite: true,
                    isDownloaded: true,
                  ),
                ],
              ),
            ),
            m.value,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Midnight Aurora'), findsOneWidget);
        expect(find.text('Glasswing'), findsOneWidget);
      });

      testWidgets('$label – empty states share one implementation', (
        tester,
      ) async {
        setViewport(tester, vp.value);
        await tester.pumpWidget(
          wrap(
            const SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Centered full-page variant (both names).
                  NexoraEmptyState(
                    icon: Icons.queue_music_outlined,
                    title: 'No playlists yet',
                    subtitle: 'Create one from the Playlists tab',
                  ),
                  EmptyView(
                    icon: Icons.music_note_outlined,
                    title: 'No songs yet',
                    subtitle: 'Check your server connection',
                  ),
                  // Compact inline rail hint.
                  EmptyView(
                    icon: Icons.folder_outlined,
                    title: 'No folders yet',
                    compact: true,
                  ),
                ],
              ),
            ),
            m.value,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('No playlists yet'), findsOneWidget);
        expect(find.text('No songs yet'), findsOneWidget);
        expect(find.text('No folders yet'), findsOneWidget);
      });

      testWidgets('$label – artwork placeholder renders without overflow', (
        tester,
      ) async {
        setViewport(tester, vp.value);
        await tester.pumpWidget(
          wrap(
            const SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NexoraArtwork(url: null, size: 140),
                  SizedBox(width: 12),
                  NexoraArtwork(
                    url: null,
                    size: 96,
                    radius: BorderRadius.zero,
                    placeholderIcon: Icons.person_rounded,
                  ),
                ],
              ),
            ),
            m.value,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      });
    }
  }
}
