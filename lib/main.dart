import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'src/audio/mic_source.dart';
import 'src/meter/calibration_store.dart';
import 'src/meter/meter_controller.dart';
import 'src/settings/language_controller.dart';
import 'src/ui/meter_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final language = LanguageController(store: PrefsLanguageStore());
  // Loaded before the first frame so the saved language never flickers.
  await language.load();
  runApp(
    NoiseMeterApp(
      controller: MeterController(
        mic: PlatformMicSource(),
        calibrationStore: PrefsCalibrationStore(),
      ),
      language: language,
    ),
  );
}

class NoiseMeterApp extends StatelessWidget {
  const NoiseMeterApp({super.key, required this.controller, required this.language});

  final MeterController controller;
  final LanguageController language;

  static const _seed = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: language,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: _seed),
        darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
        locale: language.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeListResolutionCallback: resolveDeviceLocale,
        home: MeterScreen(controller: controller, language: language),
      ),
    );
  }
}
