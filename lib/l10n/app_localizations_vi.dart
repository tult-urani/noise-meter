// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Máy đo tiếng ồn';

  @override
  String get calibrateTooltip => 'Hiệu chỉnh';

  @override
  String get languageTooltip => 'Ngôn ngữ';

  @override
  String get modeHealth => 'Sức khỏe';

  @override
  String get modeSleep => 'Giấc ngủ';

  @override
  String get startButton => 'Bắt đầu đo';

  @override
  String get stopButton => 'Dừng';

  @override
  String get levelCaption => 'Mức tức thời (LAF, trọng số A, Fast)';

  @override
  String get clippedBadge => 'Âm quá to, số đo có thể thấp hơn thực tế';

  @override
  String get statDuration => 'Thời gian';

  @override
  String sourceInfo(String source) {
    return 'Nguồn thu: $source';
  }

  @override
  String calibrationInfo(String offset) {
    return 'Hiệu chỉnh $offset dB';
  }

  @override
  String get permissionMessage =>
      'Cần quyền truy cập micro để đo tiếng ồn. Âm thanh chỉ được phân tích trên máy, không ghi lại hay gửi đi.';

  @override
  String get retryButton => 'Thử lại';

  @override
  String get openSettingsButton => 'Mở Cài đặt';

  @override
  String measurementStopped(String reason) {
    return 'Đã dừng đo: $reason';
  }

  @override
  String get measureAgainButton => 'Đo lại';

  @override
  String get errorPermissionDenied => 'chưa được cấp quyền micro';

  @override
  String get errorMicBusy => 'micro đang được ứng dụng khác sử dụng';

  @override
  String get errorStartFailed => 'không mở được micro';

  @override
  String get errorStopFailed => 'không dừng được micro';

  @override
  String get errorReadFailed => 'lỗi đọc dữ liệu micro';

  @override
  String get errorInterrupted => 'bị gián đoạn bởi cuộc gọi hoặc ứng dụng khác';

  @override
  String errorUnknown(String code) {
    return 'lỗi không xác định ($code)';
  }

  @override
  String recentAverage(String seconds, String level) {
    return 'Trung bình $seconds giây: $level dBA';
  }

  @override
  String get basisWhoNiosh => 'Theo WHO/NIOSH';

  @override
  String get basisWho => 'Theo WHO';

  @override
  String get healthAnnoyingTitle => 'Ồn: có thể gây khó chịu';

  @override
  String get healthAnnoyingBody =>
      'Tiếp xúc nhiều giờ ở mức này gây căng thẳng, giảm tập trung và ảnh hưởng giấc ngủ.';

  @override
  String get healthProlongedTitle => 'Ồn cao: có hại nếu kéo dài';

  @override
  String healthProlongedBody(String threshold) {
    return 'Tiếp xúc trên $threshold dBA nhiều giờ mỗi ngày làm tăng nguy cơ suy giảm thính lực.';
  }

  @override
  String get healthDangerTitle => 'Nguy hại thính lực';

  @override
  String healthDangerBody(String exposure) {
    return 'Chỉ nên ở mức này tối đa $exposure mỗi ngày. Hãy tránh xa nguồn ồn hoặc dùng nút bịt tai.';
  }

  @override
  String sleepEvents(String threshold, String count) {
    return 'Tiếng ồn đột ngột trên $threshold dBA: $count lần (nên dưới 10–15 lần mỗi đêm)';
  }

  @override
  String get sleepGoodTitle => 'Phù hợp để ngủ';

  @override
  String get sleepGoodBody => 'Đủ yên tĩnh để ngủ và nghỉ ngơi.';

  @override
  String get sleepFairTitle => 'Nghỉ ngơi được, khó ngủ sâu';

  @override
  String get sleepFairBody =>
      'Người ngủ nhạy có thể khó ngủ. Đóng cửa hoặc dùng nút bịt tai sẽ tốt hơn.';

  @override
  String get sleepPoorTitle => 'Không phù hợp để ngủ';

  @override
  String get sleepPoorBody => 'Mức này dễ gây khó ngủ và tỉnh giấc giữa chừng.';

  @override
  String get sleepUnsuitableTitle => 'Quá ồn để ngủ hay nghỉ ngơi';

  @override
  String get sleepUnsuitableBody => 'Mức này gây căng thẳng, khó thư giãn.';

  @override
  String get exposureUnderMinute => 'dưới 1 phút';

  @override
  String exposureMinutes(String minutes) {
    return '$minutes phút';
  }

  @override
  String exposureHours(String hours) {
    return '$hours giờ';
  }

  @override
  String exposureHoursMinutes(String hours, String minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String get calibrationTitle => 'Hiệu chỉnh';

  @override
  String get calibrationHelp =>
      'Đặt điện thoại cạnh máy đo tiếng ồn chuẩn, cùng nguồn âm ổn định. Chỉnh độ lệch đến khi số đo của app khớp với máy chuẩn.';

  @override
  String get calibrationStartHint =>
      'Bắt đầu đo để xem số đo trực tiếp khi chỉnh.';

  @override
  String calibrationPreview(String level) {
    return 'Số đo sau hiệu chỉnh: $level dBA';
  }

  @override
  String get decreaseTooltip => 'Giảm 0,1 dB';

  @override
  String get increaseTooltip => 'Tăng 0,1 dB';

  @override
  String calibrationOffset(String offset) {
    return 'Độ lệch: $offset dB';
  }

  @override
  String get clearCalibrationButton => 'Xóa hiệu chỉnh';

  @override
  String get saveButton => 'Lưu';
}
