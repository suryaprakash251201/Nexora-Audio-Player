import AVFoundation
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

private final class IOSAudioEqualizerBridge {
  private let audioEngine = AVAudioEngine()
  private var equalizer: AVAudioUnitEQ?

  @discardableResult
  func apply(enabled: Bool, preamp: Float, frequencies: [Float], gains: [Float]) -> Bool {
    guard !frequencies.isEmpty, frequencies.count == gains.count else { return false }
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try? session.setActive(true)

    if equalizer?.bands.count != frequencies.count {
      if let oldEqualizer = equalizer {
        audioEngine.detach(oldEqualizer)
      }
      let newEqualizer = AVAudioUnitEQ(numberOfBands: frequencies.count)
      audioEngine.attach(newEqualizer)
      equalizer = newEqualizer
    }
    guard let equalizer else { return false }

    for (index, frequency) in frequencies.enumerated() {
      let band = equalizer.bands[index]
      band.filterType = .parametric
      band.frequency = frequency
      band.gain = gains[index]
      band.bandwidth = 1.0
      band.bypass = !enabled
    }
    equalizer.globalGain = preamp
    equalizer.bypass = !enabled

    // just_audio owns its playback graph. This standalone engine graph is
    // configured safely, but is not connected to just_audio's output, so this
    // cannot claim to DSP just_audio audio without an engine integration point.
    return false
  }
}
