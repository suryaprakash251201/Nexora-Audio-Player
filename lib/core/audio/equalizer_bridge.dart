import 'package:flutter/services.dart';

/// Sends the app EQ curve to the platform audio implementation when one is
/// available. Unsupported platforms simply keep the curve in app settings.
class EqualizerBridge {
  static const MethodChannel _channel = MethodChannel('nexora/equalizer');

  static Future<bool> apply({
    required bool enabled,
    required double preamp,
    required List<double> frequencies,
    required List<double> gains,
    int? audioSessionId,
  }) async {
    try {
      final arguments = <String, Object?>{
        'enabled': enabled,
        'preamp': preamp,
        'frequencies': frequencies,
        'gains': gains,
      };
      if (audioSessionId != null) {
        arguments['sessionId'] = audioSessionId;
      }
      final result = await _channel.invokeMethod<bool>('apply', arguments);
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
