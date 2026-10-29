import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/src/dsp/level_meter.dart';
import 'package:noisemeter/src/meter/meter_controller.dart';
import 'package:noisemeter/src/meter/noise_risk.dart';
import 'package:noisemeter/src/meter/sleep_rating.dart';

import '../dsp/signals.dart';
import 'fakes.dart';

void main() {
  late FakeMicSource mic;
  late MemoryCalibrationStore store;
  late MeterController controller;

  setUp(() {
    mic = FakeMicSource();
    store = MemoryCalibrationStore();
    controller = MeterController(mic: mic, calibrationStore: store);
  });

  tearDown(() => controller.dispose());

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('starts idle and uncalibrated', () async {
    await controller.load();
    expect(controller.status, MeterStatus.idle);
    expect(controller.isCalibrated, isFalse);
    expect(controller.calibrationOffsetDb, 0);
    expect(controller.latest, isNull);
  });

  test('measures after permission is granted', () async {
    await controller.start();
    expect(controller.status, MeterStatus.measuring);
    expect(controller.audioSource, 'FAKE');
    expect(controller.sampleRate, 48000);

    mic.emit(sine(frequency: 1000, amplitude: 1, sampleRate: 48000, seconds: 1));
    await pump();

    expect(controller.latest!.laf, closeTo(nominalFullScaleSineDbSpl, 0.1));
    expect(controller.history, hasLength(8));
  });

  test('denied permission never starts capture', () async {
    mic.permissionGranted = false;
    await controller.start();
    expect(controller.status, MeterStatus.permissionDenied);
    expect(mic.startCalls, 0);
    expect(mic.hasListener, isFalse);

    await controller.openSettings();
    expect(mic.openSettingsCalls, 1);
  });

  test('start failure surfaces the platform error code', () async {
    mic.startError = PlatformException(code: 'mic_busy', message: 'busy');
    await controller.start();
    expect(controller.status, MeterStatus.failed);
    expect(controller.errorCode, 'mic_busy');
    expect(mic.hasListener, isFalse);
  });

  test('stream error (e.g. interruption) stops the session', () async {
    await controller.start();
    mic.emit(sine(frequency: 1000, amplitude: 0.1, sampleRate: 48000, seconds: 0.5));
    await pump();
    mic.fail(PlatformException(code: 'interrupted', message: 'call'));
    await pump();

    expect(controller.status, MeterStatus.failed);
    expect(controller.errorCode, 'interrupted');
    expect(mic.hasListener, isFalse);
    expect(controller.latest, isNotNull, reason: 'last results stay visible');
  });

  test('stop keeps results; a new start begins a fresh session', () async {
    await controller.start();
    mic.emit(sine(frequency: 1000, amplitude: 1, sampleRate: 48000, seconds: 1));
    await pump();
    await controller.stop();

    expect(controller.status, MeterStatus.idle);
    expect(mic.stopCalls, 1);
    expect(mic.hasListener, isFalse);
    expect(controller.latest!.elapsed, const Duration(seconds: 1));

    await controller.start();
    expect(controller.latest, isNull);
    expect(controller.history, isEmpty);
    expect(controller.isClipping, isFalse);
  });

  test('overload warning clears 3 s after the last clipped sample', () async {
    await controller.start();
    final chunk = sine(frequency: 1000, amplitude: 0.1, sampleRate: 48000, seconds: 0.25);
    chunk[10] = 1.0;
    mic.emit(chunk);
    mic.emit(sine(frequency: 1000, amplitude: 0.1, sampleRate: 48000, seconds: 2.5));
    await pump();
    expect(controller.latest!.clipped, isFalse);
    expect(controller.isClipping, isTrue);

    mic.emit(sine(frequency: 1000, amplitude: 0.1, sampleRate: 48000, seconds: 0.5));
    await pump();
    expect(controller.isClipping, isFalse);

    // Clipping again brings it back; stopping hides it.
    mic.emit(chunk);
    await pump();
    expect(controller.isClipping, isTrue);
    await controller.stop();
    expect(controller.isClipping, isFalse);
  });

  test('history keeps only the last 60 s of readings', () async {
    await controller.start();
    for (var i = 0; i < 61; i++) {
      mic.emit(silence(sampleRate: 48000, seconds: 1));
    }
    await pump();
    expect(controller.history, hasLength(480));
  });

  test('calibration persists and applies to the live meter', () async {
    await controller.start();
    final signal = sine(frequency: 1000, amplitude: 1, sampleRate: 48000, seconds: 1);
    mic.emit(signal);
    await pump();
    final before = controller.latest!.laf;

    await controller.setCalibrationOffset(-2.5);
    mic.emit(signal);
    await pump();

    expect(store.offsetDb, -2.5);
    expect(controller.isCalibrated, isTrue);
    expect(controller.latest!.laf - before, closeTo(-2.5, 0.01));

    await controller.clearCalibration();
    expect(store.offsetDb, isNull);
    expect(controller.isCalibrated, isFalse);
    expect(controller.calibrationOffsetDb, 0);
  });

  test('load restores a saved calibration', () async {
    store.offsetDb = 4.2;
    await controller.load();
    expect(controller.isCalibrated, isTrue);
    expect(controller.calibrationOffsetDb, 4.2);
  });

  test('noise risk follows the energy average of the last 10 s', () async {
    // 1 kHz has 0 dB A-weighting, so a sine of this peak reads [levelDb].
    Float32List tone(double levelDb, double seconds) => sine(
          frequency: 1000,
          amplitude: math.pow(10, (levelDb - nominalFullScaleSineDbSpl) / 20).toDouble(),
          sampleRate: 48000,
          seconds: seconds,
        );

    await controller.start();
    expect(controller.recentLaeq, isNull);
    expect(controller.noiseRisk, isNull);

    mic.emit(tone(90, 12));
    await pump();
    expect(controller.recentLaeq, closeTo(90, 0.1));
    expect(controller.noiseRisk, NoiseRisk.hearingDamage);

    // Half the window at 90 dB, half at 60 dB: energy mean ≈ 90 − 3 dB.
    mic.emit(tone(60, 5));
    await pump();
    expect(controller.recentLaeq, closeTo(87, 0.3));
    expect(controller.noiseRisk, NoiseRisk.hearingDamage);

    mic.emit(tone(60, 6));
    await pump();
    expect(controller.recentLaeq, closeTo(60, 0.1));
    expect(controller.noiseRisk, NoiseRisk.annoying);
  });

  test('sleep mode rates the recent level and counts loud events', () async {
    Float32List tone(double levelDb, double seconds) => sine(
          frequency: 1000,
          amplitude: math.pow(10, (levelDb - nominalFullScaleSineDbSpl) / 20).toDouble(),
          sampleRate: 48000,
          seconds: seconds,
        );

    var notified = 0;
    controller.addListener(() => notified++);
    controller.setMode(AssessmentMode.sleep);
    expect(controller.mode, AssessmentMode.sleep);
    expect(notified, 1);
    controller.setMode(AssessmentMode.sleep);
    expect(notified, 1);

    await controller.start();
    mic.emit(tone(30, 12));
    await pump();
    expect(controller.sleepRating, SleepRating.good);
    expect(controller.sleepEventCount, 0);

    for (var i = 0; i < 3; i++) {
      mic.emit(tone(60, 1));
      mic.emit(tone(30, 2));
    }
    await pump();
    expect(controller.sleepEventCount, 3);

    mic.emit(tone(50, 12));
    await pump();
    expect(controller.sleepRating, SleepRating.poor);

    // A new session starts the event count again.
    await controller.stop();
    await controller.start();
    expect(controller.sleepEventCount, 0);
    expect(controller.mode, AssessmentMode.sleep);
  });
}
