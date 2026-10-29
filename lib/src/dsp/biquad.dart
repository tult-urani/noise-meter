import 'dart:math' as math;

/// Second-order IIR section, transposed direct form II, normalised so a0 = 1.
class Biquad {
  Biquad({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  /// Digitises the analog section
  /// `(nb2·s² + nb1·s + nb0) / (da2·s² + da1·s + da0)` with the bilinear
  /// transform `s = 2·fs·(1 − z⁻¹)/(1 + z⁻¹)`.
  factory Biquad.bilinear({
    required double nb2,
    required double nb1,
    required double nb0,
    required double da2,
    required double da1,
    required double da0,
    required double sampleRate,
  }) {
    final c = 2 * sampleRate;
    final c2 = c * c;
    final norm = da2 * c2 + da1 * c + da0;
    return Biquad(
      b0: (nb2 * c2 + nb1 * c + nb0) / norm,
      b1: 2 * (nb0 - nb2 * c2) / norm,
      b2: (nb2 * c2 - nb1 * c + nb0) / norm,
      a1: 2 * (da0 - da2 * c2) / norm,
      a2: (da2 * c2 - da1 * c + da0) / norm,
    );
  }

  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  double _z1 = 0;
  double _z2 = 0;

  double process(double x) {
    final y = b0 * x + _z1;
    _z1 = b1 * x - a1 * y + _z2;
    _z2 = b2 * x - a2 * y;
    return y;
  }

  void reset() {
    _z1 = 0;
    _z2 = 0;
  }

  /// Same poles, numerator multiplied by [gain].
  Biquad scaled(double gain) =>
      Biquad(b0: b0 * gain, b1: b1 * gain, b2: b2 * gain, a1: a1, a2: a2);

  /// Linear magnitude response at [frequency] Hz.
  double magnitudeAt(double frequency, double sampleRate) {
    final w = 2 * math.pi * frequency / sampleRate;
    final cos1 = math.cos(w), sin1 = math.sin(w);
    final cos2 = math.cos(2 * w), sin2 = math.sin(2 * w);
    final numRe = b0 + b1 * cos1 + b2 * cos2;
    final numIm = -(b1 * sin1 + b2 * sin2);
    final denRe = 1 + a1 * cos1 + a2 * cos2;
    final denIm = -(a1 * sin1 + a2 * sin2);
    return math.sqrt((numRe * numRe + numIm * numIm) / (denRe * denRe + denIm * denIm));
  }
}
