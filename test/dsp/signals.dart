import 'dart:math' as math;
import 'dart:typed_data';

/// Sine wave with the given peak [amplitude] (1.0 = digital full scale).
Float32List sine({
  required double frequency,
  required double amplitude,
  required double sampleRate,
  required double seconds,
}) {
  final count = (sampleRate * seconds).round();
  final samples = Float32List(count);
  for (var i = 0; i < count; i++) {
    samples[i] = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate);
  }
  return samples;
}

Float32List silence({required double sampleRate, required double seconds}) =>
    Float32List((sampleRate * seconds).round());

Float32List concat(List<Float32List> parts) {
  final out = Float32List(parts.fold(0, (sum, p) => sum + p.length));
  var offset = 0;
  for (final part in parts) {
    out.setAll(offset, part);
    offset += part.length;
  }
  return out;
}

/// Exact 1/3-octave band centre frequency `1000 · 10^(n/10)` Hz.
double thirdOctave(int n) => 1000 * math.pow(10, n / 10).toDouble();
