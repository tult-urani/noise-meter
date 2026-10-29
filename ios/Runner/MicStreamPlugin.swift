import AVFoundation
import Flutter
import UIKit

/// Raw microphone capture for the Dart `PlatformMicSource`.
///
/// The session runs in `.measurement` mode, which disables the system's
/// automatic gain control and voice processing so levels stay linear.
final class MicStreamPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let methodChannelName = "vn.urani.noisemeter/mic"
  private static let eventChannelName = "vn.urani.noisemeter/mic/samples"
  private static let audioSourceName = "measurement"
  private static let preferredSampleRate = 48_000.0
  private static let tapBufferFrames: AVAudioFrameCount = 4096

  private let engine = AVAudioEngine()
  private var eventSink: FlutterEventSink?
  private var isCapturing = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MicStreamPlugin()
    let methods = FlutterMethodChannel(
      name: methodChannelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: eventChannelName, binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
    NotificationCenter.default.addObserver(
      instance,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance())
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      requestPermission(result)
    case "start":
      start(result)
    case "stop":
      do {
        try stopCapture()
        result(nil)
      } catch {
        result(FlutterError(code: "stop_failed", message: error.localizedDescription, details: nil))
      }
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    do {
      try stopCapture()
    } catch {
      return FlutterError(code: "stop_failed", message: error.localizedDescription, details: nil)
    }
    return nil
  }

  private func requestPermission(_ result: @escaping FlutterResult) {
    let reply: (Bool) -> Void = { granted in
      DispatchQueue.main.async { result(granted) }
    }
    if #available(iOS 17.0, *) {
      AVAudioApplication.requestRecordPermission(completionHandler: reply)
    } else {
      AVAudioSession.sharedInstance().requestRecordPermission(reply)
    }
  }

  private func start(_ result: @escaping FlutterResult) {
    do {
      if !isCapturing {
        try startCapture()
      }
      result([
        "sampleRate": engine.inputNode.outputFormat(forBus: 0).sampleRate,
        "audioSource": Self.audioSourceName,
      ])
    } catch {
      engine.inputNode.removeTap(onBus: 0)
      engine.stop()
      result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func startCapture() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: [])
    try session.setPreferredSampleRate(Self.preferredSampleRate)
    try session.setActive(true)

    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      throw NSError(
        domain: "MicStreamPlugin", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "No audio input available"])
    }
    input.installTap(onBus: 0, bufferSize: Self.tapBufferFrames, format: format) {
      [weak self] buffer, _ in
      self?.forward(buffer)
    }
    engine.prepare()
    try engine.start()
    isCapturing = true
  }

  private func stopCapture() throws {
    guard isCapturing else { return }
    isCapturing = false
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  /// Runs on the audio render thread; copies channel 0 and hops to main.
  private func forward(_ buffer: AVAudioPCMBuffer) {
    guard let channel = buffer.floatChannelData?[0] else { return }
    let data = Data(bytes: channel, count: Int(buffer.frameLength) * MemoryLayout<Float>.size)
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(FlutterStandardTypedData(float32: data))
    }
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard
      let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      AVAudioSession.InterruptionType(rawValue: rawType) == .began
    else { return }
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isCapturing else { return }
      // The system already deactivated the session; only the engine needs stopping.
      self.isCapturing = false
      self.engine.inputNode.removeTap(onBus: 0)
      self.engine.stop()
      self.eventSink?(
        FlutterError(
          code: "interrupted",
          message: "Interrupted by a call or another app",
          details: nil))
    }
  }
}
