import '../../l10n/app_localizations.dart';

String formatDb(double? value) => value == null ? '--.-' : value.toStringAsFixed(1);

String formatSignedDb(double value) =>
    '${value >= 0 ? '+' : '−'}${value.abs().toStringAsFixed(1)}';

String formatElapsed(Duration? elapsed) {
  if (elapsed == null) return '--:--';
  final h = elapsed.inHours;
  final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Rounded down, so the shown exposure never exceeds the allowed one.
String formatExposure(Duration exposure, AppLocalizations l10n) {
  final minutes = exposure.inMinutes;
  if (minutes < 1) return l10n.exposureUnderMinute;
  final h = '${minutes ~/ 60}';
  final m = '${minutes.remainder(60)}';
  if (minutes < 60) return l10n.exposureMinutes(m);
  return minutes % 60 == 0 ? l10n.exposureHours(h) : l10n.exposureHoursMinutes(h, m);
}
