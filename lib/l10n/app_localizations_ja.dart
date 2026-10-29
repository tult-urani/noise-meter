// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '騒音計';

  @override
  String get calibrateTooltip => '校正';

  @override
  String get languageTooltip => '言語';

  @override
  String get modeHealth => '健康';

  @override
  String get modeSleep => '睡眠';

  @override
  String get startButton => '測定開始';

  @override
  String get stopButton => '停止';

  @override
  String get levelCaption => '瞬時値（LAF、A特性、Fast）';

  @override
  String get clippedBadge => '音が大きすぎます：実際より低く表示される可能性があります';

  @override
  String get statDuration => '経過時間';

  @override
  String sourceInfo(String source) {
    return '入力：$source';
  }

  @override
  String calibrationInfo(String offset) {
    return '校正 $offset dB';
  }

  @override
  String get permissionMessage =>
      '騒音を測定するにはマイクへのアクセスが必要です。音声は端末内でのみ解析され、録音や送信は行われません。';

  @override
  String get retryButton => '再試行';

  @override
  String get openSettingsButton => '設定を開く';

  @override
  String measurementStopped(String reason) {
    return '測定を停止しました：$reason';
  }

  @override
  String get measureAgainButton => '再測定';

  @override
  String get errorPermissionDenied => 'マイクの使用が許可されていません';

  @override
  String get errorMicBusy => 'マイクが他のアプリで使用中です';

  @override
  String get errorStartFailed => 'マイクを開けませんでした';

  @override
  String get errorStopFailed => 'マイクを正常に停止できませんでした';

  @override
  String get errorReadFailed => 'マイクの読み取りエラー';

  @override
  String get errorInterrupted => '通話または他のアプリにより中断されました';

  @override
  String errorUnknown(String code) {
    return '不明なエラー（$code）';
  }

  @override
  String recentAverage(String seconds, String level) {
    return '$seconds秒平均：$level dBA';
  }

  @override
  String get basisWhoNiosh => 'WHO/NIOSH基準';

  @override
  String get basisWho => 'WHO基準';

  @override
  String get healthAnnoyingTitle => '騒がしい：不快に感じる可能性';

  @override
  String get healthAnnoyingBody => 'この音量に長時間さらされると、ストレス、集中力の低下、睡眠の妨げの原因になります。';

  @override
  String get healthProlongedTitle => 'うるさい：長時間では有害';

  @override
  String healthProlongedBody(String threshold) {
    return '$threshold dBAを超える音に1日数時間さらされると、難聴のリスクが高まります。';
  }

  @override
  String get healthDangerTitle => '聴覚障害の危険';

  @override
  String healthDangerBody(String exposure) {
    return 'この音量では1日最大$exposureまでにしてください。音源から離れるか、耳栓を使用してください。';
  }

  @override
  String sleepEvents(String threshold, String count) {
    return '$threshold dBAを超える突発音：$count回（1晩10〜15回未満が目安）';
  }

  @override
  String get sleepGoodTitle => '睡眠に適しています';

  @override
  String get sleepGoodBody => '睡眠や休息に十分な静かさです。';

  @override
  String get sleepFairTitle => '休息は可能、熟睡は難しい';

  @override
  String get sleepFairBody => '眠りの浅い人は寝つきにくいことがあります。窓を閉めるか耳栓を使うと改善します。';

  @override
  String get sleepPoorTitle => '睡眠に適していません';

  @override
  String get sleepPoorBody => 'この音量では寝つきが悪くなり、途中で目が覚めやすくなります。';

  @override
  String get sleepUnsuitableTitle => '睡眠・休息には騒がしすぎます';

  @override
  String get sleepUnsuitableBody => 'この音量はストレスとなり、リラックスしにくくなります。';

  @override
  String get exposureUnderMinute => '1分未満';

  @override
  String exposureMinutes(String minutes) {
    return '$minutes分';
  }

  @override
  String exposureHours(String hours) {
    return '$hours時間';
  }

  @override
  String exposureHoursMinutes(String hours, String minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get calibrationTitle => '校正';

  @override
  String get calibrationHelp =>
      '安定した音源のもとで、基準となる騒音計の隣にスマートフォンを置き、アプリの値が基準器と一致するまでオフセットを調整してください。';

  @override
  String get calibrationStartHint => '測定を開始すると、調整中の値をリアルタイムで確認できます。';

  @override
  String calibrationPreview(String level) {
    return '校正後の値：$level dBA';
  }

  @override
  String get decreaseTooltip => '0.1 dB下げる';

  @override
  String get increaseTooltip => '0.1 dB上げる';

  @override
  String calibrationOffset(String offset) {
    return 'オフセット：$offset dB';
  }

  @override
  String get clearCalibrationButton => '校正をリセット';

  @override
  String get saveButton => '保存';
}
