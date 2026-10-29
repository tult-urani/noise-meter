import 'dart:typed_data';

import 'package:flutter/services.dart';

class MicStartInfo {
  const MicStartInfo({required this.sampleRate, required this.audioSource});

  final double sampleRate;

  /// Platform capture path, e.g. `UNPROCESSED` or `measurement`.
  final String audioSource;
}

/// Raw microphone capture: mono float PCM in [−1, 1].
abstract interface class MicSource {
  Future<bool> requestPermission();

  /// Subscribe before calling [start]; chunks flow until [stop] or until the
  /// subscription is cancelled. Errors (e.g. an interruption) end the stream.
  Stream<Float32List> get samples;

  Future<MicStartInfo> start();

  Future<void> stop();

  Future<void> openSettings();
}

/// [MicSource] backed by the native capture code in the iOS and Android
/// runners (`MicStreamPlugin.swift`, `MicStreamHandler.kt`).
class PlatformMicSource implements MicSource {
  static const _methods = MethodChannel('vn.urani.noisemeter/mic');
  static const _events = EventChannel('vn.urani.noisemeter/mic/samples');

  @override
  late final Stream<Float32List> samples =
      _events.receiveBroadcastStream().map((chunk) => chunk as Float32List);

  @override
  Future<bool> requestPermission() async =>
      await _methods.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<MicStartInfo> start() async {
    final info = await _methods.invokeMapMethod<String, Object?>('start');
    if (info == null) {
      throw PlatformException(code: 'start_failed', message: 'No capture info');
    }
    return MicStartInfo(
      sampleRate: (info['sampleRate']! as num).toDouble(),
      audioSource: info['audioSource']! as String,
    );
  }

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<void> openSettings() => _methods.invokeMethod<void>('openSettings');
}
