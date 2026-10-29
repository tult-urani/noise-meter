import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/main.dart';
import 'package:noisemeter/src/dsp/level_meter.dart';
import 'package:noisemeter/src/meter/meter_controller.dart';
import 'package:noisemeter/src/settings/language_controller.dart';

import '../dsp/signals.dart';
import '../meter/fakes.dart';

/// 1 kHz has 0 dB A-weighting, so a sine of this peak reads [levelDb].
Float32List tone(double levelDb, double seconds) => sine(
      frequency: 1000,
      amplitude: math.pow(10, (levelDb - nominalFullScaleSineDbSpl) / 20).toDouble(),
      sampleRate: 48000,
      seconds: seconds,
    );

Color? levelColor(WidgetTester tester) => tester
    .widget<Text>(find.byWidgetPredicate((w) => w is Text && w.style?.fontSize == 88))
    .style!
    .color;

void main() {
  late FakeMicSource mic;
  late MemoryCalibrationStore store;
  late MeterController controller;
  late MemoryLanguageStore languageStore;

  setUp(() {
    mic = FakeMicSource();
    store = MemoryCalibrationStore();
    controller = MeterController(mic: mic, calibrationStore: store);
    languageStore = MemoryLanguageStore('vi');
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final language = LanguageController(store: languageStore);
    await language.load();
    await tester.pumpWidget(NoiseMeterApp(controller: controller, language: language));
    await tester.pumpAndSettle();
  }

  void setDeviceLocales(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  testWidgets('idle screen shows placeholders and no calibration badge', (tester) async {
    await pumpApp(tester);
    expect(find.text('--.-'), findsWidgets);
    expect(find.text('Bắt đầu đo'), findsOneWidget);
    expect(find.text('Chưa hiệu chuẩn'), findsNothing);
  });

  testWidgets('measuring shows live level and a stop button', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();
    expect(find.text('Dừng'), findsOneWidget);

    mic.emit(sine(frequency: 1000, amplitude: 0.1, sampleRate: 48000, seconds: 1));
    await tester.pumpAndSettle();
    // Amplitude 0.1 sits 20 dB below a full-scale sine.
    expect(find.text((nominalFullScaleSineDbSpl - 20).toStringAsFixed(1)), findsWidgets);
    expect(find.textContaining('Nguồn thu: FAKE'), findsOneWidget);

    await tester.tap(find.text('Dừng'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu đo'), findsOneWidget);
    expect(mic.stopCalls, 1);
  });

  testWidgets('risk card escalates with level and stays hidden when quiet', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();

    mic.emit(tone(30, 12));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trung bình 10 giây'), findsNothing);
    expect(find.textContaining('kém tin cậy'), findsNothing);
    expect(levelColor(tester), Colors.green.shade800);

    mic.emit(tone(62, 12));
    await tester.pumpAndSettle();
    expect(find.text('Ồn: có thể gây khó chịu'), findsOneWidget);
    expect(levelColor(tester), Colors.amber.shade900);

    mic.emit(tone(75, 12));
    await tester.pumpAndSettle();
    expect(find.text('Ồn cao: có hại nếu kéo dài'), findsOneWidget);
    expect(levelColor(tester), Colors.deepOrange.shade800);

    // NIOSH: 91 dBA is 2 halvings above 85 dBA → 2 h.
    mic.emit(tone(91, 12));
    await tester.pumpAndSettle();
    expect(find.text('Nguy hại thính lực'), findsOneWidget);
    expect(find.textContaining('tối đa 2 giờ mỗi ngày'), findsOneWidget);
    expect(find.text('Ồn cao: có hại nếu kéo dài'), findsNothing);
    expect(levelColor(tester), Colors.red.shade800);
  });

  testWidgets('sleep toggle switches the verdict for the same level', (tester) async {
    await pumpApp(tester);
    final idleColor = Theme.of(tester.element(find.byType(Scaffold))).textTheme.displayLarge!.color;
    expect(levelColor(tester), idleColor);
    await tester.tap(find.text('Giấc ngủ'));
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();

    mic.emit(tone(30, 12));
    await tester.pumpAndSettle();
    expect(find.text('Phù hợp để ngủ'), findsOneWidget);
    expect(levelColor(tester), Colors.green.shade800);

    mic.emit(concat([tone(60, 1), tone(30, 2), tone(50, 12)]));
    await tester.pumpAndSettle();
    expect(find.text('Không phù hợp để ngủ'), findsOneWidget);
    expect(find.textContaining('2 lần'), findsOneWidget);
    expect(levelColor(tester), Colors.deepOrange.shade800);

    // 50 dBA is harmless for health, so that mode shows no card.
    await tester.tap(find.text('Sức khỏe'));
    await tester.pumpAndSettle();
    expect(find.text('Không phù hợp để ngủ'), findsNothing);
    expect(find.textContaining('Trung bình 10 giây'), findsNothing);
    expect(levelColor(tester), Colors.green.shade800);
  });

  testWidgets('overload warning appears on clipping and clears by itself', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();

    final clipped = tone(80, 0.25)..[10] = 1.0;
    mic.emit(clipped);
    await tester.pumpAndSettle();
    expect(find.text('Âm quá to, số đo có thể thấp hơn thực tế'), findsOneWidget);

    mic.emit(tone(80, 3.5));
    await tester.pumpAndSettle();
    expect(find.text('Âm quá to, số đo có thể thấp hơn thực tế'), findsNothing);
  });

  testWidgets('start failure is explained in the selected language', (tester) async {
    mic.startError = PlatformException(code: 'mic_busy', message: 'native detail');
    await pumpApp(tester);
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();
    expect(find.text('Đã dừng đo: micro đang được ứng dụng khác sử dụng'), findsOneWidget);
  });

  group('language', () {
    testWidgets('follows a supported device language', (tester) async {
      setDeviceLocales(tester, const [Locale('ja', 'JP')]);
      languageStore.code = null;
      await pumpApp(tester);
      expect(find.text('騒音計'), findsOneWidget);
      expect(find.text('測定開始'), findsOneWidget);
    });

    testWidgets('falls back to English for other device languages', (tester) async {
      setDeviceLocales(tester, const [Locale('fr', 'FR'), Locale('de')]);
      languageStore.code = null;
      await pumpApp(tester);
      expect(find.text('Noise Meter'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('a saved choice overrides the device language', (tester) async {
      setDeviceLocales(tester, const [Locale('ja')]);
      languageStore.code = 'vi';
      await pumpApp(tester);
      expect(find.text('Máy đo tiếng ồn'), findsOneWidget);
    });

    testWidgets('menu switches the whole screen and saves the choice', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Ngôn ngữ'));
      await tester.pumpAndSettle();
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);

      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, 'English'));
      await tester.pumpAndSettle();
      expect(languageStore.code, 'en');
      expect(find.text('Noise Meter'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Bắt đầu đo'), findsNothing);
    });
  });

  testWidgets('denied permission offers the settings shortcut', (tester) async {
    mic.permissionGranted = false;
    await pumpApp(tester);
    await tester.tap(find.text('Bắt đầu đo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở Cài đặt'));
    expect(mic.openSettingsCalls, 1);
  });

  testWidgets('calibration sheet saves the offset', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Hiệu chỉnh'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tăng 0,1 dB'));
    await tester.tap(find.byTooltip('Tăng 0,1 dB'));
    await tester.pump();
    expect(find.text('Độ lệch: +0.2 dB'), findsOneWidget);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.offsetDb, closeTo(0.2, 1e-9));
    expect(find.textContaining('Hiệu chỉnh +0.2 dB'), findsOneWidget);
  });
}
