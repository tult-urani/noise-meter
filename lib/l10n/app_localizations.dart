import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Noise Meter'**
  String get appTitle;

  /// No description provided for @calibrateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Calibrate'**
  String get calibrateTooltip;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @modeHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get modeHealth;

  /// No description provided for @modeSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get modeSleep;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @levelCaption.
  ///
  /// In en, this message translates to:
  /// **'Instantaneous level (LAF, A-weighted, Fast)'**
  String get levelCaption;

  /// No description provided for @clippedBadge.
  ///
  /// In en, this message translates to:
  /// **'Too loud for the microphone: reading may be lower than actual'**
  String get clippedBadge;

  /// No description provided for @statDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get statDuration;

  /// No description provided for @sourceInfo.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String sourceInfo(String source);

  /// No description provided for @calibrationInfo.
  ///
  /// In en, this message translates to:
  /// **'Calibration {offset} dB'**
  String calibrationInfo(String offset);

  /// No description provided for @permissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed to measure noise. Audio is analysed on the device only, never recorded or sent.'**
  String get permissionMessage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// No description provided for @openSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// No description provided for @measurementStopped.
  ///
  /// In en, this message translates to:
  /// **'Measurement stopped: {reason}'**
  String measurementStopped(String reason);

  /// No description provided for @measureAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get measureAgainButton;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'microphone permission not granted'**
  String get errorPermissionDenied;

  /// No description provided for @errorMicBusy.
  ///
  /// In en, this message translates to:
  /// **'the microphone is in use by another app'**
  String get errorMicBusy;

  /// No description provided for @errorStartFailed.
  ///
  /// In en, this message translates to:
  /// **'couldn\'t open the microphone'**
  String get errorStartFailed;

  /// No description provided for @errorStopFailed.
  ///
  /// In en, this message translates to:
  /// **'couldn\'t stop the microphone cleanly'**
  String get errorStopFailed;

  /// No description provided for @errorReadFailed.
  ///
  /// In en, this message translates to:
  /// **'error reading from the microphone'**
  String get errorReadFailed;

  /// No description provided for @errorInterrupted.
  ///
  /// In en, this message translates to:
  /// **'interrupted by a call or another app'**
  String get errorInterrupted;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown error ({code})'**
  String errorUnknown(String code);

  /// No description provided for @recentAverage.
  ///
  /// In en, this message translates to:
  /// **'{seconds}-second average: {level} dBA'**
  String recentAverage(String seconds, String level);

  /// No description provided for @basisWhoNiosh.
  ///
  /// In en, this message translates to:
  /// **'Based on WHO/NIOSH'**
  String get basisWhoNiosh;

  /// No description provided for @basisWho.
  ///
  /// In en, this message translates to:
  /// **'Based on WHO'**
  String get basisWho;

  /// No description provided for @healthAnnoyingTitle.
  ///
  /// In en, this message translates to:
  /// **'Noisy: may cause annoyance'**
  String get healthAnnoyingTitle;

  /// No description provided for @healthAnnoyingBody.
  ///
  /// In en, this message translates to:
  /// **'Hours of exposure at this level cause stress, reduce concentration and disturb sleep.'**
  String get healthAnnoyingBody;

  /// No description provided for @healthProlongedTitle.
  ///
  /// In en, this message translates to:
  /// **'Loud: harmful if prolonged'**
  String get healthProlongedTitle;

  /// No description provided for @healthProlongedBody.
  ///
  /// In en, this message translates to:
  /// **'Several hours a day above {threshold} dBA raise the risk of hearing loss.'**
  String healthProlongedBody(String threshold);

  /// No description provided for @healthDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hearing damage risk'**
  String get healthDangerTitle;

  /// No description provided for @healthDangerBody.
  ///
  /// In en, this message translates to:
  /// **'Limit exposure at this level to {exposure} a day. Move away from the source or wear earplugs.'**
  String healthDangerBody(String exposure);

  /// No description provided for @sleepEvents.
  ///
  /// In en, this message translates to:
  /// **'Sudden noises above {threshold} dBA: {count} (keep under 10–15 a night)'**
  String sleepEvents(String threshold, String count);

  /// No description provided for @sleepGoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Good for sleep'**
  String get sleepGoodTitle;

  /// No description provided for @sleepGoodBody.
  ///
  /// In en, this message translates to:
  /// **'Quiet enough to sleep and rest.'**
  String get sleepGoodBody;

  /// No description provided for @sleepFairTitle.
  ///
  /// In en, this message translates to:
  /// **'Fine for rest, hard to sleep deeply'**
  String get sleepFairTitle;

  /// No description provided for @sleepFairBody.
  ///
  /// In en, this message translates to:
  /// **'Light sleepers may struggle. Closing windows or wearing earplugs helps.'**
  String get sleepFairBody;

  /// No description provided for @sleepPoorTitle.
  ///
  /// In en, this message translates to:
  /// **'Not suitable for sleep'**
  String get sleepPoorTitle;

  /// No description provided for @sleepPoorBody.
  ///
  /// In en, this message translates to:
  /// **'This level easily delays sleep and causes awakenings.'**
  String get sleepPoorBody;

  /// No description provided for @sleepUnsuitableTitle.
  ///
  /// In en, this message translates to:
  /// **'Too loud to sleep or rest'**
  String get sleepUnsuitableTitle;

  /// No description provided for @sleepUnsuitableBody.
  ///
  /// In en, this message translates to:
  /// **'This level causes stress and makes it hard to relax.'**
  String get sleepUnsuitableBody;

  /// No description provided for @exposureUnderMinute.
  ///
  /// In en, this message translates to:
  /// **'under 1 minute'**
  String get exposureUnderMinute;

  /// No description provided for @exposureMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String exposureMinutes(String minutes);

  /// No description provided for @exposureHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String exposureHours(String hours);

  /// No description provided for @exposureHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String exposureHoursMinutes(String hours, String minutes);

  /// No description provided for @calibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get calibrationTitle;

  /// No description provided for @calibrationHelp.
  ///
  /// In en, this message translates to:
  /// **'Place the phone next to a reference sound level meter with a steady sound source. Adjust the offset until the app\'s reading matches the reference.'**
  String get calibrationHelp;

  /// No description provided for @calibrationStartHint.
  ///
  /// In en, this message translates to:
  /// **'Start measuring to see the live reading while adjusting.'**
  String get calibrationStartHint;

  /// No description provided for @calibrationPreview.
  ///
  /// In en, this message translates to:
  /// **'Calibrated reading: {level} dBA'**
  String calibrationPreview(String level);

  /// No description provided for @decreaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decrease 0.1 dB'**
  String get decreaseTooltip;

  /// No description provided for @increaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increase 0.1 dB'**
  String get increaseTooltip;

  /// No description provided for @calibrationOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset: {offset} dB'**
  String calibrationOffset(String offset);

  /// No description provided for @clearCalibrationButton.
  ///
  /// In en, this message translates to:
  /// **'Clear calibration'**
  String get clearCalibrationButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
