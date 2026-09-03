import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_flutter/core/download/download_manager.dart';
import 'package:nexora_flutter/core/utils/formatters.dart';
import 'package:nexora_flutter/data/dto/file_dto.dart';
import 'package:nexora_flutter/ui/widgets/track_menu_box.dart';

void main() {
  group('NexoraFiles.splitId', () {
    test('canonical root|path', () {
      final parts = NexoraFiles.splitId('root123|Music/Album/01 song.flac');
      expect(parts.root, 'root123');
      expect(parts.path, 'Music/Album/01 song.flac');
    });

    test('stream URL with query params', () {
      final parts = NexoraFiles.splitId(
        'https://music.example.com/api/v1/files/raw?root=root123&path=Music%2FAlbum%2F01%20song.flac&token=abc',
      );
      expect(parts.root, 'root123');
      expect(parts.path, 'Music/Album/01 song.flac');
    });

    test('garbage passes through for server-side 400', () {
      final parts = NexoraFiles.splitId('nonsense');
      expect(parts.root, 'nonsense');
      expect(parts.path, 'nonsense');
    });
  });

  group('DownloadManager.fileNameFor', () {
    test('strips separators so downloads never nest', () {
      final name = DownloadManager.fileNameFor(
        'root123|Music/Album/01 song.flac',
      );
      expect(name.contains('/'), isFalse);
      expect(name.contains('|'), isFalse);
      expect(name.endsWith('.mp3'), isTrue);
    });

    test('distinct ids stay distinct', () {
      final a = DownloadManager.fileNameFor('r|a/b.flac');
      final b = DownloadManager.fileNameFor('r|a_b.flac');
      expect(a == b, isFalse);
    });
  });

  group('formatters', () {
    test('formatFileSize scales to GB/TB', () {
      expect(formatFileSize(500), '500 B');
      expect(formatFileSize(2048), '2.0 KB');
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
      expect(formatFileSize(3 * 1024 * 1024 * 1024), '3.0 GB');
    });

    test('formatCount groups thousands', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1234567), '1,234,567');
    });
  });

  group('showTrackMenuBox', () {
    testWidgets('shows options and fires taps', (tester) async {
      var tapped = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTrackMenuBox(
                context: context,
                anchor: const Rect.fromLTWH(300, 400, 36, 36),
                options: [
                  TrackMenuOption(
                    icon: Icons.play_arrow_rounded,
                    label: 'Play next',
                    onTap: () => tapped = 'next',
                  ),
                  TrackMenuOption(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    onTap: () => tapped = 'download',
                  ),
                  TrackMenuOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    danger: true,
                    onTap: () => tapped = 'remove',
                  ),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Play next'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(tapped, 'download');
    });
  });
}
