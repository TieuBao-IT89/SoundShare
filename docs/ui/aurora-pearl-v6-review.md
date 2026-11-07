# Aurora Pearl V6 — Kết quả kiểm tra

Ngày: 07/11/2026. Aurora Pearl là Light Theme mới, OBSIDIAN PULSE tiếp tục là Dark Theme. Công tắc mặt trời/mặt trăng chuyển Sáng/Tối trực tiếp; nút A bật/tắt Theo hệ thống. Lựa chọn lưu trên thiết bị. Không có thay đổi backend/API/database.

## Kiểm tra tự động

| Kiểm tra đã chạy | Kết quả |
|---|---|
| `dart format .` và kiểm tra lại formatter | 98 file, vòng cuối không cần định dạng lại |
| `flutter gen-l10n` | Thành công; 6 chuỗi theme tiếng Việt được tạo lại |
| `flutter analyze` / `dart analyze` | Vòng V6 ban đầu Flutter sạch; sau đổi sang công tắc, Dart phân tích toàn repository không có lỗi/cảnh báo |
| `flutter test` | **216/216 đạt** sau đổi sang công tắc, gồm thao tác gạt thực tế và nút Theo hệ thống |
| `node --test test/web/*.cjs` | **25/25 đạt** |
| Flutter Web release, config client hiện có, resources cục bộ | Build thành công |
| Chrome app: Light/Dark × 390/1280 | 34 screenshot của các màn hình chính/dock/queue, không lỗi API hoặc exception browser |
| ClerkJS/UI thật: Light/Dark × 390/1280 | 12 screenshot welcome/sign-in/sign-up; không modal hay overflow; đổi theme giữ nguyên DOM input và màu input cập nhật |

Các kiểm thử mới bao phủ mặc định Light, khôi phục cả ba chế độ, giá trị hỏng, lỗi storage, ghi liên tiếp khi đổi nhanh, System phản ứng với OS, tương phản WCAG AA và việc truyền lựa chọn qua container phiên riêng. Test route kiểm tra cả Light/Dark ở **320, 390, 430, 768, 1024, 1280, 1440 px**, có active player; 320/1280 dùng chữ 2×. Các suite cũ tiếp tục bao phủ search/follow/playlist/upload, loading/error/empty, session và controls.

Chrome đã kiểm tra trực tiếp:

- Đổi theme giữ cùng HTML audio element, vị trí tăng liên tục, trạng thái phát, route và session; F5 khôi phục lựa chọn; System theo OS khi đang mở.
- Queue desktop mở/đóng không tạo audio mới; volume điều khiển HTML audio thật; global search gửi `@username` đến trang kết quả.
- Tìm `@username` mở đúng hồ sơ, follow được lưu qua reload trong database kiểm thử; tạo playlist bằng dialog thật được lưu trong database này.
- Audio tổng hợp 20 giây phát qua điều hướng và tạo valid play event bằng heartbeat server. Không suy ra dữ liệu production từ kết quả fixture.
- Tương phản chữ thông thường ≥4,5:1 trên surface/selected và các stop featured/ambient; chữ trắng trên stop action ≥4,5:1; viền input ≥3:1. Cyan chữ được làm đậm riêng vì swatch ban đầu không đạt trên mọi pastel.

Đã xem ảnh chạy thực tế của Home, Discover, Search, Profile, full player, dock và Clerk ở cả Light/Dark. Các sửa polish sau rà soát gồm CTA player violet, header thương hiệu mobile, rank có nền riêng, cover profile pastel và giảm bóng Light.

## Ảnh so sánh thực tế

| Màn hình | 390 Sáng | 390 Tối | 1280 Sáng | 1280 Tối |
|---|---|---|---|---|
| Home | [Ảnh](aurora-pearl-v6/light/home-390.png) | [Ảnh](aurora-pearl-v6/dark/home-390.png) | [Ảnh](aurora-pearl-v6/light/home-1280.png) | [Ảnh](aurora-pearl-v6/dark/home-1280.png) |
| Discover | [Ảnh](aurora-pearl-v6/light/discover-390.png) | [Ảnh](aurora-pearl-v6/dark/discover-390.png) | [Ảnh](aurora-pearl-v6/light/discover-1280.png) | [Ảnh](aurora-pearl-v6/dark/discover-1280.png) |
| Search @username | [Ảnh](aurora-pearl-v6/light/search-390.png) | [Ảnh](aurora-pearl-v6/dark/search-390.png) | [Ảnh](aurora-pearl-v6/light/search-1280.png) | [Ảnh](aurora-pearl-v6/dark/search-1280.png) |
| Profile / empty | [Ảnh](aurora-pearl-v6/light/profile-390.png) | [Ảnh](aurora-pearl-v6/dark/profile-390.png) | [Ảnh](aurora-pearl-v6/light/profile-1280.png) | [Ảnh](aurora-pearl-v6/dark/profile-1280.png) |
| Player | [Ảnh](aurora-pearl-v6/light/player-390.png) | [Ảnh](aurora-pearl-v6/dark/player-390.png) | [Ảnh](aurora-pearl-v6/light/player-1280.png) | [Ảnh](aurora-pearl-v6/dark/player-1280.png) |
| Mini player / desktop dock | [Ảnh](aurora-pearl-v6/light/home-playing-390.png) | [Ảnh](aurora-pearl-v6/dark/home-playing-390.png) | [Ảnh](aurora-pearl-v6/light/home-playing-1280.png) | [Ảnh](aurora-pearl-v6/dark/home-playing-1280.png) |
| Library | [Ảnh](aurora-pearl-v6/light/library-390.png) | [Ảnh](aurora-pearl-v6/dark/library-390.png) | [Ảnh](aurora-pearl-v6/light/library-1280.png) | [Ảnh](aurora-pearl-v6/dark/library-1280.png) |
| Upload | [Ảnh](aurora-pearl-v6/light/upload-390.png) | [Ảnh](aurora-pearl-v6/dark/upload-390.png) | [Ảnh](aurora-pearl-v6/light/upload-1280.png) | [Ảnh](aurora-pearl-v6/dark/upload-1280.png) |
| Login Clerk | [Ảnh](aurora-pearl-v6/light/auth-sign-in-390.png) | [Ảnh](aurora-pearl-v6/dark/auth-sign-in-390.png) | [Ảnh](aurora-pearl-v6/light/auth-sign-in-1280.png) | [Ảnh](aurora-pearl-v6/dark/auth-sign-in-1280.png) |
| Signup Clerk | [Ảnh](aurora-pearl-v6/light/auth-sign-up-390.png) | [Ảnh](aurora-pearl-v6/dark/auth-sign-up-390.png) | [Ảnh](aurora-pearl-v6/light/auth-sign-up-1280.png) | [Ảnh](aurora-pearl-v6/dark/auth-sign-up-1280.png) |
| Welcome | [Ảnh](aurora-pearl-v6/light/auth-welcome-390.png) | [Ảnh](aurora-pearl-v6/dark/auth-welcome-390.png) | [Ảnh](aurora-pearl-v6/light/auth-welcome-1280.png) | [Ảnh](aurora-pearl-v6/dark/auth-welcome-1280.png) |

Queue desktop: [Sáng](aurora-pearl-v6/light/queue-1280.png) · [Tối](aurora-pearl-v6/dark/queue-1280.png). Tổng cộng **46 ảnh** được lưu cùng báo cáo.

## Phạm vi bằng chứng

Ảnh ứng dụng được chụp từ bản Flutter Web release chạy trong Chrome, dùng backend fixture PostgreSQL biệt lập, JWT kiểm thử được server xác minh và audio/artwork tổng hợp. Đây là screenshot của ứng dụng chạy thật; nội dung và phiên Clerk của bộ fixture là kiểm thử, không phải dữ liệu/tài khoản production.

Ảnh authentication dùng ClerkJS/UI thật từ cấu hình development hiện có, chỉ mở form. Không nhập thông tin đăng nhập thật, gửi OTP, tạo tài khoản hoặc bắt đầu OAuth. Dấu Development mode thuộc SDK.

Chưa nghiệm thu lại login/logout/signup/email verification/password recovery/MFA bằng tài khoản thật, account profile với phiên thật, Android/iOS hoặc lưu/khôi phục trên thiết bị native. Các suite hiện có kiểm tra session gate, authorization, tìm kiếm, follow, playlist, upload và playback bằng phụ thuộc giả lập. Không khẳng định các tích hợp production đã hoạt động từ kiểm thử này.

## Tái lập

```powershell
dart format .
flutter gen-l10n
flutter analyze
flutter test
node --test test/web/*.cjs
flutter build web --release --dart-define-from-file=.local/web-config.json --no-web-resources-cdn
python scripts/prepare-pearl-review.py
$env:QA_SNAPSHOT='1'; $env:QA_WIDTH='390'; $env:QA_THEME='light'; $env:QA_THEME_FLOW='1'
node build/review-pearl.mjs
```

Lặp ảnh với `QA_WIDTH=1280` và `QA_THEME=dark`; bỏ `QA_THEME_FLOW` khi chỉ chụp ảnh. `node build/review-pearl-auth.mjs` kiểm tra form Clerk thật ở 390/1280, không gửi credential. Không cần chạy migration hoặc cung cấp secret/database production. Các log/profile/report thô ở `build/` được gitignore.

## Điều khiển bằng công tắc

Công tắc thể hiện độ sáng đang hiển thị, kể cả khi OS quyết định theme. Gạt công tắc chuyển sang Sáng/Tối thủ công; nút A có trạng thái chọn khi Theo hệ thống được bật. Tắt A giữ độ sáng hiện tại. Cả Flutter và trang auth Web dùng cùng hành vi, lưu preference như trước; không mở menu để đổi Sáng/Tối. Control có nhãn tiếng Việt, focus bàn phím và vùng chạm tối thiểu 48 px.

Mã liên quan: `lib/core/widgets/theme_mode_menu.dart` (giữ tên để tương thích các nơi gọi), header Home hẹp, `web/auth.html`, `web/theme.js`, `web/soundshare.css`, l10n và các kiểm thử/theme review script. Các ảnh trong bảng được cập nhật theo công tắc mới. Không sửa service xác thực/API/backend cho điều chỉnh này.
