import 'dart:math' as math;

import 'biquad.dart';

// Pole frequencies of the A-weighting network, IEC 61672-1 Annex E.
const _f1 = 20.598997;
const _f2 = 107.65265;
const _f3 = 737.86223;
const _f4 = 12194.217;

double _log10(double x) => math.log(x) / math.ln10;

double _analogMagnitude(double frequency) {
  final ff = frequency * frequency;
  return (_f4 * _f4 * ff * ff) /
      ((ff + _f1 * _f1) *
          math.sqrt((ff + _f2 * _f2) * (ff + _f3 * _f3)) *
          (ff + _f4 * _f4));
}

final double _analogMagnitudeAt1k = _analogMagnitude(1000);

/// Analog A-weighting in dB at [frequency] Hz, normalised to 0 dB at 1 kHz.
double aWeightingDb(double frequency) =>
    20 * _log10(_analogMagnitude(frequency) / _analogMagnitudeAt1k);

// Zeros of the high-frequency section sit at z = −β. The bilinear transform
// (β = 1) droops towards Nyquist (−1.5 dB at 10 kHz, fs 44.1 kHz) and the
// matched-z transform (β = 0) overshoots (+1.3 dB); β = 0.1 was found by
// minimax search and keeps the error within 0.1 dB up to 12.5 kHz for any
// fs from 44.1 to 96 kHz.
const _highSectionZero = 0.1;

/// Digital A-weighting filter for the IEC 61672-1 analog network
/// `K·s⁴ / ((s+ω1)²·(s+ω2)·(s+ω3)·(s+ω4)²)`, as three biquads: the two
/// low-frequency sections by bilinear transform, the ω4 low-pass by matched-z
/// with tuned zeros. Gain is normalised to exactly 0 dB at 1 kHz.
class AWeightingFilter {
  factory AWeightingFilter(double sampleRate) {
    if (sampleRate <= 2 * _f4) {
      throw ArgumentError.value(
        sampleRate,
        'sampleRate',
        'must exceed twice the highest A-weighting pole (${2 * _f4} Hz)',
      );
    }
    final w1 = 2 * math.pi * _f1;
    final w2 = 2 * math.pi * _f2;
    final w3 = 2 * math.pi * _f3;
    final w4 = 2 * math.pi * _f4;
    final sections = [
      // s² / (s + ω1)²
      Biquad.bilinear(
        nb2: 1, nb1: 0, nb0: 0,
        da2: 1, da1: 2 * w1, da0: w1 * w1,
        sampleRate: sampleRate,
      ),
      // s² / ((s + ω2)(s + ω3))
      Biquad.bilinear(
        nb2: 1, nb1: 0, nb0: 0,
        da2: 1, da1: w2 + w3, da0: w2 * w3,
        sampleRate: sampleRate,
      ),
      // 1 / (s + ω4)² → (1 + β·z⁻¹)² / (1 − p·z⁻¹)², p = e^(−ω4/fs)
      _matchedLowPass(math.exp(-w4 / sampleRate)),
    ];
    final gainAt1k = sections.fold<double>(
      1,
      (g, s) => g * s.magnitudeAt(1000, sampleRate),
    );
    sections[2] = sections[2].scaled(1 / gainAt1k);
    return AWeightingFilter._(sampleRate, sections);
  }

  AWeightingFilter._(this.sampleRate, this._sections);

  final double sampleRate;
  final List<Biquad> _sections;

  double process(double x) {
    var y = x;
    for (final section in _sections) {
      y = section.process(y);
    }
    return y;
  }

  void reset() {
    for (final section in _sections) {
      section.reset();
    }
  }

  static Biquad _matchedLowPass(double pole) => Biquad(
        b0: 1,
        b1: 2 * _highSectionZero,
        b2: _highSectionZero * _highSectionZero,
        a1: -2 * pole,
        a2: pole * pole,
      );

  /// Digital magnitude response in dB at [frequency] Hz.
  double responseDb(double frequency) => 20 *
      _log10(_sections.fold<double>(
        1,
        (g, s) => g * s.magnitudeAt(frequency, sampleRate),
      ));
}
