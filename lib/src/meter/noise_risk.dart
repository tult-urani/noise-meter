import 'dart:math' as math;

/// Health effect bands for a sustained A-weighted level.
enum NoiseRisk {
  /// Below [annoyanceThresholdDb].
  low,

  /// WHO Guidelines for Community Noise (1999): from 55 dBA LAeq daytime,
  /// serious annoyance, stress and reduced concentration.
  annoying,

  /// WHO (1999): a 24 h LAeq of 70 dBA is the limit for negligible
  /// hearing impairment over a lifetime; longer exposure above it adds risk.
  harmfulIfProlonged,

  /// NIOSH REL: 85 dBA for 8 h a day; exposure beyond the allowed time
  /// risks permanent hearing loss.
  hearingDamage,
}

const annoyanceThresholdDb = 55.0;
const prolongedHarmThresholdDb = 70.0;
const hearingDamageThresholdDb = 85.0;

/// NIOSH 3 dB exchange rate: each +3 dB halves the allowed time.
const _nioshExchangeRateDb = 3.0;
const _nioshReferenceExposure = Duration(hours: 8);

NoiseRisk classifyNoise(double laeqDb) {
  if (laeqDb >= hearingDamageThresholdDb) return NoiseRisk.hearingDamage;
  if (laeqDb >= prolongedHarmThresholdDb) return NoiseRisk.harmfulIfProlonged;
  if (laeqDb >= annoyanceThresholdDb) return NoiseRisk.annoying;
  return NoiseRisk.low;
}

/// Daily exposure NIOSH allows at [laeqDb] before hearing damage risk.
Duration nioshSafeExposure(double laeqDb) {
  final halvings = (laeqDb - hearingDamageThresholdDb) / _nioshExchangeRateDb;
  final micros = _nioshReferenceExposure.inMicroseconds / math.pow(2, halvings);
  return Duration(microseconds: micros.round());
}
