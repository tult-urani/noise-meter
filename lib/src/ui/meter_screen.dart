import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../dsp/level_meter.dart';
import '../meter/meter_controller.dart';
import '../settings/language_controller.dart';
import 'assessment.dart';
import 'calibration_sheet.dart';
import 'format.dart';
import 'level_history_chart.dart';

class MeterScreen extends StatefulWidget {
  const MeterScreen({super.key, required this.controller, required this.language});

  final MeterController controller;
  final LanguageController language;

  @override
  State<MeterScreen> createState() => _MeterScreenState();
}

class _MeterScreenState extends State<MeterScreen> {
  late final AppLifecycleListener _lifecycle;

  MeterController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
    // Neither platform keeps the microphone for a backgrounded app here.
    _lifecycle = AppLifecycleListener(onHide: _controller.stop);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        final active =
            status == MeterStatus.measuring || status == MeterStatus.starting;
        final l10n = AppLocalizations.of(context);
        final assessment = assess(_controller, l10n);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              _LanguageMenu(language: widget.language),
              IconButton(
                tooltip: l10n.calibrateTooltip,
                icon: const Icon(Icons.tune),
                onPressed: () => showCalibrationSheet(context, _controller),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeToggle(controller: _controller),
                  const SizedBox(height: 16),
                  _LevelDisplay(
                    reading: _controller.latest,
                    severity: assessment?.severity,
                  ),
                  const SizedBox(height: 12),
                  if (_controller.isClipping) const _ClipWarning(),
                  const SizedBox(height: 16),
                  if (assessment != null && assessment.title != null)
                    _AssessmentCard(assessment: assessment),
                  if (status == MeterStatus.permissionDenied)
                    _PermissionCard(controller: _controller)
                  else if (status == MeterStatus.failed)
                    _ErrorCard(controller: _controller),
                  _Statistics(reading: _controller.latest),
                  const SizedBox(height: 24),
                  LevelHistoryChart(
                    levels: _controller.history,
                    capacity: MeterController.historyCapacity,
                  ),
                  const SizedBox(height: 12),
                  _SourceInfo(controller: _controller),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: status == MeterStatus.starting
                  ? null
                  : active
                      ? _controller.stop
                      : _controller.start,
              icon: Icon(active ? Icons.stop : Icons.mic),
              label: Text(active ? l10n.stopButton : l10n.startButton),
            ),
          ),
        );
      },
    );
  }
}

const _tabular = [FontFeature.tabularFigures()];

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.language});

  final LanguageController language;

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).languageTooltip,
      icon: const Icon(Icons.language),
      initialValue: current,
      onSelected: language.setLanguage,
      itemBuilder: (context) => [
        for (final MapEntry(key: code, value: name) in languageNames.entries)
          CheckedPopupMenuItem(value: code, checked: code == current, child: Text(name)),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.controller});

  final MeterController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<AssessmentMode>(
      segments: [
        ButtonSegment(
          value: AssessmentMode.health,
          icon: const Icon(Icons.health_and_safety_outlined),
          label: Text(l10n.modeHealth),
        ),
        ButtonSegment(
          value: AssessmentMode.sleep,
          icon: const Icon(Icons.bedtime_outlined),
          label: Text(l10n.modeSleep),
        ),
      ],
      selected: {controller.mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => controller.setMode(selection.single),
    );
  }
}

class _LevelDisplay extends StatelessWidget {
  const _LevelDisplay({required this.reading, required this.severity});

  final LevelReading? reading;

  /// Colours the level; null keeps the default text colour.
  final Severity? severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatDb(reading?.laf),
              style: theme.textTheme.displayLarge!.copyWith(
                fontSize: 88,
                fontWeight: FontWeight.w600,
                fontFeatures: _tabular,
                color: severity == null
                    ? null
                    : severityColor(severity!, theme.brightness),
              ),
            ),
            const SizedBox(width: 8),
            Text('dBA', style: theme.textTheme.headlineSmall),
          ],
        ),
        Text(
          AppLocalizations.of(context).levelCaption,
          style: theme.textTheme.bodySmall!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Shown while samples clip, so readings may be lower than the real level.
class _ClipWarning extends StatelessWidget {
  const _ClipWarning();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      color: scheme.errorContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.volume_up, size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context).clippedBadge,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = severityColor(assessment.severity, theme.brightness);
    final muted = theme.textTheme.bodySmall!
        .copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card.filled(
      color: accent.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(assessment.icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.title!,
                    style: theme.textTheme.titleMedium!.copyWith(color: accent),
                  ),
                  const SizedBox(height: 4),
                  Text(assessment.body!),
                  const SizedBox(height: 8),
                  for (final line in assessment.details) Text(line, style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.reading});

  final LevelReading? reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      ('LAeq', formatDb(reading?.laeq), 'dBA'),
      ('Lmax', formatDb(reading?.lafMax), 'dBA'),
      ('Lmin', formatDb(reading?.lafMin), 'dBA'),
      (l10n.statDuration, formatElapsed(reading?.elapsed), ''),
    ];
    return Row(
      children: [
        for (final (label, value, unit) in items)
          Expanded(child: _StatTile(label: label, value: value, unit: unit)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge!.copyWith(fontFeatures: _tabular),
        ),
        Text(unit, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _SourceInfo extends StatelessWidget {
  const _SourceInfo({required this.controller});

  final MeterController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = controller.audioSource;
    final rate = controller.sampleRate;
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (source != null) l10n.sourceInfo(source),
      if (rate != null) '${(rate / 1000).toStringAsFixed(1)} kHz',
      l10n.calibrationInfo(formatSignedDb(controller.calibrationOffsetDb)),
    ];
    return Text(
      parts.join(' · '),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall!
          .copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.controller});

  final MeterController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _NoticeCard(
      message: l10n.permissionMessage,
      actions: [
        TextButton(onPressed: controller.start, child: Text(l10n.retryButton)),
        FilledButton.tonal(
          onPressed: controller.openSettings,
          child: Text(l10n.openSettingsButton),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.controller});

  final MeterController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _NoticeCard(
      message: l10n.measurementStopped(_errorText(l10n, controller.errorCode)),
      actions: [
        FilledButton.tonal(onPressed: controller.start, child: Text(l10n.measureAgainButton)),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message, required this.actions});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps the native mic handlers' error codes to the selected language.
String _errorText(AppLocalizations l10n, String? code) => switch (code) {
      'permission_denied' => l10n.errorPermissionDenied,
      'mic_busy' => l10n.errorMicBusy,
      'start_failed' => l10n.errorStartFailed,
      'stop_failed' => l10n.errorStopFailed,
      'read_failed' => l10n.errorReadFailed,
      'interrupted' => l10n.errorInterrupted,
      _ => l10n.errorUnknown(code ?? unknownErrorCode),
    };
