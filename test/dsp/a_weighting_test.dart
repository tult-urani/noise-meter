import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/src/dsp/a_weighting.dart';

import 'signals.dart';

void main() {
  group('aWeightingDb (analog reference)', () {
    // Nominal A-weightings from IEC 61672-1 (rounded to 0.1 dB), keyed by the
    // 1/3-octave index n of the exact frequency 1000·10^(n/10) Hz.
    const nominal = <int, double>{
      -20: -70.4, // 10 Hz
      -15: -39.4, // 31.5 Hz
      -12: -26.2, // 63 Hz
      -9: -16.1, // 125 Hz
      -6: -8.6, // 250 Hz
      -3: -3.2, // 500 Hz
      0: 0.0, // 1 kHz
      3: 1.2, // 2 kHz
      6: 1.0, // 4 kHz
      9: -1.1, // 8 kHz
      12: -6.6, // 16 kHz
      13: -9.3, // 20 kHz
    };

    for (final entry in nominal.entries) {
      final f = thirdOctave(entry.key);
      test('${f.toStringAsFixed(1)} Hz ≈ ${entry.value} dB', () {
        expect(aWeightingDb(f), closeTo(entry.value, 0.06));
      });
    }

    test('is exactly 0 dB at 1 kHz', () {
      expect(aWeightingDb(1000), closeTo(0, 1e-9));
    });
  });

  for (final sampleRate in [48000.0, 44100.0]) {
    group('AWeightingFilter @ ${sampleRate.toInt()} Hz', () {
      final filter = AWeightingFilter(sampleRate);

      test('matches the analog curve within 0.1 dB from 10 Hz to 12.5 kHz', () {
        for (var n = -20; n <= 11; n++) {
          final f = thirdOctave(n);
          expect(
            filter.responseDb(f),
            closeTo(aWeightingDb(f), 0.1),
            reason: 'at ${f.toStringAsFixed(1)} Hz',
          );
        }
      });

      test('stays within 0.6 dB of the analog curve at 16 kHz', () {
        final f = thirdOctave(12);
        expect(filter.responseDb(f), closeTo(aWeightingDb(f), 0.6));
      });

      for (final f in [100.0, 1000.0, 4000.0, 10000.0]) {
        test('time-domain gain of a ${f.toInt()} Hz sine equals the response', () {
          filter.reset();
          final input = sine(
            frequency: f,
            amplitude: 0.5,
            sampleRate: sampleRate,
            seconds: 2,
          );
          // Skip the first second so the 20 Hz high-pass poles have settled.
          final settle = sampleRate.toInt();
          var inEnergy = 0.0;
          var outEnergy = 0.0;
          for (var i = 0; i < input.length; i++) {
            final y = filter.process(input[i]);
            if (i >= settle) {
              inEnergy += input[i] * input[i];
              outEnergy += y * y;
            }
          }
          final gainDb = 10 * math.log(outEnergy / inEnergy) / math.ln10;
          expect(gainDb, closeTo(filter.responseDb(f), 0.05));
        });
      }
    });
  }
}
