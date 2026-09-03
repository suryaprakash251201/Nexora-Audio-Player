import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora_flutter/core/audio/audio_handler.dart';
import 'package:nexora_flutter/features/equalizer/presentation/equalizer_screen.dart';

Widget _wrap() => ProviderScope(
  overrides: [audioHandlerProvider.overrideWithValue(NexoraAudioHandler())],
  child: const MaterialApp(home: EqualizerScreen()),
);

void main() {
  testWidgets('EQ renders immediately with saved curve', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.eq_enabled': true,
      'flutter.eq_preamp': 2.0,
      'flutter.eq_bands_5_android': '1.0,2.0,0.0,-1.0,3.0',
    });
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Equalizer'), findsOneWidget);
    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('BANDS'), findsOneWidget);
  });

  testWidgets('EQ renders content even when prefs hang', (tester) async {
    // No mock values: on platforms without the prefs plugin the load
    // never resolves — the screen must still show its UI, never a
    // bare spinner.
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('Equalizer'), findsOneWidget);
    expect(find.text('PRESETS'), findsOneWidget); // header uppercases
  });
}
