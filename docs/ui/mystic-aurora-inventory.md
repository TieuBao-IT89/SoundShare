# Mystic Aurora — kiểm kê trước khi triển khai

Yêu cầu: thiết kế lại giao diện đang hoạt động, mặc định tiếng Việt; giữ Clerk, REST API, dữ liệu và state phát nhạc. Không commit hoặc push trong đợt thay đổi này.

## Nền tảng đã kiểm tra

- Flutter 3.47.4, Dart 3.13.3; Riverpod 2.6, GoRouter 14, just_audio 0.9.
- `lib/app/theme/app_theme.dart` có một dark theme; chưa có ARB, font đóng gói hoặc design tokens tách biệt.
- `lib/features` gồm auth, splash, home, explore, player, upload, library, profile. `lib/core` giữ config, API/audio service và widget dùng chung.
- Web: ClerkJS 6.42.2 và UI 1.42.3 qua `web/clerk-bridge.js`; Flutter native dùng clerk_flutter hiện có. Session gate và provider container độc lập theo phiên phải được giữ.
- Catalog, tìm kiếm, upload, URL phát và yêu thích đi qua Express; giao diện dùng provider/repository hiện tại. Không có API thông báo, playlist, hồ sơ công khai, lịch sử nghe hoặc cài đặt.

## Màn hình và phạm vi chỉnh sửa

| Màn hình | Hành vi đã có | Thay đổi giao diện |
|---|---|---|
| Splash | Timer điều hướng, fade | Logo sóng âm, Aurora, khẩu hiệu Việt, chuyển động giảm được |
| Đăng nhập | Clerk modal và khôi phục phiên | Cửa vào Aurora; Việt hóa shell, Clerk localization/appearance; giữ xác minh token |
| Trang chủ | Catalog riêng/demo, bài nổi bật, nhóm thể loại | Header tài khoản, banner artwork, nội dung có dữ liệu, lối vào tải nhạc |
| Khám phá | Tìm kiếm server có debounce, filter query/genre/collection | Tìm kiếm và bộ lọc Việt hóa, nhóm thể loại rõ ràng, đầy đủ loading/error/empty |
| Đang phát | Streams player, seek, skip, like, shuffle/repeat | Artwork/glow, tiến trình thật, nút gradient, bố cục hẹp và desktop |
| Mini player | Cùng audio provider, hiện trên navigation | Tách widget dùng chung, progress thật, kính mờ nhẹ, giữ chọn bài qua tab |
| Thư viện | Nhạc đã upload và yêu thích theo tài khoản | Kệ nhạc riêng, bộ lọc rõ, số lượng từ catalog, empty có hành động |
| Tải nhạc | MP3 20 MB, artwork 5 MB, metadata, retry | Bàn tải nhạc, vùng chọn file, form/preview responsive, tiến trình không giả % |
| Cá nhân | Tên Clerk, số lượt thích, logout | Thẻ danh tính riêng, thống kê có nguồn, thư viện/upload, quản lý tài khoản bằng Clerk và logout |
| Cài đặt | Chưa tồn tại | Không thêm màn hình hay công tắc chưa có tác dụng |

## Dùng chung và giới hạn

Xây tokens màu/gradient/spacing/typography, Be Vietnam Pro đóng gói kèm OFL, Flutter localization/ARB tiếng Việt, AuroraBackground, GradientButton, GlassCard, gradient icon, search, skeleton, artwork, section/empty/error, navigation thích ứng. Giữ danh tính bài hát, dữ liệu do người dùng nhập và tên nghệ sĩ nguyên văn. Không thêm dependency animation; dùng Flutter SDK và tôn trọng Reduce Motion.

Chưa có dữ liệu playlist/artist độc lập nên không dựng thẻ nội dung giả. Profile chỉ nhận tên, không tự tạo email/avatar. Upload chỉ báo thành công sau callback API hoàn tất. Các bước kiểm tra và ảnh sẽ được ghi trong báo cáo nghiệm thu khi thực sự chạy.

## Tiến độ theo giai đoạn

| Giai đoạn | File chính | Kết quả |
|---|---|---|
| 1. Nền tảng | `app_theme.dart`, `pubspec.yaml`, `assets/fonts`, `l10n.yaml`, `lib/l10n` | Token Aurora, font cục bộ, localization mặc định tiếng Việt |
| 2. Thành phần / navigation | `aurora_widgets.dart`, `app_scaffold.dart`, `catalog_widgets.dart`, `artwork.dart`, `section_heading.dart` | Glass, gradient, skeleton, trạng thái, navigation mobile/desktop và semantic tap |
| 3. Trang chủ / khám phá | `home_screen.dart`, `explore_screen.dart`, `sample_collection_tile.dart` | Layout mới, copy Việt, giữ filter/debounce/catalog/index bài |
| 4. Player / mini | `player_screen.dart`, `floating_mini_player.dart`, `music_progress_slider.dart` | Artwork glow, progress thật, cùng instance audio và Hero có Reduce Motion |
| 5. Nội dung cá nhân | `library_screen.dart`, `upload_screen.dart`, `profile_screen.dart` | Thư viện thật, form responsive, trạng thái upload và danh tính hiện có |
| 6. Xác thực | `web_auth.dart`, `session_gate.dart`, `account_management.dart`, `session_scope.dart`, `main.dart`, `clerk_vi.dart`, `web/clerk-*` | Shell và bản dịch Clerk, quản lý tài khoản; cập nhật tên cùng phiên giữ nguyên player; giữ xác minh, refresh và timeout |
| 7. Chuyển động / tiếp cận | Component chung, `artwork_glow.dart`, `splash_screen.dart`, route Player, tests | Nhấn thẻ, shimmer, mini icon, glow theo ảnh; reduced motion, 48 dp, chữ 2×, keyboard và màn hình ngang |
| 8. Nghiệm thu | `test/*`, README, DESIGN, báo cáo ảnh | Kết quả thực tế và giới hạn ghi trong `mystic-aurora-review.md` |

Không có chỉnh sửa trong `backend/`, file secret hoặc cấu hình môi trường thật. Không commit/push trong đợt redesign.
