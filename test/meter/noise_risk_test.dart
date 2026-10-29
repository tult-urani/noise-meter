import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/src/meter/noise_risk.dart';

void main() {
  test('bands switch exactly at the WHO / NIOSH thresholds', () {
    expect(classifyNoise(54.9), NoiseRisk.low);
    expect(classifyNoise(55), NoiseRisk.annoying);
    expect(classifyNoise(69.9), NoiseRisk.annoying);
    expect(classifyNoise(70), NoiseRisk.harmfulIfProlonged);
    expect(classifyNoise(84.9), NoiseRisk.harmfulIfProlonged);
    expect(classifyNoise(85), NoiseRisk.hearingDamage);
    expect(classifyNoise(110), NoiseRisk.hearingDamage);
  });

  test('safe exposure follows the NIOSH 3 dB exchange rate', () {
    expect(nioshSafeExposure(85), const Duration(hours: 8));
    expect(nioshSafeExposure(88), const Duration(hours: 4));
    expect(nioshSafeExposure(94), const Duration(hours: 1));
    expect(nioshSafeExposure(100), const Duration(minutes: 15));
    expect(nioshSafeExposure(112).inSeconds, 56);
  });
}
