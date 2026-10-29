import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's calibration offset; `null` means never calibrated.
abstract interface class CalibrationStore {
  Future<double?> loadOffsetDb();

  Future<void> saveOffsetDb(double offsetDb);

  Future<void> clear();
}

class PrefsCalibrationStore implements CalibrationStore {
  PrefsCalibrationStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'calibration_offset_db';

  final SharedPreferencesAsync _prefs;

  @override
  Future<double?> loadOffsetDb() => _prefs.getDouble(_key);

  @override
  Future<void> saveOffsetDb(double offsetDb) => _prefs.setDouble(_key, offsetDb);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
