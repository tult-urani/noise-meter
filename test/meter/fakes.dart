import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:noisemeter/src/audio/mic_source.dart';
import 'package:noisemeter/src/meter/calibration_store.dart';
import 'package:noisemeter/src/settings/language_controller.dart';

class FakeMicSource implements MicSource {
  FakeMicSource({this.permissionGranted = true, this.startError});

  bool permissionGranted;
  PlatformException? startError;
  int startCalls = 0;
  int stopCalls = 0;
  int openSettingsCalls = 0;

  final _controller = StreamController<Float32List>.broadcast();

  bool get hasListener => _controller.hasListener;

  void emit(Float32List chunk) => _controller.add(chunk);

  void fail(PlatformException error) => _controller.addError(error);

  @override
  Stream<Float32List> get samples => _controller.stream;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<MicStartInfo> start() async {
    startCalls++;
    final error = startError;
    if (error != null) throw error;
    return const MicStartInfo(sampleRate: 48000, audioSource: 'FAKE');
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> openSettings() async => openSettingsCalls++;
}

class MemoryCalibrationStore implements CalibrationStore {
  MemoryCalibrationStore([this.offsetDb]);

  double? offsetDb;

  @override
  Future<double?> loadOffsetDb() async => offsetDb;

  @override
  Future<void> saveOffsetDb(double offsetDb) async => this.offsetDb = offsetDb;

  @override
  Future<void> clear() async => offsetDb = null;
}

class MemoryLanguageStore implements LanguageStore {
  MemoryLanguageStore([this.code]);

  String? code;

  @override
  Future<String?> loadLanguageCode() async => code;

  @override
  Future<void> saveLanguageCode(String code) async => this.code = code;
}
