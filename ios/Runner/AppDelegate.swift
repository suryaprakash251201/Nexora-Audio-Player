import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let equalizerBridge = IOSAudioEqualizerBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "nexora/equalizer",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "apply" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let enabled = arguments["enabled"] as? Bool,
            let frequencies = arguments["frequencies"] as? [NSNumber],
            let gains = arguments["gains"] as? [NSNumber] else {
        result(FlutterError(code: "INVALID_EQ", message: "Invalid EQ settings", details: nil))
        return
      }
      let applied = self?.equalizerBridge.apply(
        enabled: enabled,
        preamp: (arguments["preamp"] as? NSNumber)?.floatValue ?? 0,
        frequencies: frequencies.map { $0.floatValue },
        gains: gains.map { $0.floatValue }
      ) ?? false
      result(applied)
    }
  }
}

/// iOS EQ endpoint. Deliberately side-effect free: just_audio owns the
/// AVPlayer graph and the shared AVAudioSession, which also drives the
/// lock-screen / Control Center card (MPNowPlayingInfoCenter) and remote
/// commands. Touching the session here (category/activation) used to stall
/// lock-screen updates every time the EQ screen applied its curve, while
/// the standalone AVAudioEngine graph below was never connected to the
/// player output — pure harm, zero audible effect. So this validates the
/// payload, persists nothing, touches nothing, and reports unavailable so
/// Dart keeps the curve stored locally and stays honest in the UI.
private final class IOSAudioEqualizerBridge {
  @discardableResult
  func apply(enabled: Bool, preamp: Float, frequencies: [Float], gains: [Float]) -> Bool {
    guard !frequencies.isEmpty, frequencies.count == gains.count else { return false }
    // Real per-band DSP would require an MTAudioProcessingTap inside
    // just_audio's player pipeline — not something an app-side engine can
    // inject. Until such an integration point exists, report unavailable.
    return false
  }
}
