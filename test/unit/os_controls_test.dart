import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_flutter/core/audio/audio_handler.dart';

/// Pins the OS media-control contract for lock screen / notification
/// center / Control Center:
///
/// - Previous + Next track buttons MUST be advertised.
/// - No ±seconds interval-skip (rewind / fastForward / seekForward /
///   seekBackward) — on iOS those surface as skip buttons that displace
///   prev/next.
/// - Compact notification slots must be prev / play-pause / next.
void main() {
  Set<MediaAction> actions({required bool playing}) =>
      NexoraAudioHandler.osControls(
        playing: playing,
      ).map((c) => c.action).toSet();

  test('osControls advertises prev/next, never interval-skip', () {
    for (final playing in [true, false]) {
      final a = actions(playing: playing);
      expect(a, contains(MediaAction.skipToPrevious));
      expect(a, contains(MediaAction.skipToNext));
      expect(a, isNot(contains(MediaAction.rewind)));
      expect(a, isNot(contains(MediaAction.fastForward)));
    }
  });

  test('osControls toggles play/pause with playback state', () {
    expect(actions(playing: true), contains(MediaAction.pause));
    expect(actions(playing: true), isNot(contains(MediaAction.play)));
    expect(actions(playing: false), contains(MediaAction.play));
    expect(actions(playing: false), isNot(contains(MediaAction.pause)));
  });

  test('osSystemActions is seek-only (scrubber, no skip commands)', () {
    expect(NexoraAudioHandler.osSystemActions, contains(MediaAction.seek));
    expect(
      NexoraAudioHandler.osSystemActions,
      isNot(contains(MediaAction.seekForward)),
    );
    expect(
      NexoraAudioHandler.osSystemActions,
      isNot(contains(MediaAction.seekBackward)),
    );
  });

  test('osCompactIndices point at prev / play-pause / next', () {
    final controls = NexoraAudioHandler.osControls(playing: true);
    final compact = NexoraAudioHandler.osCompactIndices;
    expect(compact, [0, 1, 3]);
    for (final i in compact) {
      expect(i, inInclusiveRange(0, controls.length - 1));
    }
    expect(controls[compact[0]].action, MediaAction.skipToPrevious);
    expect(controls[compact[1]].action, MediaAction.pause);
    expect(controls[compact[2]].action, MediaAction.skipToNext);
  });
}
