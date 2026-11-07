# SoundShare — Vinyl Player 2.0

Ảnh bìa của bản thu độc lập nằm ở tâm mâm đĩa kỹ thuật số, với chất liệu charcoal làm khung và ánh sáng nền lấy từ chính artwork. Hướng hình khối tham khảo [Vinyl Player — Ana Carolina Magalhães](https://dribbble.com/shots/27364872-Vinyl-Player-Music-Player-UI) và [Vinyl Music Player — Tom.vsx](https://dribbble.com/shots/14611479-Vinyl-Music-Player-App-UI-Concept); bản triển khai dùng palette, font và nội dung SoundShare.

## Hành vi đã triển khai

- Đĩa có 40 rãnh, phản chiếu cố định, viền dày, bóng đổ và nhãn artwork 70% đường kính. Quay thuận chiều kim đồng hồ 12 giây/vòng; pause/buffering/completed/lỗi dừng đúng góc, resume tiếp tục. Góc còn được giữ khi đổi breakpoint và cây bố cục thay đổi. Artwork đổi bằng cross-fade 500 ms.
- Cần kim chuyển 650 ms vào vành ngoài khi playing/ready, về nghỉ khi pause/buffering/completed/lỗi; không che nhãn và không nhận gesture. Đĩa dưới 220 px hoặc Reduce Motion không có cần kim.
- Hai radial gradient lấy màu artwork qua ảnh cache/bitmap 32×32, đổi trong 650 ms. Chờ ảnh mới vẫn giữ màu cũ; ảnh thiếu/lỗi/trung tính/quá hạn dùng màu thương hiệu. Không blur liên tục hay lấy mẫu mỗi frame.
- Double-tap thích/bỏ thích dùng chung service với nút tim. Khóa request theo identity, không đổi UI trước khi lưu thành công, lỗi báo an toàn; phản hồi muộn vẫn cập nhật đúng bài. Vuốt ngang vùng đĩa chuyển bài; seek giữ gesture riêng. Creator có username mở hồ sơ công khai.
- Queue mobile mở Bottom Sheet, tablet/desktop tiếp tục drawer/panel. Có phát ngay, thêm, bỏ và kéo thứ tự. Reorder giữ đúng mục đang phát, kể cả các occurrence trùng bài, không gọi lại setUrl. Queue hiện chỉ lưu trong phiên, không đồng bộ server.
- Nút Play/Pause morph; tim có phản hồi scale/fade, đĩa hiện tim ngắn khi lưu thành công; haptic trên nền tảng hỗ trợ. Reduce Motion dừng quay, bỏ cần kim, cross-fade/morph/phản hồi và chuyển động sheet.
- Hẹn giờ 15/30/60 phút: một deadline thay/hủy được, không reset khi đổi bài; đến hạn tạm dừng player chung. Nếu URL/decoder còn tải, kết quả về muộn không tự phát. Timer thuộc container phiên và được hủy khi dispose; không lưu qua lần khởi động sau.
- Luồng hoàn tất queue dùng generation của audio source để vẫn chuyển bài sau pause/resume; nút Play ở cuối queue seek về đầu và phát lại sau một lần chạm.

## Giới hạn dữ liệu và nghiệm thu

API/domain hiện **không có lyrics hay timestamp**. Nút lời mở trạng thái tiếng Việt “Chưa có lời bài hát cho bản thu này.” Không có lời mẫu, highlight hay cuộn đồng bộ; phần đồng bộ còn phụ thuộc dữ liệu backend hợp lệ. Không thêm endpoint/provider/schema/storage mới.

Kiểm tra bằng Flutter widget test với fake AudioPlayer/repository và artwork tổng hợp, không dùng tài khoản hoặc database thật. Chưa nghiệm thu FPS, haptic, audio nền/lock screen và sleep timer khi OS đình chỉ ứng dụng trên thiết bị Android/iOS thật. Dart timer trong phiên không thay thế background audio service hoặc báo thức hệ thống.

## File thay đổi trong nâng cấp 2.0

| File | Vai trò |
|---|---|
| `lib/core/widgets/vinyl_record_artwork.dart` | Chất liệu, artwork transition, tonearm và bộ nhớ góc |
| `lib/core/widgets/artwork_glow.dart` | Sampling, giữ màu cũ, radial và chuyển màu |
| `lib/features/player/presentation/player_screen.dart` | Bố cục theo chiều cao, Safe Area, creator và controls |
| `lib/features/player/presentation/player_record.dart` | Double-tap, vuốt, semantics và phản hồi tim |
| `lib/features/player/presentation/player_extras.dart` | Lyrics empty state, sheet hẹn giờ, thêm vào queue |
| `lib/core/widgets/playback_controls.dart` | Morph, service favorite chung và mở queue sheet |
| `lib/core/widgets/player_sheet.dart` | Sheet dùng chung, Safe Area, Reduce Motion |
| `lib/core/widgets/listening_panel.dart` | Kéo đổi thứ tự và giữ các thao tác queue |
| `lib/core/services/audio_service.dart` | Reorder, pause khi đang tải và hoàn tất queue |
| `lib/core/services/song_favorite_service.dart` | Lưu yêu thích theo identity, khóa mutation chung |
| `lib/core/services/sleep_timer_service.dart` | Deadline thật, thay/hủy và cleanup |
| `lib/l10n/app_vi.arb`, `lib/l10n/generated/app_localizations*.dart` | Copy tiếng Việt và file sinh bằng gen-l10n |
| `test/vinyl_player_v2_test.dart` | Gestures, favorite race/error, queue, profile, lyrics, timer, responsive |
| `test/vinyl_record_artwork_test.dart` | Tonearm và capture sau bitmap readback |
| `test/aurora_motion_test.dart` | Giữ màu khi đổi ảnh, nội suy 650 ms và Reduce Motion |
| `DESIGN.md`, `PRD.md`, báo cáo này | Hành vi sản phẩm và giới hạn |

## Ảnh kiểm tra

Các ảnh dùng font thật của ứng dụng, bìa hình học tổng hợp trong test; caption “Nhạc mẫu” được giữ. Ảnh trước nâng cấp vẫn ở [báo cáo vinyl đầu tiên](vinyl-player-review.md).

| Bố cục | Light | Dark |
|---|---|---|
| 320×640, system padding 24 px | [Ảnh](vinyl-player-v2/v2-player-320-light.png) | [Ảnh](vinyl-player-v2/v2-player-320-dark.png) |
| 360×740, system padding 24 px | [Ảnh](vinyl-player-v2/v2-player-360-light.png) | [Ảnh](vinyl-player-v2/v2-player-360-dark.png) |
| 390×844, pause | [Ảnh](vinyl-player-v2/v2-player-390-light.png) | [Ảnh](vinyl-player-v2/v2-player-390-dark.png) |
| 390×844, playing | [Ảnh](vinyl-player-v2/v2-player-390-light-playing.png) | [Ảnh](vinyl-player-v2/v2-player-390-dark-playing.png) |
| 430×932 | [Ảnh](vinyl-player-v2/v2-player-430-light.png) | [Ảnh](vinyl-player-v2/v2-player-430-dark.png) |
| Queue mobile | [Ảnh](vinyl-player-v2/v2-queue-light.png) | [Ảnh](vinyl-player-v2/v2-queue-dark.png) |

## Kiểm tra

Kết quả cuối: `flutter analyze` không có issue; toàn bộ `flutter test --dart-define=CAPTURE_VINYL_REVIEW=true` có **278 kiểm thử đạt**, gồm 23 ca trong `vinyl_player_v2_test.dart`. Đã xem ảnh Light/Dark, cần kim lúc phát/nghỉ, bố cục điện thoại hẹp và queue sheet. Lưu 12 ảnh V2 trong thư mục đi kèm. Kiểm tra định dạng các file Dart liên quan và `git diff --check` đạt.

Các assertion mới bao phủ favorite thành công/lỗi/request lặp/phản hồi muộn khi đổi bài, swipe hai hướng, reorder có bài trùng và không restart audio, kéo hàng đợi thật trong sheet, phát ngay/thêm bài, profile route, lời trống với chữ 2×, deadline thay/hủy/đổi bài/đang tải và UI hẹn giờ. Kiểm tra kích thước 320/360/390/430 px xác nhận Play hit-test được và nằm trên system padding dưới mà không cuộn. Bài test vinyl hiện có tiếp tục kiểm tra tốc độ, pause/resume, buffering/completed, lifecycle, Reduce Motion, TickerMode, dispose, fallback, light/dark, chữ 2× và landscape/desktop.

Lệnh chạy:

```powershell
flutter analyze
flutter test --dart-define=CAPTURE_VINYL_REVIEW=true
```

Ảnh sinh ở `build/vinyl-review/`; chép các file `v2-*.png` sang `docs/ui/vinyl-player-v2/` để lưu bằng chứng. Không tự commit/push trong nhiệm vụ này.
