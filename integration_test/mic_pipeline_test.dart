import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:noisemeter/main.dart';
import 'package:noisemeter/src/audio/mic_source.dart';
import 'package:noisemeter/src/meter/calibration_store.dart';
import 'package:noisemeter/src/meter/meter_controller.dart';
import 'package:noisemeter/src/settings/language_controller.dart';

/// End-to-end check of native capture → channel → Dart meter → UI.
/// Grant the microphone permission before running (see README).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real microphone delivers readings to the screen', (tester) async {
    final controller = MeterController(
      mic: PlatformMicSource(),
      calibrationStore: PrefsCalibrationStore(),
    );
    final language = LanguageController(store: PrefsLanguageStore());
    await language.setLanguage('vi');
    await tester.pumpWidget(NoiseMeterApp(controller: controller, language: language));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bắt đầu đo'));
    for (var i = 0; i < 30 && controller.latest == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(controller.status, MeterStatus.measuring, reason: controller.errorCode);
    expect(controller.sampleRate, anyOf(44100, 48000));
    expect(controller.audioSource, isNotEmpty);
    expect(controller.latest, isNotNull, reason: 'no readings within 3 s');
    expect(controller.latest!.laf.isFinite, isTrue);
    expect(find.text('Dừng'), findsOneWidget);

    await tester.tap(find.text('Dừng'));
    await tester.pumpAndSettle();
    expect(controller.status, MeterStatus.idle);
    expect(find.text('Bắt đầu đo'), findsOneWidget);
  });
}
