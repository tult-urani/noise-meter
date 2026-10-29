# NoiseMeter

App đo mức ồn môi trường (iOS + Android, Flutter). Hiển thị mức tức thời LAF (trọng số A, Fast),
LAeq, Lmax, Lmin của phiên đo và biểu đồ 60 giây gần nhất. Không ghi âm, không gửi dữ liệu đi đâu.

## Độ chính xác

- Công thức (trọng số A theo IEC 61672-1, Fast τ = 125 ms, LAeq) được kiểm bằng test:
  bộ lọc A lệch ≤ 0,1 dB so với đường cong chuẩn từ 10 Hz đến 12,5 kHz.
- Số tuyệt đối **chưa được hiệu chuẩn**: app giả định sóng sin full-scale = 116 dB SPL
  (`nominalFullScaleSineDbSpl`, `lib/src/dsp/level_meter.dart`; giảm từ 120 sau khi so với
  NIOSH SLM trên iPhone 12). Mỗi dòng máy lệch vài dB.
  Dùng nút **Hiệu chỉnh** để nhập độ lệch so với máy đo chuẩn.
- Dưới khoảng 35 dBA, nhiễu nội của micro điện thoại làm số đo cao hơn thực tế.
- Không thay thế máy đo loại 1 đã kiểm định theo QCVN 26:2025/BNNMT.

## Cảnh báo sức khỏe

Đánh giá theo LAeq của 10 giây gần nhất (`lib/src/meter/noise_risk.dart`):

| Mức | Cảnh báo | Căn cứ |
|---|---|---|
| < 55 dBA | không hiện | |
| 55–70 dBA | gây khó chịu, căng thẳng, ảnh hưởng giấc ngủ | WHO Guidelines for Community Noise (1999) |
| 70–85 dBA | có hại nếu kéo dài nhiều giờ | WHO: LAeq 24 h 70 dBA |
| ≥ 85 dBA | nguy hại thính lực, kèm thời gian tiếp xúc tối đa mỗi ngày | NIOSH REL 85 dBA/8 h, quy tắc 3 dB |

Nút **Sức khỏe | Giấc ngủ** đổi thang đánh giá; số đo đổi màu theo mức (xanh → vàng → cam → đỏ).
Chế độ giấc ngủ (`lib/src/meter/sleep_rating.dart`, WHO 1999):

| Mức | Đánh giá |
|---|---|
| < 35 dBA | phù hợp để ngủ (WHO khuyến nghị phòng ngủ ≤ 30 dBA; micro điện thoại không đo chính xác dưới ~35) |
| 35–45 dBA | nghỉ ngơi được, khó ngủ sâu |
| 45–55 dBA | không phù hợp để ngủ |
| ≥ 55 dBA | quá ồn để ngủ hay nghỉ ngơi |

Kèm số lần tiếng ồn đột ngột vượt 45 dBA trong phiên đo (WHO: nên dưới 10–15 lần mỗi đêm).

Nhãn "Âm quá to, số đo có thể thấp hơn thực tế" hiện khi có mẫu chạm trần micro (|x| ≥ 0,99)
và tự ẩn sau 3 giây không còn quá tải (`clipHoldTime`, `lib/src/meter/meter_controller.dart`).

## Ngôn ngữ

Tiếng Việt, English, 日本語 — chọn bằng biểu tượng 🌐 trên thanh tiêu đề, lưu lại cho lần sau.
Mặc định theo ngôn ngữ máy; máy dùng ngôn ngữ khác thì hiện tiếng Anh.

- Chuỗi giao diện: `lib/l10n/app_{en,vi,ja}.arb` (`app_en.arb` là mẫu), sinh code bằng `flutter gen-l10n`
  (tự chạy khi build). `test/l10n_test.dart` kiểm 3 file đủ khóa và cùng placeholder.
- Native chỉ trả mã lỗi (`permission_denied`, `mic_busy`, `start_failed`, `stop_failed`, `read_failed`,
  `interrupted`); Dart dịch theo ngôn ngữ đang chọn.
- Câu xin quyền micro trên iOS: `ios/Runner/{en,vi,ja}.lproj/InfoPlist.strings`. iOS chọn theo ngôn ngữ
  máy, không theo lựa chọn trong app.

## Logo

Nguồn: `branding/logo.svg` (icon đầy đủ) và `branding/logo_foreground.svg` (lớp hình của adaptive icon
Android, thu vào vùng an toàn 66/108). Sửa SVG rồi chạy `branding/generate_icons.sh` để sinh lại
toàn bộ icon iOS (`AppIcon.appiconset`, không alpha) và Android (`mipmap-*`, adaptive icon trong
`mipmap-anydpi-v26`, màu nền `values/ic_launcher_background.xml`).

## Kiến trúc

| Lớp | File |
|---|---|
| Thu âm native | `ios/Runner/MicStreamPlugin.swift` (AVAudioSession mode `measurement`), `android/.../MicStreamHandler.kt` (`UNPROCESSED` → `VOICE_RECOGNITION`, tắt AGC/NS/AEC) |
| Kênh truyền | `lib/src/audio/mic_source.dart` — MethodChannel `vn.urani.noisemeter/mic`, EventChannel `.../mic/samples` (Float32 PCM mono) |
| Xử lý tín hiệu | `lib/src/dsp/` — bộ lọc A, Fast, LAeq, Lmax/Lmin, phát hiện quá tải |
| Trạng thái | `lib/src/meter/meter_controller.dart`, hiệu chỉnh lưu bằng `shared_preferences` |
| Ngôn ngữ | `lib/src/settings/language_controller.dart`, `lib/l10n/` |
| Giao diện | `lib/src/ui/` |

## Chạy

```sh
flutter test                      # unit + widget test
flutter run                       # cần thiết bị thật để đo thật
```

Integration test (micro thật → màn hình) cần cấp quyền micro trước khi app xin quyền, ví dụ trên Android:

```sh
adb shell 'for i in $(seq 1 600); do pm grant vn.urani.noisemeter android.permission.RECORD_AUDIO 2>/dev/null; sleep 0.2; done' &
flutter test integration_test -d <device-id>
```

iOS chạy trên máy thật cần chọn Team ký ở `ios/Runner.xcworkspace` → Signing & Capabilities.
