import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import '../meter/meter_controller.dart';
import '../meter/noise_risk.dart';
import '../meter/sleep_rating.dart';
import 'format.dart';

enum Severity { ok, notice, warning, danger }

/// The verdict on the recent level in the active [AssessmentMode]. A null
/// [title] colours the level without showing a card.
class Assessment {
  const Assessment({
    required this.severity,
    this.icon,
    this.title,
    this.body,
    this.details = const [],
  });

  final Severity severity;
  final IconData? icon;
  final String? title;
  final String? body;
  final List<String> details;
}

Color severityColor(Severity severity, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (severity) {
    Severity.ok => dark ? Colors.green.shade300 : Colors.green.shade800,
    Severity.notice => dark ? Colors.amber.shade300 : Colors.amber.shade900,
    Severity.warning => dark ? Colors.deepOrange.shade300 : Colors.deepOrange.shade800,
    Severity.danger => dark ? Colors.red.shade300 : Colors.red.shade800,
  };
}

/// Null until the session has a reading.
Assessment? assess(MeterController controller, AppLocalizations l10n) {
  final level = controller.recentLaeq;
  if (level == null) return null;
  final average = l10n.recentAverage('${riskWindow.inSeconds}', formatDb(level));
  return switch (controller.mode) {
    AssessmentMode.health =>
      _assessHealth(classifyNoise(level), level, average, l10n),
    AssessmentMode.sleep =>
      _assessSleep(rateSleep(level), average, controller.sleepEventCount, l10n),
  };
}

Assessment _assessHealth(
  NoiseRisk risk,
  double level,
  String average,
  AppLocalizations l10n,
) {
  final details = [average, l10n.basisWhoNiosh];
  return switch (risk) {
    NoiseRisk.low => const Assessment(severity: Severity.ok),
    NoiseRisk.annoying => Assessment(
        severity: Severity.notice,
        icon: Icons.volume_up,
        title: l10n.healthAnnoyingTitle,
        body: l10n.healthAnnoyingBody,
        details: details,
      ),
    NoiseRisk.harmfulIfProlonged => Assessment(
        severity: Severity.warning,
        icon: Icons.hearing,
        title: l10n.healthProlongedTitle,
        body: l10n.healthProlongedBody(prolongedHarmThresholdDb.toStringAsFixed(0)),
        details: details,
      ),
    NoiseRisk.hearingDamage => Assessment(
        severity: Severity.danger,
        icon: Icons.warning_amber,
        title: l10n.healthDangerTitle,
        body: l10n.healthDangerBody(formatExposure(nioshSafeExposure(level), l10n)),
        details: details,
      ),
  };
}

Assessment _assessSleep(
  SleepRating rating,
  String average,
  int events,
  AppLocalizations l10n,
) {
  final details = [
    average,
    l10n.sleepEvents(sleepEventThresholdDb.toStringAsFixed(0), '$events'),
    l10n.basisWho,
  ];
  return switch (rating) {
    SleepRating.good => Assessment(
        severity: Severity.ok,
        icon: Icons.bedtime,
        title: l10n.sleepGoodTitle,
        body: l10n.sleepGoodBody,
        details: details,
      ),
    SleepRating.fair => Assessment(
        severity: Severity.notice,
        icon: Icons.weekend,
        title: l10n.sleepFairTitle,
        body: l10n.sleepFairBody,
        details: details,
      ),
    SleepRating.poor => Assessment(
        severity: Severity.warning,
        icon: Icons.bedtime_off,
        title: l10n.sleepPoorTitle,
        body: l10n.sleepPoorBody,
        details: details,
      ),
    SleepRating.unsuitable => Assessment(
        severity: Severity.danger,
        icon: Icons.do_not_disturb_on,
        title: l10n.sleepUnsuitableTitle,
        body: l10n.sleepUnsuitableBody,
        details: details,
      ),
  };
}
