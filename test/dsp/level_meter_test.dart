import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/src/dsp/level_meter.dart';

import 'signals.dart';

const _fs = 48000.0;

List<LevelReading> _run(LevelMeter meter, Float32List samples, {int chunk = 4096}) {
  final readings = <LevelReading>[];
  for (var start = 0; start < samples.length; start += chunk) {
    final end = math.min(start + chunk, samples.length);
    readings.addAll(meter.process(Float32List.sublistView(samples, start, end)));
  }
  return readings;
}

double _log10(double x) => math.log(x) / math.ln10;

void main() {
  test('a full-scale 1 kHz sine reads the nominal full-scale level', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 2),
    );
    expect(readings.last.laf, closeTo(nominalFullScaleSineDbSpl, 0.05));
    expect(readings.last.laeq, closeTo(nominalFullScaleSineDbSpl, 0.05));
  });

  test('levels scale 20 dB per decade of amplitude', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      sine(frequency: 1000, amplitude: 0.01, sampleRate: _fs, seconds: 2),
    );
    expect(readings.last.laf, closeTo(nominalFullScaleSineDbSpl - 40, 0.05));
  });

  test('calibration offset shifts every level, including mid-session', () {
    final meter = LevelMeter(sampleRate: _fs);
    final signal = sine(frequency: 1000, amplitude: 0.1, sampleRate: _fs, seconds: 2);
    final before = _run(meter, signal).last;
    meter.calibrationOffsetDb = 3.5;
    final after = _run(meter, signal).last;
    expect(after.laf - before.laf, closeTo(3.5, 0.01));
    expect(after.laeq - before.laeq, closeTo(3.5, 0.01));
    expect(after.lafMax! - before.lafMax!, closeTo(3.5, 0.01));
  });

  test('emits one reading per 125 ms regardless of chunk size', () {
    final signal = sine(frequency: 500, amplitude: 0.2, sampleRate: _fs, seconds: 1);
    final a = _run(LevelMeter(sampleRate: _fs), signal, chunk: 1);
    final b = _run(LevelMeter(sampleRate: _fs), signal, chunk: 997);
    final c = _run(LevelMeter(sampleRate: _fs), signal, chunk: 4096);
    expect(a.length, 8);
    expect(b.length, 8);
    expect(c.length, 8);
    for (var i = 0; i < 8; i++) {
      expect(b[i].laeq, closeTo(a[i].laeq, 1e-9));
      expect(c[i].laf, closeTo(a[i].laf, 1e-9));
      expect(c[i].elapsed, Duration(milliseconds: 125 * (i + 1)));
    }
  });

  test('LAeq energy-averages two equal-length segments', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      concat([
        sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 1),
        sine(frequency: 1000, amplitude: 0.1, sampleRate: _fs, seconds: 1),
      ]),
    );
    final l1 = nominalFullScaleSineDbSpl;
    final l2 = nominalFullScaleSineDbSpl - 20;
    final expected =
        10 * _log10((math.pow(10, l1 / 10) + math.pow(10, l2 / 10)) / 2);
    expect(readings.last.laeq, closeTo(expected, 0.1));
  });

  test('Fast time weighting rises to −2 dB after one time constant', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 1),
    );
    // 1 − e^(−1) of the final mean square = −1.99 dB.
    expect(
      readings.first.laf,
      closeTo(nominalFullScaleSineDbSpl + 10 * _log10(1 - math.exp(-1)), 0.3),
    );
  });

  test('Fast time weighting decays at 34.7 dB/s', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      concat([
        sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 1),
        silence(sampleRate: _fs, seconds: 1),
      ]),
    );
    // Readings land every 125 ms: index 9 → 1.25 s, index 13 → 1.75 s.
    final drop = readings[9].laf - readings[13].laf;
    expect(drop, closeTo(34.74 * 0.5, 0.2));
  });

  test('Lmax/Lmin wait for the Fast detector to settle, then track', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(
      meter,
      concat([
        sine(frequency: 1000, amplitude: 0.1, sampleRate: _fs, seconds: 1),
        sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 1),
        sine(frequency: 1000, amplitude: 0.1, sampleRate: _fs, seconds: 1),
      ]),
    );
    // Settling takes 5τ = 625 ms → the first four readings have no extrema.
    for (final r in readings.take(4)) {
      expect(r.lafMax, isNull);
      expect(r.lafMin, isNull);
    }
    expect(readings[4].lafMin, isNotNull);
    expect(readings.last.lafMax, closeTo(nominalFullScaleSineDbSpl, 0.1));
    expect(readings.last.lafMin, closeTo(nominalFullScaleSineDbSpl - 20, 0.2));
  });

  test('flags clipping only for the interval that contained it', () {
    final meter = LevelMeter(sampleRate: _fs);
    final signal = sine(frequency: 1000, amplitude: 0.1, sampleRate: _fs, seconds: 0.5);
    signal[100] = 1.0;
    final readings = _run(meter, signal);
    expect(readings[0].clipped, isTrue);
    expect(readings.skip(1).any((r) => r.clipped), isFalse);
  });

  test('reset starts a fresh session', () {
    final meter = LevelMeter(sampleRate: _fs);
    _run(meter, sine(frequency: 1000, amplitude: 1.0, sampleRate: _fs, seconds: 1));
    meter.reset();
    final readings = _run(
      meter,
      sine(frequency: 1000, amplitude: 0.01, sampleRate: _fs, seconds: 1),
    );
    expect(readings.first.elapsed, const Duration(milliseconds: 125));
    expect(readings.last.laeq, closeTo(nominalFullScaleSineDbSpl - 40, 0.2));
  });

  test('digital silence yields finite levels', () {
    final meter = LevelMeter(sampleRate: _fs);
    final readings = _run(meter, silence(sampleRate: _fs, seconds: 1));
    expect(readings.last.laf.isFinite, isTrue);
    expect(readings.last.laeq.isFinite, isTrue);
  });
}
