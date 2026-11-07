# Aurora Pearl V6 — Audit và các phase

Ngày rà soát: 07/11/2026. Thực hiện trên working tree hiện có, không commit/push hay truy cập dữ liệu production.

## Phát hiện trước thay đổi

- `app_theme.dart` chỉ có `AppTheme.dark`; `MaterialApp.router` dùng duy nhất theme này.
- Gần 300 tham chiếu màu tĩnh trong khoảng 33 file widget; cả loading, upload, fallback ảnh, painter và overlay dùng palette tối.
- `soundshare.css`, meta theme-color, manifest và Appearance của Clerk Web cố định nền tối. Authentication có document/hash riêng; không thể thay bằng Flutter form mà vẫn giữ hợp đồng V5.
- `SessionScope` tạo container riêng cho mỗi phiên. Cho menu đọc provider theme trong container này sẽ không cập nhật MaterialApp ở container gốc. V6 truyền controller bằng inherited scope, giữ nguyên cách cô lập phiên.
- Mini player trong các nhánh được giữ lại có cùng Hero tag. Rà soát route với active player phát hiện cần tắt Hero ở tab có TickerMode không hoạt động.
- Cyan `#007E91` chỉ đạt khoảng 4,28:1 trên `#F0F2FA`; thêm cyan chữ `#006D80`. Viền input có token tương phản riêng với viền trang trí.

## Nguồn tham khảo

- [Apple Music](https://music.apple.com/us/new): artwork lớn, nhóm nội dung và phân cấp tiêu đề. Trang đọc được khi nghiên cứu.
- [Zing MP3](https://zingmp3.vn/), [Spotify](https://open.spotify.com/): đã mở, nhưng nội dung browser tool bị giới hạn bởi JavaScript/điều kiện truy cập; không coi đây là bằng chứng đã kiểm tra toàn bộ UI live.
- [Lilac Music](https://dribbble.com/shots/20350942-Lilac-Themed-Music-Mobile-App-UI), [Melo](https://dribbble.com/shots/27303083-Melo-Music-App-UI-Design), [Light Music Player](https://dribbble.com/shots/9799574-Music-Player-Mobile-App-Light-Mode): tham khảo bố cục/art direction pastel; không sao chép asset.
- [Flutter ThemeMode](https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html), [SharedPreferences](https://pub.dev/packages/shared_preferences), [Clerk Appearance variables](https://clerk.com/docs/js-frontend/guides/customizing-clerk/appearance-prop/variables#using-css-variables). Dùng API native của Flutter và Appearance được hỗ trợ, không gọi API nội bộ để remount Clerk.

## Theo dõi phase

| Phase | File/nhóm thay đổi | Kiểm tra và điều chỉnh |
|---|---|---|
| 1 — Audit | Tài liệu này; đọc README/DESIGN/PRD, router, providers và toàn bộ nhóm presentation liên quan | Kiểm kê token tĩnh, hardcoded overlay và painter; không thay hex hàng loạt |
| 2 — Theme engine | `app_palette.dart`, `app_theme.dart`, `theme_controller.dart`, `theme_bridge_*`, `app.dart`, `main.dart`, pubspec/lockfile | Test khôi phục, giá trị hỏng, storage lỗi, ghi liên tiếp, System; thêm shared_preferences chỉ cho lưu thiết bị |
| 3 — Shared components | `aurora_widgets`, `artwork`, `catalog_widgets`, `section_heading`, `app_scaffold`, `listening_panel`, `theme_mode_menu` | Hai palette, focus/selected, dialog/sheet/menu/snackbar; bỏ giả định nền tối |
| 4 — Home/Discover | `home_screen`, `community_home_screen`, `discover_screen`, `music_components`, `community_widgets` | Featured Light riêng, logo mobile, rank đậm, genre pastel khác nhau, Follow có filled/tonal; giữ API và nội dung có dữ liệu |
| 5 — Search/Profile/Library | Search, public profile/header/account menu, playlist preview, library và sample collection presentation | Token chữ/surface, cover pastel fallback, giữ @username, owner/account actions và playlist |
| 6 — Playback | `player_screen`, `artwork_glow`, `floating_mini_player`, `playback_dock`, `playback_controls`, `music_progress_slider` | Cùng audio, route/session/queue/position qua đổi theme; ambient hạn chế saturation; sửa Hero tab ẩn; nút phát Light violet |
| 7 — Authentication/Web | `authentication_header`, auth loading/session UI, `theme.js`, CSS, HTML, Clerk bridge, manifest, SVG Pearl | Kiểm thử Web bridge; form Clerk thật render ở hai viewport; CSS variables giữ DOM/form state |
| 8 — QA/polish | `theme_*_test`, test helper, recommendation scroll test, scripts review và tài liệu/ảnh | Các lệnh và kết quả cuối ghi trong báo cáo; luồng cần OTP/native thật vẫn có giới hạn rõ ràng |

Các thay đổi của phase 3–7 được kiểm tra cùng nhau bằng suite Flutter/Web và ảnh Chrome. Kiểm tra hình ảnh không thay thế việc đăng ký/xác minh email thật; xem báo cáo nghiệm thu.
