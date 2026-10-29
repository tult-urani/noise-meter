import 'dart:math' as math;
import 'dart:typed_data';

import 'a_weighting.dart';

/// Sound pressure level (dB SPL) assumed to produce a full-scale digital sine
/// before any user calibration. Typical phone MEMS microphones are specified
/// at −26 dBFS for 94 dB SPL, i.e. 0 dBFS ≈ 120 dB SPL. Lowered by 4 dB after
/// comparing an iPhone 12 against NIOSH SLM, which read lower than 120 implied.
const nominalFullScaleSineDbSpl = 116.0;

/// Fast (F) exponential time weighting, IEC 61672-1.
const fastTimeConstantSeconds = 0.125;

/// Raw samples at or above this magnitude mean the input stage saturated.
const clipThreshold = 0.99;

// Mean square of a full-scale sine (peak 1.0).
const _fullScaleSineMeanSquare = 0.5;

// Lmax/Lmin start after 5τ, when a step from silence is within 0.03 dB.
const _settleTimeConstants = 5;

// Floor that keeps log10 finite on digital silence (≈ −147 dB re full scale).
const _silenceFloorMeanSquare = 1e-15;

class LevelReading {
  const LevelReading({
    required this.elapsed,
    required this.laf,
    required this.laeq,
    required this.lafMax,
    required this.lafMin,
    required this.clipped,
  });

  /// Session time at the end of this reading interval.
  final Duration elapsed;

  /// A-weighted, Fast time-weighted level at the end of the interval.
  final double laf;

  /// A-weighted equivalent continuous level since the session started.
  final double laeq;

  /// Session extrema of [laf]; null until the detector has settled.
  final double? lafMax;
  final double? lafMin;

  /// Whether any raw sample in this interval reached [clipThreshold].
  final bool clipped;
}

/// Sound level meter core: A-weighting, Fast time weighting and session
/// statistics (LAeq, LAFmax, LAFmin), emitting one [LevelReading] per
/// [readingInterval] of audio regardless of how input is chunked.
class LevelMeter {
  LevelMeter({
    required this.sampleRate,
    this.calibrationOffsetDb = 0,
    Duration readingInterval = const Duration(milliseconds: 125),
  })  : _filter = AWeightingFilter(sampleRate),
        _alpha = 1 - math.exp(-1 / (fastTimeConstantSeconds * sampleRate)),
        _samplesPerReading =
            (sampleRate * readingInterval.inMicroseconds / 1e6).round(),
        _settleSamples =
            (_settleTimeConstants * fastTimeConstantSeconds * sampleRate).ceil();

  final double sampleRate;

  /// User calibration in dB, added to every level. Safe to change mid-session.
  double calibrationOffsetDb;

  final AWeightingFilter _filter;
  final double _alpha;
  final int _samplesPerReading;
  final int _settleSamples;

  int _sampleCount = 0;
  double _energySum = 0;
  double _fastMeanSquare = 0;
  double _maxMeanSquare = 0;
  double _minMeanSquare = double.infinity;
  bool _clippedInInterval = false;

  List<LevelReading> process(Float32List samples) {
    final readings = <LevelReading>[];
    for (final raw in samples) {
      if (raw.abs() >= clipThreshold) _clippedInInterval = true;
      final weighted = _filter.process(raw);
      final square = weighted * weighted;
      _energySum += square;
      _fastMeanSquare += _alpha * (square - _fastMeanSquare);
      _sampleCount++;
      if (_sampleCount >= _settleSamples) {
        _maxMeanSquare = math.max(_maxMeanSquare, _fastMeanSquare);
        _minMeanSquare = math.min(_minMeanSquare, _fastMeanSquare);
      }
      if (_sampleCount % _samplesPerReading == 0) {
        readings.add(_reading());
        _clippedInInterval = false;
      }
    }
    return readings;
  }

  void reset() {
    _filter.reset();
    _sampleCount = 0;
    _energySum = 0;
    _fastMeanSquare = 0;
    _maxMeanSquare = 0;
    _minMeanSquare = double.infinity;
    _clippedInInterval = false;
  }

  LevelReading _reading() {
    final settled = _sampleCount >= _settleSamples;
    return LevelReading(
      elapsed: Duration(microseconds: (_sampleCount * 1e6 / sampleRate).round()),
      laf: _levelDb(_fastMeanSquare),
      laeq: _levelDb(_energySum / _sampleCount),
      lafMax: settled ? _levelDb(_maxMeanSquare) : null,
      lafMin: settled ? _levelDb(_minMeanSquare) : null,
      clipped: _clippedInInterval,
    );
  }

  double _levelDb(double meanSquare) =>
      10 *
          math.log(math.max(meanSquare, _silenceFloorMeanSquare) / _fullScaleSineMeanSquare) /
          math.ln10 +
      nominalFullScaleSineDbSpl +
      calibrationOffsetDb;
}
