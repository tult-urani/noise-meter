import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/src/meter/sleep_rating.dart';

void main() {
  test('ratings switch exactly at the WHO-based thresholds', () {
    expect(rateSleep(34.9), SleepRating.good);
    expect(rateSleep(35), SleepRating.fair);
    expect(rateSleep(44.9), SleepRating.fair);
    expect(rateSleep(45), SleepRating.poor);
    expect(rateSleep(54.9), SleepRating.poor);
    expect(rateSleep(55), SleepRating.unsuitable);
  });

  test('event counter counts rises above 45 dBA once each', () {
    final counter = SleepEventCounter();
    for (final level in <double>[30, 44.9, 46, 50, 44, 43, 46, 41, 30, 45, 60, 30]) {
      counter.add(level);
    }
    // 46 starts event 1; dips to 44/43 stay within the 3 dB hysteresis;
    // 41 ends it; 45 starts event 2; 30 ends it.
    expect(counter.count, 2);

    counter.reset();
    expect(counter.count, 0);
    counter.add(50);
    expect(counter.count, 1);
  });
}
