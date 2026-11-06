# OBSIDIAN PULSE V4 — kết quả tích hợp và QA

**Cập nhật tiếp theo:** [Điều chỉnh thao tác hồ sơ](profile-account-menu-review.md) bỏ nút đăng nhạc và đưa Quản lý tài khoản/Đăng xuất vào menu góc phải ảnh bìa. 75 ảnh và kết quả bên dưới là baseline V4 trước điều chỉnh này; ảnh hồ sơ mới và kiểm tra bổ sung nằm trong báo cáo cập nhật.

Ngày 06/11/2026, nhánh local `feature/ui-obsidian-pulse-v4`, trên nền V3 `2d372c5`. [Audit trước khi sửa](obsidian-pulse-v4-audit.md) ghi nhận toàn bộ 19 ảnh V3 và nguồn nghiên cứu. V4 được tích hợp vào ứng dụng hiện có, không thêm dependency, thay Clerk, sửa AudioPlayer/heartbeat, đổi API/schema hoặc chạy migration trên Neon. Không commit/push trong đợt này.

## Kết quả theo sprint

| Sprint | File chính đã thay đổi/thêm | Kết quả và kiểm tra |
|---|---|---|
| 1 — Audit | `obsidian-pulse-v4-audit.md` | Đọc repository, tài liệu và 19 PNG baseline; Before/After và giới hạn nguồn live được ghi trước khi sửa UI |
| 2 — Design system | `app_theme.dart`, `app_vi.arb`, generated localization, `music_components.dart`, `community_widgets.dart` | Token OBSIDIAN, Be Vietnam Pro giữ nguyên; featured/artwork rail/Top 3/creator/genre/tab và empty compact; format và kiểm tra cộng đồng/player sau tích hợp |
| 3 — Shell | `app_scaffold.dart`, `playback_dock.dart`, `listening_panel.dart`, `playback_controls.dart` | Sidebar 224, rail 80, topbar thật; dock và drawer/panel dùng cùng player. Nhóm community/player 34 test đạt sau sửa Material/ListTile và progress assertion desktop |
| 4 — Home/Discover | `community_home_screen.dart`, `discover_screen.dart` | Featured tối đa 3 bài thật, quick access, recent, feed/gợi ý minh bạch, releases nhiều cột, Top 3 trực quan, creator/genre/emerging; giữ query/time filter/pagination V3. Nhóm 34 test đạt, gồm chữ 2x |
| 5 — Search/Profile | `community_search_screen.dart`, `search_suggestions.dart`, `public_profile_screen.dart`, `profile_header.dart` | Search debounce/loại kết quả/@handle/follow giữ nguyên; suggestions từ API; cover thật hoặc đồ họa fallback, identity/stats/actions gọn. Nhóm community/player 34 test đạt |
| 6 — Player | `player_screen.dart`, `floating_mini_player.dart`, shared playback widgets | Mobile icon controls; desktop artwork/metadata hai cột; progress, favorite, shuffle/repeat/queue chung state. Nhóm player/mobile 34 test đạt |
| 7 — Library/Upload | `music_library_screen.dart`, `library_screen.dart`, `playlist_preview.dart`, `playlists_screen.dart`, `queue_screen.dart`, client `community_repository.dart`, `upload_screen.dart` | Thư viện live dùng sliver/lazy rows, playlist metadata visual, phát tất cả/ngẫu nhiên đọc đủ trang có quyền. Queue lazy; upload giữ validation/visibility/rights/progress/cancel và chỉ thành công sau server. Toàn bộ 122 test cũ đạt trước khi thêm ma trận V4 |
| 8 — Polish/QA | `artwork.dart`, test support/player/mobile tests, `obsidian_experience_test.dart`, Web theme, README/DESIGN/PRD, `scripts/prepare-obsidian-review.py` | Sửa dock giãn chiều cao, giữ artwork vuông khi mở panel, Web dùng SDK image cache chung với ambient; tinh chỉnh artist/@handle và counter search. Bộ đầy đủ 171 test đạt; analyze sạch; JS 12/12; release Web build thành công |

Phần demo cũ vẫn được đánh dấu demo và giữ hành vi của nó; tài khoản live không nhận dữ liệu mẫu. Playlist API chưa có cover nên visual dùng biểu tượng album minh bạch, không tự gán ảnh. Bộ lọc và ranking tiếp tục dùng dữ liệu V3; không tạo thuật toán, lượt nghe hoặc playlist giả để lấp giao diện.

## Before / After

Ảnh đều là browser capture của ứng dụng chạy được. Nội dung “kiểm thử”, ảnh vòng sóng và âm thanh tổng hợp thuộc fixture biệt lập; không phải tài khoản, nhạc hoặc dữ liệu production. Số bài/quan hệ giữa ảnh baseline và ảnh mới có thể khác vì các phiên fixture độc lập.

| Vùng | Before V3 | After V4 |
|---|---|---|
| Home desktop | [1280 px](nocturne-v3/home-1280.png) | [1280 px](obsidian-pulse-v4/home-1280.png), [dock đang phát 1440 px](obsidian-pulse-v4/home-playing-1440.png) |
| Home mobile | [390 px](nocturne-v3/home-390.png) | [390 px](obsidian-pulse-v4/home-390.png), [mini player](obsidian-pulse-v4/home-playing-390.png) |
| Discovery | [390 px](nocturne-v3/discover-390.png) | [390 px](obsidian-pulse-v4/discover-390.png), [desktop Top 3](obsidian-pulse-v4/discover-1440.png) |
| Creator/thể loại | Nội dung cộng đồng V3 | [Creator mobile](obsidian-pulse-v4/discover-creators-390.png), [genre/emerging desktop](obsidian-pulse-v4/discover-genres-1440.png) |
| Search | [390 px](nocturne-v3/username-search-390.png) | [390 px](obsidian-pulse-v4/search-390.png) |
| Hồ sơ | [1280 px](nocturne-v3/profile-1280.png) | [1280 px](obsidian-pulse-v4/profile-1280.png), [hồ sơ cộng đồng](obsidian-pulse-v4/public-profile-390.png) |
| Player | [390 px](nocturne-v3/player-390.png) | [390 px](obsidian-pulse-v4/player-390.png), [desktop](obsidian-pulse-v4/player-1440.png), [queue panel](obsidian-pulse-v4/queue-1440.png) |
| Upload | [1280 px](nocturne-v3/upload-1280.png) | [1280 px](obsidian-pulse-v4/upload-1280.png) |
| Thư viện | Luồng thư viện riêng V3 | [390 px](obsidian-pulse-v4/library-390.png), [1280 px](obsidian-pulse-v4/library-1280.png) |
| Playlist | [Dialog V3](nocturne-v3/playlist-dialog-390.png) | [Danh sách có bài](obsidian-pulse-v4/playlist-390.png), [sau Phát tất cả](obsidian-pulse-v4/playlist-after-play-390.png) |

## Bằng chứng kiểm tra

[Browser report](obsidian-pulse-v4/browser-report.json) lưu kết quả chức năng, bảy viewport, kiểm tra artwork, SHA-256 bundle và danh sách **75 PNG** (khoảng 7,7 MB). Bundle đã được đối chiếu với file đang phục vụ tại localhost:3000; không còn Chrome QA do harness mở sau khi hoàn tất.

- `dart format`: các file Dart thay đổi đã format. `flutter gen-l10n` đã sinh lại localization từ ARB.
- `flutter analyze`: **No issues found**.
- `flutter test --reporter expanded`: **171/171 đạt**, gồm 122 bài cũ và 49 bài V4. Ma trận 42 trường hợp: Home/Discover/Search/Library/Profile/Player × 320/390/430/768/1024/1280/1440, có playback đang hoạt động. Test cũ bao phủ chữ 2x, keyboard, lỗi player, retry, upload và account. Queue mới kiểm tra thêm chữ 2x tại 768/1440.
- Playlist: phân trang đủ thứ tự, dedupe khi trang chồng nhau, từ chối offset không tiến hoặc trang lỗi; thao tác ngẫu nhiên sử dụng cùng AudioPlayer. Không thay queue trước khi đọc xong các trang.
- Queue: đóng/mở drawer và panel bằng tương tác, không reload audio; volume đổi trên chính player; dock cao dưới 220 px để bắt lỗi giãn hết viewport. Có kiểm tra chuyển nhiều tab trước/sau mở queue, không mở drawer ở tab bị ẩn, và đổi 1024 ↔ 1440 px khi queue đang mở.
- `node --test test/web/*.cjs`: **12/12 đạt** — Clerk navigation/account bridge và upload transport.
- `flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --dart-define-from-file=.local/web-config.json`: thành công. Không đưa nội dung cấu hình local vào tài liệu/source.
- Chrome headless với profile mới: @username mở đúng người; follow còn sau reload; tạo playlist qua dialog ghi vào PostgreSQL biệt lập; audio HTML thực chạy qua navigation và ghi valid play bằng heartbeat. Không có API thất bại hoặc exception browser không bắt được trong luồng này.
- Mỗi viewport được chụp lại bằng browser mới. Queue mở/đóng tại 768/1024/1280/1440; volume điều khiển audio HTML và topbar submit `@username` tại 1280/1440. “Phát tất cả” trên playlist có ba bài mở player và phát audio thật ở 390/1440. Kiểm tra màn hình player dựa trên semantics hiển thị; không suy luận từ hash, vì `context.push` của GoRouter không bắt buộc phản ánh imperative route lên URL. HTTP ứng dụng local trả 200.
- Đã xem ảnh mobile/tablet/desktop và kiểm tra pixel artwork trong vùng player tại cả 7 kích thước; ảnh thực đã decode, không chỉ hiện icon fallback. Các lần thử cũ phát hiện lỗi artwork sau navigation được thay bằng ảnh chụp sau khi sửa.

Các lỗi được phát hiện và sửa trong QA: hero featured overflow khi chữ 2x; ListTile thiếu Material thích hợp; volume Slider làm dock cao bằng viewport; artwork bị co khi Hero đổi bố cục; đường nạp ảnh Web của package cache trở thành fallback sau nhiều lần điều hướng. Web hiện dùng `NetworkImage`/Flutter ImageCache cho cả Artwork và lấy màu ambient; native giữ disk cache hiện có. [Tài liệu package](https://github.com/Baseflow/flutter_cached_network_image) mô tả hỗ trợ Web còn hạn chế; [Flutter NetworkImage](https://api.flutter.dev/flutter/painting/NetworkImage-class.html) là đường SDK được dùng. Không thêm package hoặc thay đổi URL/quyền đọc của server.

## Tái lập browser review

Chạy từ root sau khi cài dependencies backend và build Web. Cần Python 3, Node hỗ trợ global WebSocket và Chrome; có thể đặt `CHROME_PATH`. Đây là công cụ QA opt-in, không nằm trong runtime ứng dụng.

```powershell
python scripts/prepare-obsidian-review.py
$env:QA_ONLY_FLOW='1'
node build/review-obsidian.mjs
Remove-Item Env:QA_ONLY_FLOW
$env:QA_SNAPSHOT='1'
$env:QA_WIDTH='1440' # lần lượt 320, 390, 430, 768, 1024, 1280, 1440
$env:QA_DETAIL='1' # tùy chọn: chụp thêm sections và kiểm tra Play all
node build/review-obsidian.mjs
```

Sau khi chụp đủ bảy viewport, `python scripts/check-obsidian-artwork.py` kiểm tra PNG fixture trong vùng artwork; không chỉnh sửa ảnh hoặc áp dụng điều kiện màu cho nội dung người dùng thật.

Harness tái sử dụng fixture SQL/middleware/service V3, RSA JWT test, ảnh PNG sinh bằng code và WAV tổng hợp. Toàn bộ request browser được chuyển vào server test trong bộ nhớ, không gọi instance đang chạy tại localhost:3000. Chỉ dùng Chrome profile do harness tự tạo; server/browser được đóng sau khi chạy. Report và raw captures nằm trong `build/obsidian-review/`; bản bằng chứng chọn lưu tại [obsidian-pulse-v4](obsidian-pulse-v4/).

## Giới hạn còn lại

- Chưa chạy Android/iOS trên thiết bị thật, TalkBack/VoiceOver, hoặc đo FPS/DevTools trên Android tầm trung. Widget tests/Chrome không thay thế các bước đó.
- Đợt V4 không lặp lại đăng ký/OTP Clerk thật hoặc upload/xóa Cloudinary thật. Luồng thật V3 đã được người dùng xác nhận; V4 giữ bridge/API/services, chạy lại tests và kiểm tra server bằng fixture. Không tuyên bố có lần nghiệm thu dịch vụ ngoài mới.
- Nội dung fixture nhỏ, chưa đo tải/hiệu năng với thư viện lớn. Pagination API và lazy lists hiện có được giữ.
- “Lướt nhạc” là hạng mục optional trong brief, chưa thêm. Không dựng màn hình hoặc control mô phỏng tính năng này.
- Ảnh/bản thu thật có thể thiếu, hết hạn hoặc lỗi mạng; fallback và retry được giữ. Chrome headless không chứng minh mọi GPU/driver đều có hành vi giống nhau.
