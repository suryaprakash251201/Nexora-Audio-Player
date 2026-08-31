import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_flutter/main.dart';
import 'package:nexora_flutter/core/audio/audio_handler.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    final handler = NexoraAudioHandler();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [audioHandlerProvider.overrideWithValue(handler)],
        child: const NexoraApp(),
      ),
    );
    expect(find.text('Nexora'), findsWidgets);
  });
}
