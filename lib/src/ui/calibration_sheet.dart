import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../meter/meter_controller.dart';
import 'format.dart';

const _maxOffsetDb = 20.0;
const _stepDb = 0.1;

Future<void> showCalibrationSheet(BuildContext context, MeterController controller) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CalibrationSheet(controller: controller),
    );

class CalibrationSheet extends StatefulWidget {
  const CalibrationSheet({super.key, required this.controller});

  final MeterController controller;

  @override
  State<CalibrationSheet> createState() => _CalibrationSheetState();
}

class _CalibrationSheetState extends State<CalibrationSheet> {
  late double _offsetDb = widget.controller.calibrationOffsetDb;

  void _nudge(double delta) => setState(() {
        final stepped = ((_offsetDb + delta) / _stepDb).round() * _stepDb;
        _offsetDb = stepped.clamp(-_maxOffsetDb, _maxOffsetDb);
      });

  Future<void> _save() async {
    await widget.controller.setCalibrationOffset(_offsetDb);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    await widget.controller.clearCalibration();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.calibrationTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.calibrationHelp, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final latest = widget.controller.latest;
                final preview = latest == null
                    ? null
                    : latest.laf - widget.controller.calibrationOffsetDb + _offsetDb;
                return Text(
                  latest == null
                      ? l10n.calibrationStartHint
                      : l10n.calibrationPreview(formatDb(preview)),
                  style: theme.textTheme.bodyLarge,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.decreaseTooltip,
                  onPressed: () => _nudge(-_stepDb),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    value: _offsetDb,
                    min: -_maxOffsetDb,
                    max: _maxOffsetDb,
                    divisions: (2 * _maxOffsetDb / _stepDb).round(),
                    label: '${formatSignedDb(_offsetDb)} dB',
                    onChanged: (v) => setState(() => _offsetDb = v),
                  ),
                ),
                IconButton(
                  tooltip: l10n.increaseTooltip,
                  onPressed: () => _nudge(_stepDb),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Text(
              l10n.calibrationOffset(formatSignedDb(_offsetDb)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.controller.isCalibrated ? _clear : null,
                    child: Text(l10n.clearCalibrationButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
