import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/mic_source.dart';
import '../dsp/level_meter.dart';
import 'calibration_store.dart';
import 'noise_risk.dart';
import 'sleep_rating.dart';

enum MeterStatus { idle, starting, measuring, permissionDenied, failed }

/// Which yardstick the screen judges the level against.
enum AssessmentMode { health, sleep }

const historyWindow = Duration(seconds: 60);

/// How long the overload warning stays up after the last clipped reading.
const clipHoldTime = Duration(seconds: 3);

/// [MeterController.errorCode] for failures that carry no platform code.
const unknownErrorCode = 'unknown';

/// Averaging window for [MeterController.recentLaeq], long enough that the
/// health warning does not flicker with every transient.
const riskWindow = Duration(seconds: 10);

const _readingInterval = Duration(milliseconds: 125);

/// Owns one measuring session at a time: permission, capture, the
/// [LevelMeter], the rolling history and the persisted calibration.
class MeterController extends ChangeNotifier {
  MeterController({
    required this._mic,
    required CalibrationStore calibrationStore,
  }) : _store = calibrationStore;

  static final int historyCapacity =
      historyWindow.inMicroseconds ~/ _readingInterval.inMicroseconds;

  static final int _riskWindowReadings =
      riskWindow.inMicroseconds ~/ _readingInterval.inMicroseconds;

  final MicSource _mic;
  final CalibrationStore _store;

  MeterStatus _status = MeterStatus.idle;
  AssessmentMode _mode = AssessmentMode.health;
  final _sleepEvents = SleepEventCounter();
  LevelReading? _latest;
  final _history = ListQueue<double>();
  Duration? _lastClipAt;
  String? _audioSource;
  double? _sampleRate;
  String? _errorCode;
  double? _savedOffsetDb;
  LevelMeter? _meter;
  StreamSubscription<Float32List>? _subscription;

  MeterStatus get status => _status;
  AssessmentMode get mode => _mode;

  /// Rises above [sleepEventThresholdDb] in the current or last session.
  int get sleepEventCount => _sleepEvents.count;

  /// Most recent reading of the current or last session.
  LevelReading? get latest => _latest;

  /// LAF values of the last [historyWindow], oldest first.
  List<double> get history => List.unmodifiable(_history);

  /// True while measuring and a sample clipped within the last [clipHoldTime].
  bool get isClipping {
    final lastClipAt = _lastClipAt;
    final latest = _latest;
    return _status == MeterStatus.measuring &&
        lastClipAt != null &&
        latest != null &&
        latest.elapsed - lastClipAt < clipHoldTime;
  }

  String? get audioSource => _audioSource;
  double? get sampleRate => _sampleRate;
  /// Platform error code of the last failure (see the native mic handlers),
  /// or [unknownErrorCode].
  String? get errorCode => _errorCode;
  bool get isCalibrated => _savedOffsetDb != null;
  double get calibrationOffsetDb => _savedOffsetDb ?? 0;

  /// Energy average of the LAF readings in the last [riskWindow], or null
  /// before the first reading.
  double? get recentLaeq {
    if (_history.isEmpty) return null;
    final count = math.min(_history.length, _riskWindowReadings);
    var energy = 0.0;
    for (final level in _history.skip(_history.length - count)) {
      energy += math.pow(10, level / 10);
    }
    return 10 * math.log(energy / count) / math.ln10;
  }

  NoiseRisk? get noiseRisk {
    final level = recentLaeq;
    return level == null ? null : classifyNoise(level);
  }

  SleepRating? get sleepRating {
    final level = recentLaeq;
    return level == null ? null : rateSleep(level);
  }

  void setMode(AssessmentMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  Future<void> load() async {
    _savedOffsetDb = await _store.loadOffsetDb();
    notifyListeners();
  }

  Future<void> start() async {
    if (_status == MeterStatus.starting || _status == MeterStatus.measuring) {
      return;
    }
    _status = MeterStatus.starting;
    _errorCode = null;
    notifyListeners();

    try {
      if (!await _mic.requestPermission()) {
        _status = MeterStatus.permissionDenied;
        notifyListeners();
        return;
      }
      _resetSession();
      _subscription = _mic.samples.listen(_onSamples, onError: _onStreamError);
      final info = await _mic.start();
      _sampleRate = info.sampleRate;
      _audioSource = info.audioSource;
      _meter = LevelMeter(
        sampleRate: info.sampleRate,
        calibrationOffsetDb: calibrationOffsetDb,
        readingInterval: _readingInterval,
      );
      _status = MeterStatus.measuring;
      notifyListeners();
    } on PlatformException catch (e) {
      final detached = _detachCapture();
      _fail(e);
      notifyListeners();
      await detached;
    }
  }

  Future<void> stop() async {
    if (_status != MeterStatus.measuring && _status != MeterStatus.starting) {
      return;
    }
    try {
      await _mic.stop();
      _status = MeterStatus.idle;
    } on PlatformException catch (e) {
      _fail(e);
    }
    final detached = _detachCapture();
    notifyListeners();
    await detached;
  }

  Future<void> setCalibrationOffset(double offsetDb) async {
    await _store.saveOffsetDb(offsetDb);
    _savedOffsetDb = offsetDb;
    _meter?.calibrationOffsetDb = offsetDb;
    notifyListeners();
  }

  Future<void> clearCalibration() async {
    await _store.clear();
    _savedOffsetDb = null;
    _meter?.calibrationOffsetDb = 0;
    notifyListeners();
  }

  Future<void> openSettings() => _mic.openSettings();

  @override
  void dispose() {
    // Cancelling the stream makes the native side stop capturing.
    _subscription?.cancel();
    super.dispose();
  }

  void _resetSession() {
    _latest = null;
    _history.clear();
    _lastClipAt = null;
    _sleepEvents.reset();
    _meter = null;
  }

  void _onSamples(Float32List chunk) {
    final meter = _meter;
    if (meter == null) return;
    final readings = meter.process(chunk);
    if (readings.isEmpty) return;
    for (final reading in readings) {
      _history.addLast(reading.laf);
      if (_history.length > historyCapacity) _history.removeFirst();
      if (reading.clipped) _lastClipAt = reading.elapsed;
      _sleepEvents.add(reading.laf);
    }
    _latest = readings.last;
    notifyListeners();
  }

  Future<void> _onStreamError(Object error) async {
    final detached = _detachCapture();
    _fail(error);
    notifyListeners();
    await detached;
  }

  /// Drops the meter and subscription at once, so the UI can update before
  /// the (possibly slow) native cancellation completes.
  Future<void> _detachCapture() async {
    final subscription = _subscription;
    _subscription = null;
    _meter = null;
    await subscription?.cancel();
  }

  void _fail(Object error) {
    _status = MeterStatus.failed;
    _errorCode = switch (error) {
      PlatformException(:final code) => code,
      _ => unknownErrorCode,
    };
  }
}
