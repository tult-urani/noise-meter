import 'package:flutter_test/flutter_test.dart';
import 'package:noisemeter/l10n/app_localizations_en.dart';
import 'package:noisemeter/l10n/app_localizations_ja.dart';
import 'package:noisemeter/l10n/app_localizations_vi.dart';
import 'package:noisemeter/src/ui/format.dart';

void main() {
  test('exposure is rounded down to whole minutes', () {
    final vi = AppLocalizationsVi();
    expect(formatExposure(const Duration(seconds: 56), vi), 'dưới 1 phút');
    expect(formatExposure(const Duration(minutes: 37, seconds: 59), vi), '37 phút');
    expect(formatExposure(const Duration(hours: 2), vi), '2 giờ');
    expect(formatExposure(const Duration(hours: 6, minutes: 20, seconds: 9), vi), '6 giờ 20 phút');
  });

  test('exposure follows the selected language', () {
    const exposure = Duration(hours: 1, minutes: 5);
    expect(formatExposure(exposure, AppLocalizationsEn()), '1 h 5 min');
    expect(formatExposure(exposure, AppLocalizationsJa()), '1時間5分');
  });
}
