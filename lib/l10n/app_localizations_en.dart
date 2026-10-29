// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noise Meter';

  @override
  String get calibrateTooltip => 'Calibrate';

  @override
  String get languageTooltip => 'Language';

  @override
  String get modeHealth => 'Health';

  @override
  String get modeSleep => 'Sleep';

  @override
  String get startButton => 'Start';

  @override
  String get stopButton => 'Stop';

  @override
  String get levelCaption => 'Instantaneous level (LAF, A-weighted, Fast)';

  @override
  String get clippedBadge =>
      'Too loud for the microphone: reading may be lower than actual';

  @override
  String get statDuration => 'Duration';

  @override
  String sourceInfo(String source) {
    return 'Source: $source';
  }

  @override
  String calibrationInfo(String offset) {
    return 'Calibration $offset dB';
  }

  @override
  String get permissionMessage =>
      'Microphone access is needed to measure noise. Audio is analysed on the device only, never recorded or sent.';

  @override
  String get retryButton => 'Try again';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String measurementStopped(String reason) {
    return 'Measurement stopped: $reason';
  }

  @override
  String get measureAgainButton => 'Measure again';

  @override
  String get errorPermissionDenied => 'microphone permission not granted';

  @override
  String get errorMicBusy => 'the microphone is in use by another app';

  @override
  String get errorStartFailed => 'couldn\'t open the microphone';

  @override
  String get errorStopFailed => 'couldn\'t stop the microphone cleanly';

  @override
  String get errorReadFailed => 'error reading from the microphone';

  @override
  String get errorInterrupted => 'interrupted by a call or another app';

  @override
  String errorUnknown(String code) {
    return 'unknown error ($code)';
  }

  @override
  String recentAverage(String seconds, String level) {
    return '$seconds-second average: $level dBA';
  }

  @override
  String get basisWhoNiosh => 'Based on WHO/NIOSH';

  @override
  String get basisWho => 'Based on WHO';

  @override
  String get healthAnnoyingTitle => 'Noisy: may cause annoyance';

  @override
  String get healthAnnoyingBody =>
      'Hours of exposure at this level cause stress, reduce concentration and disturb sleep.';

  @override
  String get healthProlongedTitle => 'Loud: harmful if prolonged';

  @override
  String healthProlongedBody(String threshold) {
    return 'Several hours a day above $threshold dBA raise the risk of hearing loss.';
  }

  @override
  String get healthDangerTitle => 'Hearing damage risk';

  @override
  String healthDangerBody(String exposure) {
    return 'Limit exposure at this level to $exposure a day. Move away from the source or wear earplugs.';
  }

  @override
  String sleepEvents(String threshold, String count) {
    return 'Sudden noises above $threshold dBA: $count (keep under 10–15 a night)';
  }

  @override
  String get sleepGoodTitle => 'Good for sleep';

  @override
  String get sleepGoodBody => 'Quiet enough to sleep and rest.';

  @override
  String get sleepFairTitle => 'Fine for rest, hard to sleep deeply';

  @override
  String get sleepFairBody =>
      'Light sleepers may struggle. Closing windows or wearing earplugs helps.';

  @override
  String get sleepPoorTitle => 'Not suitable for sleep';

  @override
  String get sleepPoorBody =>
      'This level easily delays sleep and causes awakenings.';

  @override
  String get sleepUnsuitableTitle => 'Too loud to sleep or rest';

  @override
  String get sleepUnsuitableBody =>
      'This level causes stress and makes it hard to relax.';

  @override
  String get exposureUnderMinute => 'under 1 minute';

  @override
  String exposureMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String exposureHours(String hours) {
    return '$hours h';
  }

  @override
  String exposureHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get calibrationTitle => 'Calibration';

  @override
  String get calibrationHelp =>
      'Place the phone next to a reference sound level meter with a steady sound source. Adjust the offset until the app\'s reading matches the reference.';

  @override
  String get calibrationStartHint =>
      'Start measuring to see the live reading while adjusting.';

  @override
  String calibrationPreview(String level) {
    return 'Calibrated reading: $level dBA';
  }

  @override
  String get decreaseTooltip => 'Decrease 0.1 dB';

  @override
  String get increaseTooltip => 'Increase 0.1 dB';

  @override
  String calibrationOffset(String offset) {
    return 'Offset: $offset dB';
  }

  @override
  String get clearCalibrationButton => 'Clear calibration';

  @override
  String get saveButton => 'Save';
}
