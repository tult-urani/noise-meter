/// How suitable a sustained A-weighted level is for sleep and rest.
///
/// WHO Guidelines for Community Noise (1999): bedrooms LAeq ≤ 30 dBA,
/// indoor rest ≤ 35 dBA, and single events above 45 dBA LAmax disturb sleep.
/// Phone microphones cannot resolve levels much below 35 dBA, so that is the
/// practical "good" limit here.
enum SleepRating {
  /// Below [sleepFairThresholdDb].
  good,

  /// Rest is fine; light sleepers may struggle.
  fair,

  /// Likely to delay sleep and cause awakenings.
  poor,

  /// Too loud for sleep or rest.
  unsuitable,
}

const sleepFairThresholdDb = 35.0;
const sleepPoorThresholdDb = 45.0;
const sleepUnsuitableThresholdDb = 55.0;

/// WHO (1999): individual events above this LAmax disturb sleep; more than
/// 10–15 per night should be avoided.
const sleepEventThresholdDb = 45.0;

/// An event ends only once the level falls this far below the threshold, so
/// a level hovering at the threshold counts once.
const _sleepEventHysteresisDb = 3.0;

SleepRating rateSleep(double laeqDb) {
  if (laeqDb >= sleepUnsuitableThresholdDb) return SleepRating.unsuitable;
  if (laeqDb >= sleepPoorThresholdDb) return SleepRating.poor;
  if (laeqDb >= sleepFairThresholdDb) return SleepRating.fair;
  return SleepRating.good;
}

/// Counts noise events: each rise of LAF to [sleepEventThresholdDb] or above.
class SleepEventCounter {
  int _count = 0;
  bool _inEvent = false;

  int get count => _count;

  void add(double lafDb) {
    if (_inEvent) {
      if (lafDb < sleepEventThresholdDb - _sleepEventHysteresisDb) _inEvent = false;
    } else if (lafDb >= sleepEventThresholdDb) {
      _inEvent = true;
      _count++;
    }
  }

  void reset() {
    _count = 0;
    _inEvent = false;
  }
}
